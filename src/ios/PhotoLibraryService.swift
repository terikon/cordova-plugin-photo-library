import Photos
import Foundation
import AssetsLibrary
import MobileCoreServices

final class PhotoLibraryService {
    
    let fetchOptions: PHFetchOptions!
    let thumbnailRequestOptions: PHImageRequestOptions!
    let imageRequestOptions: PHImageRequestOptions!
    let dateFormatter: DateFormatter!
    let cachingImageManager: PHCachingImageManager!
    
    let contentMode = PHImageContentMode.aspectFill // AspectFit: can be smaller, AspectFill - can be larger. TODO: resize to exact size
    
    var cacheActive = false
    
    let mimeTypes = [
        "flv":  "video/x-flv",
        "mp4":  "video/mp4",
        "m3u8":    "application/x-mpegURL",
        "ts":   "video/MP2T",
        "3gp":    "video/3gpp",
        "mov":    "video/quicktime",
        "avi":    "video/x-msvideo",
        "wmv":    "video/x-ms-wmv",
        "gif":  "image/gif",
        "jpg":  "image/jpeg",
        "jpeg": "image/jpeg",
        "png":  "image/png",
        "tiff": "image/tiff",
        "tif":  "image/tiff"
    ]
    
    static let PERMISSION_ERROR = "Permission Denial: This application is not allowed to access Photo data."
    
    let dataURLPattern = try! NSRegularExpression(pattern: "^data:.+?;base64,", options: NSRegularExpression.Options(rawValue: 0))
    
    let assetCollectionTypes = [PHAssetCollectionType.album, PHAssetCollectionType.smartAlbum/*, PHAssetCollectionType.moment*/]
    
    fileprivate init() {
        fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        if #available(iOS 9.0, *) {
            fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        }
        
        thumbnailRequestOptions = PHImageRequestOptions()
        thumbnailRequestOptions.isSynchronous = false
        thumbnailRequestOptions.resizeMode = .exact
        thumbnailRequestOptions.deliveryMode = .highQualityFormat
        thumbnailRequestOptions.version = .current
        thumbnailRequestOptions.isNetworkAccessAllowed = false
        
        imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.resizeMode = .exact
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.version = .current
        imageRequestOptions.isNetworkAccessAllowed = false
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        cachingImageManager = PHCachingImageManager()
    }
    
    class var instance: PhotoLibraryService {
        
        struct SingletonWrapper {
            static let singleton = PhotoLibraryService()
        }
        
        return SingletonWrapper.singleton
        
    }
    
    static func hasPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
        
    }
    
    func getLibrary(_ options: PhotoLibraryGetLibraryOptions, completion: @escaping (_ result: [NSDictionary], _ chunkNum: Int, _ isLastChunk: Bool) -> Void) {
        
        if(options.includeCloudData == false) {
            if #available(iOS 9.0, *) {
                // remove iCloud source type
                fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
            }
        }
        
        // let fetchResult = PHAsset.fetchAssets(with: .image, options: self.fetchOptions)
        if(options.includeImages == true && options.includeVideos == true) {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                                 PHAssetMediaType.image.rawValue,
                                                 PHAssetMediaType.video.rawValue)
        }
        else {
            if(options.includeImages == true) {
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                     PHAssetMediaType.image.rawValue)
            }
            else if(options.includeVideos == true) {
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                     PHAssetMediaType.video.rawValue)
            }
        }
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        
        
        // TODO: do not restart caching on multiple calls
        //        if fetchResult.count > 0 {
        //
        //            var assets = [PHAsset]()
        //            fetchResult.enumerateObjects({(asset, index, stop) in
        //                assets.append(asset)
        //            })
        //
        //            self.stopCaching()
        //            self.cachingImageManager.startCachingImages(for: assets, targetSize: CGSize(width: options.thumbnailWidth, height: options.thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions)
        //            self.cacheActive = true
        //        }
        
        var chunk = [NSDictionary]()
        var chunkStartTime = NSDate()
        var chunkNum = 0
        
        fetchResult.enumerateObjects({ (asset: PHAsset, index, stop) in
            
            let libraryItem = self.assetToLibraryItem(asset: asset, useOriginalFileNames: options.useOriginalFileNames, includeAlbumData: options.includeAlbumData)
            
            chunk.append(libraryItem)
            
            self.getCompleteInfo(libraryItem, completion: { (fullPath) in
                
                libraryItem["filePath"] = fullPath
                
                if index == fetchResult.count - 1 { // Last item
                    completion(chunk, chunkNum, true)
                } else if (options.itemsInChunk > 0 && chunk.count == options.itemsInChunk) ||
                    (options.chunkTimeSec > 0 && abs(chunkStartTime.timeIntervalSinceNow) >= options.chunkTimeSec) {
                    completion(chunk, chunkNum, false)
                    chunkNum += 1
                    chunk = [NSDictionary]()
                    chunkStartTime = NSDate()
                }
            })
        })
    }
    
    
    
    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    
    func getCompleteInfo(_ libraryItem: NSDictionary, completion: @escaping (_ fullPath: String?) -> Void) {
        
        
        let ident = libraryItem.object(forKey: "id") as! String
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [ident], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        
        let mime_type = libraryItem.object(forKey: "mimeType") as! String
        let mediaType = mime_type.components(separatedBy: "/").first
        
        
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let asset = obj as! PHAsset
            
            if(mediaType == "image") {
                PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                    (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) in
                    
                    if(imageData == nil) {
                        completion(nil)
                    }
                    else {
                        let file_url:URL = info!["PHImageFileURLKey"] as! URL
                        //                        let mime_type = self.mimeTypes[file_url.pathExtension.lowercased()]!
                        completion(file_url.relativePath)
                    }
                }
            }
            else if(mediaType == "video") {
                
                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    
                    if( avAsset is AVURLAsset ) {
                        let video_asset = avAsset as! AVURLAsset
                        let url = URL(fileURLWithPath: video_asset.url.relativePath)
                        completion(url.relativePath)
                    }
                    else if(avAsset is AVComposition) {
                        let token = info?["PHImageFileSandboxExtensionTokenKey"] as! String
                        let path = token.components(separatedBy: ";").last
                        completion(path)
                    }
                })
            }
            else if(mediaType == "audio") {
                // TODO:
                completion(nil)
            }
            else {
                completion(nil) // unknown
            }
        })
    }
    
    
    private func assetToLibraryItem(asset: PHAsset, useOriginalFileNames: Bool, includeAlbumData: Bool) -> NSMutableDictionary {
        let libraryItem = NSMutableDictionary()
        
        libraryItem["id"] = asset.localIdentifier
        libraryItem["fileName"] = useOriginalFileNames ? asset.originalFileName : asset.fileName // originalFilename is much slower
        libraryItem["width"] = asset.pixelWidth
        libraryItem["height"] = asset.pixelHeight
        
        let fname = libraryItem["fileName"] as! String
        libraryItem["mimeType"] = self.mimeTypeForPath(path: fname)
        
        libraryItem["creationDate"] = self.dateFormatter.string(from: asset.creationDate!)
        if let location = asset.location {
            libraryItem["latitude"] = location.coordinate.latitude
            libraryItem["longitude"] = location.coordinate.longitude
        }
        
        
        if includeAlbumData {
            // This is pretty slow, use only when needed
            var assetCollectionIds = [String]()
            for assetCollectionType in self.assetCollectionTypes {
                let albumsOfAsset = PHAssetCollection.fetchAssetCollectionsContaining(asset, with: assetCollectionType, options: nil)
                albumsOfAsset.enumerateObjects({ (assetCollection: PHAssetCollection, index, stop) in
                    assetCollectionIds.append(assetCollection.localIdentifier)
                })
            }
            libraryItem["albumIds"] = assetCollectionIds
        }
        
        return libraryItem
    }
    
    func getAlbums() -> [NSDictionary] {
        
        var result = [NSDictionary]()
        
        for assetCollectionType in assetCollectionTypes {
            
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: assetCollectionType, subtype: .any, options: nil)
            
            fetchResult.enumerateObjects({ (assetCollection: PHAssetCollection, index, stop) in
                
                let albumItem = NSMutableDictionary()
                
                albumItem["id"] = assetCollection.localIdentifier
                albumItem["title"] = assetCollection.localizedTitle
                
                result.append(albumItem)
                
            });
            
        }
        
        return result;
        
    }
    
    func getThumbnail(_ photoId: String, thumbnailWidth: Int, thumbnailHeight: Int, quality: Float, completion: @escaping (_ result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            self.cachingImageManager.requestImage(for: asset, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.thumbnailRequestOptions) {
                (image: UIImage?, imageInfo: [AnyHashable: Any]?) in
                
                guard let image = image else {
                    completion(nil)
                    return
                }
                
                let imageData = PhotoLibraryService.image2PictureData(image, quality: quality)
                
                completion(imageData)
            }
        })
        
    }
    
    func getPhoto(_ photoId: String, completion: @escaping (_ result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) in
                
                guard let image = imageData != nil ? UIImage(data: imageData!) : nil else {
                    completion(nil)
                    return
                }
                
                let imageData = PhotoLibraryService.image2PictureData(image, quality: 1.0)
                
                completion(imageData)
            }
        })
    }
    
    
    func getLibraryItem(_ itemId: String, mimeType: String, completion: @escaping (_ base64: String?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [itemId], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        
        // TODO: data should be returned as chunks, even for pics.
        // a massive data object might increase RAM usage too much, and iOS will then kill the app.
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let asset = obj as! PHAsset
            
            let mediaType = mimeType.components(separatedBy: "/")[0]
            
            if(mediaType == "image") {
                PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                    (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) in
                    
                    if(imageData == nil) {
                        completion(nil)
                    }
                    else {
                        //                        let file_url:URL = info!["PHImageFileURLKey"] as! URL
                        //                        let mime_type = self.mimeTypes[file_url.pathExtension.lowercased()]
                        completion(imageData!.base64EncodedString())
                    }
                }
            }
            else if(mediaType == "video") {
                
                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    
                    let video_asset = avAsset as! AVURLAsset
                    let url = URL(fileURLWithPath: video_asset.url.relativePath)
                    
                    do {
                        let video_data = try Data(contentsOf: url)
                        let video_base64 = video_data.base64EncodedString()
                        //                        let mime_type = self.mimeTypes[url.pathExtension.lowercased()]
                        completion(video_base64)
                    }
                    catch _ {
                        completion(nil)
                    }
                })
            }
            else if(mediaType == "audio") {
                // TODO:
                completion(nil)
            }
            else {
                completion(nil) // unknown
            }
            
        })
    }
    
    
    func getVideo(_ videoId: String, completion: @escaping (_ result: PictureData?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                
                let video_asset = avAsset as! AVURLAsset
                let url = URL(fileURLWithPath: video_asset.url.relativePath)
                
                do {
                    let video_data = try Data(contentsOf: url)
                    let pic_data = PictureData(data: video_data, mimeType: "video/quicktime") // TODO: get mime from info dic ?
                    completion(pic_data)
                }
                catch _ {
                    completion(nil)
                }
            })
        })
    }
    
    
    func stopCaching() {
        
        if self.cacheActive {
            self.cachingImageManager.stopCachingImagesForAllAssets()
            self.cacheActive = false
        }
        
    }
    
    func requestAuthorization(_ success: @escaping () -> Void, failure: @escaping (_ err: String) -> Void ) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .authorized {
            success()
            return
        }
        
        if status == .notDetermined {
            // Ask for permission
            PHPhotoLibrary.requestAuthorization() { (status) -> Void in
                switch status {
                case .authorized:
                    success()
                default:
                    failure("requestAuthorization denied by user")
                }
            }
            return
        }
        
        // Permission was manually denied by user, open settings screen
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.openURL(url)
            // TODO: run callback only when return ?
            // Do not call success, as the app will be restarted when user changes permission
        } else {
            failure("could not open settings url")
        }
        
    }
    
    func saveImage(_ url: String, album: String, completion: @escaping (_ url: URL?, _ error: String?)->Void) {
        
        let sourceData = URL(string: url)!
        let collection = fetchAssetCollectionWithAlbumName(albumName: album)

        if collection == nil {
            
            PHPhotoLibrary.shared().performChanges({ PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
            }, completionHandler: {(success : Bool, error : NSError?) in
                if error != nil {
                    completion(nil, "Could not write image to album: \(String(describing: error))")
                    return
                }
                
                if success {
                    let newCollection = self.fetchAssetCollectionWithAlbumName(albumName: album)
                    self.insertImage(url: sourceData, intoAssetCollection: newCollection!)
                    completion(sourceData, nil)
                }
                
                } as? (Bool, Error?) -> Void)
        } else {
            self.insertImage(url: sourceData, intoAssetCollection: collection!)
            completion(sourceData, nil)
        }
    }

    func saveVideo(_ url: String, album: String, completion: @escaping (_ url: URL?, _ error: String?)->Void) { // TODO: should return library item
        
        let sourceData = URL(string: url)!
        let collection = fetchAssetCollectionWithAlbumName(albumName: album)
        
        if collection == nil {
            
            PHPhotoLibrary.shared().performChanges({ PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
            }, completionHandler: {(success : Bool, error : NSError?) in
                if error != nil {
                    completion(nil, "Could not write image to album: \(String(describing: error))")
                    return
                }
                
                if success {
                    let newCollection = self.fetchAssetCollectionWithAlbumName(albumName: album)
                    self.insertVideo(url: sourceData, intoAssetCollection: newCollection!)
                    completion(sourceData, nil)
                }
                
                } as? (Bool, Error?) -> Void)
        } else {
            self.insertVideo(url: sourceData, intoAssetCollection: collection!)
            completion(sourceData, nil)
        }
    }
    
    func insertImage(url: URL, intoAssetCollection collection : PHAssetCollection) {
        
        PHPhotoLibrary.shared().performChanges({
            
            let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
            let asset = creationRequest?.placeholderForCreatedAsset
            let request = PHAssetCollectionChangeRequest(for: collection)
            
            if request != nil && asset != nil {
                let enumeration: NSArray = [asset!]
                request!.addAssets(enumeration)
            }
        });
    }
    
    func insertVideo(url: URL, intoAssetCollection collection : PHAssetCollection) {
        
        PHPhotoLibrary.shared().performChanges({
            
            let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
            let asset = creationRequest?.placeholderForCreatedAsset
            let request = PHAssetCollectionChangeRequest(for: collection)
            
            if request != nil && asset != nil {
                let enumeration: NSArray = [asset!]
                request!.addAssets(enumeration)
            }
        });
    }
    
    func fetchAssetCollectionWithAlbumName(albumName : String) -> PHAssetCollection? {
        
        let fetchOption = PHFetchOptions()
        fetchOption.predicate = NSPredicate(format: "title == '" + albumName + "'")
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumRegular, options: fetchOption)
        let collection = fetchResult.firstObject
        
        return collection
    }
    
    struct PictureData {
        var data: Data
        var mimeType: String
    }
    
    // TODO: currently seems useless
    enum PhotoLibraryError: Error, CustomStringConvertible {
        case error(description: String)
        
        var description: String {
            switch self {
            case .error(let description): return description
            }
        }
    }
    
    fileprivate func getDataFromURL(_ url: String) throws -> Data {
        if url.hasPrefix("data:") {
            
            guard let match = self.dataURLPattern.firstMatch(in: url, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, url.count)) else { // TODO: firstMatchInString seems to be slow for unknown reason
                throw PhotoLibraryError.error(description: "The dataURL could not be parsed")
            }
            let dataPos = match.rangeAt(0).length
            let base64 = (url as NSString).substring(from: dataPos)
            guard let decoded = Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0)) else {
                throw PhotoLibraryError.error(description: "The dataURL could not be decoded")
            }
            
            return decoded
            
        } else {
            
            guard let nsURL = URL(string: url) else {
                throw PhotoLibraryError.error(description: "The url could not be decoded: \(url)")
            }
            guard let fileContent = try? Data(contentsOf: nsURL) else {
                throw PhotoLibraryError.error(description: "The url could not be read: \(url)")
            }
            
            return fileContent
            
        }
    }
    
    fileprivate static func image2PictureData(_ image: UIImage, quality: Float) -> PictureData? {
        //        This returns raw data, but mime type is unknown. Anyway, crodova performs base64 for messageAsArrayBuffer, so there's no performance gain visible
        //        let provider: CGDataProvider = CGImageGetDataProvider(image.CGImage)!
        //        let data = CGDataProviderCopyData(provider)
        //        return data;
        
        var data: Data?
        var mimeType: String?
        
        if (imageHasAlpha(image)){
            data = UIImagePNGRepresentation(image)
            mimeType = data != nil ? "image/png" : nil
        } else {
            data = UIImageJPEGRepresentation(image, CGFloat(quality))
            mimeType = data != nil ? "image/jpeg" : nil
        }
        
        if data != nil && mimeType != nil {
            return PictureData(data: data!, mimeType: mimeType!)
        }
        return nil
    }
    
    fileprivate static func imageHasAlpha(_ image: UIImage) -> Bool {
        let alphaInfo = (image.cgImage)?.alphaInfo
        return alphaInfo == .first || alphaInfo == .last || alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension PHAsset {
    
    // Returns original file name, useful for photos synced with iTunes
    var originalFileName: String? {
        var result: String?
        
        // This technique is slow
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                result = resource.originalFilename
            }
        }
        
        return result
    }
    
    var fileName: String? {
        return self.value(forKey: "filename") as? String
    }
    
}
