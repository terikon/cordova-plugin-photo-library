import Photos
import Foundation
import AssetsLibrary // TODO: needed for deprecated functionality

//TODO: Swift 3
//extension NSDate: JSONRepresentable {
//    var JSONRepresentation: AnyObject {
//        let formatter = NSDateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
//
//        return formatter.stringFromDate(self)
//    }
//}
//extension NSURL: JSONRepresentable {
//    var JSONRepresentation: AnyObject {
//        return self.absoluteString
//    }
//}

final class PhotoLibraryService {
    
    let fetchOptions: PHFetchOptions!
    let imageRequestOptions: PHImageRequestOptions!
    let dateFormatter: NSDateFormatter! //TODO: remove in Swift 3, use JSONRepresentable
    let cachingImageManager: PHCachingImageManager!
    
    let contentMode = PHImageContentMode.AspectFill // AspectFit: can be smaller, AspectFill - can be larger. TODO: resize to exact size
    
    var cacheActive = false
    
    let PERMISSION_ERROR = "Permission Denial: This application is not allowed to access Photo data."
    
    let dataURLPattern = try! NSRegularExpression(pattern: "^data:.+?;base64,", options: NSRegularExpressionOptions(rawValue: 0))
    
    private init() {
        fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        if #available(iOS 9.0, *) {
            fetchOptions.includeAssetSourceTypes = [.TypeUserLibrary, .TypeiTunesSynced, .TypeCloudShared]
        }
        
        imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.synchronous = true
        imageRequestOptions.resizeMode = .Fast
        imageRequestOptions.deliveryMode = .FastFormat
        imageRequestOptions.version = .Current
        
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        cachingImageManager = PHCachingImageManager()
    }
    
    class var instance: PhotoLibraryService {
        struct SingletonWrapper {
            static let singleton = PhotoLibraryService()
        }
        return SingletonWrapper.singleton
    }
    
    // Returns nil if permissions not granted
    func getLibrary(thumbnailWidth: Int, thumbnailHeight: Int) -> [NSDictionary]? {
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: self.fetchOptions)
        
        var library = [NSDictionary]()
        
        var assets = [PHAsset]()
        fetchResult.enumerateObjectsUsingBlock{ (obj, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            assets.append(obj as! PHAsset)
        }
        
        if assets.count > 0 {
            self.stopCaching()
            self.cachingImageManager.startCachingImagesForAssets(assets, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions)
            self.cacheActive = true
        } else {
            // No photos returned, let's check permissions
            if PHPhotoLibrary.authorizationStatus() != .Authorized {
                return nil
            }
        }
        
        assets.forEach { (asset: PHAsset) in
            
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
                (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in
                
                let imageURL = info?["PHImageFileURLKey"] as? NSURL
                
                let libraryItem = NSMutableDictionary()
                
                libraryItem["id"] = asset.localIdentifier
                libraryItem["filename"] = imageURL?.pathComponents?.last
                libraryItem["nativeURL"] = imageURL?.absoluteString //TODO: in Swift 3, use JSONRepresentable
                libraryItem["width"] = asset.pixelWidth
                libraryItem["height"] = asset.pixelHeight
                libraryItem["creationDate"] = self.dateFormatter.stringFromDate(asset.creationDate!) //TODO: in Swift 3, use JSONRepresentable
                // TODO: asset.faceRegions, asset.locationData
                
                library.append(libraryItem)
            }
        }
        
        return library
        
    }
    
    // Result will be null if permissions not granted, or result.data will be empty if processing of image failed
    func getThumbnail(photoId: String, thumbnailWidth: Int, thumbnailHeight: Int, quality: Float, completion: (result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            if PHPhotoLibrary.authorizationStatus() != .Authorized {
                completion(result: nil)
                return
            }
            completion(result: PictureData(data:nil, mimeType: nil))
            return
        }
        
        fetchResult.enumerateObjectsUsingBlock {
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            self.cachingImageManager.requestImageForAsset(asset, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions) {
                (image: UIImage?, imageInfo: [NSObject : AnyObject]?) in
                
                guard let image = image else {
                    completion(result: PictureData(data:nil, mimeType: nil))
                    return
                }
                
                let imageData = PhotoLibraryService.image2PictureData(image, quality: quality)
                
                completion(result: imageData)
            }
        }
        
    }
    
    // Result will be null if permissions not granted, or result.data will be empty if processing of image failed
    func getPhoto(photoId: String, completion: (result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            if PHPhotoLibrary.authorizationStatus() != .Authorized {
                completion(result: nil)
                return
            }
            completion(result: PictureData(data:nil, mimeType: nil))
            return
        }
        
        fetchResult.enumerateObjectsUsingBlock {
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
                (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in
                
                guard let image = imageData != nil ? UIImage(data: imageData!) : nil else {
                    completion(result: PictureData(data:nil, mimeType: nil))
                    return
                }
                
                let imageData = PhotoLibraryService.image2PictureData(image, quality: 1.0)
                
                completion(result: imageData)
            }
        }
        
    }
    
    func stopCaching() {
        if self.cacheActive {
            self.cachingImageManager.stopCachingImagesForAllAssets()
            self.cacheActive = false
        }
    }
    
    func requestAuthorization(success: () -> Void, failure: (err: String) -> Void ) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .NotDetermined {
            // Ask for permission
            PHPhotoLibrary.requestAuthorization() { (status) -> Void in
                switch status {
                case .Authorized:
                    success()
                default:
                    failure(err: "requestAuthorization denied by user")
                }
            }
            return
        }
        
        // Permission was manually denied by user, open settings screen
        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            UIApplication.sharedApplication().openURL(url)
            // TODO: run callback only when return ?
            success()
        } else {
            failure(err: "could not open settings url")
        }
        
    }
    
    // TODO: implement with PHPhotoLibrary (UIImageWriteToSavedPhotosAlbum) instead of deprecated ALAssetsLibrary,
    // as described here: http://stackoverflow.com/questions/11972185/ios-save-photo-in-an-app-specific-album
    // but first find a way to save animated gif with it.
    func saveImage(url: String, album: String, completion: (url: NSURL?, error: String?)->Void) {
        
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            completion(url: nil, error: PERMISSION_ERROR)
            return
        }
        
        let sourceData: NSData
        do {
            sourceData = try getImageData(url)
        } catch {
            completion(url: nil, error: "\(error)")
            return
        }
        
        let assetsLibrary = ALAssetsLibrary()
        
        func saveImage(photoAlbum: PHAssetCollection) {
            assetsLibrary.writeImageDataToSavedPhotosAlbum(sourceData, metadata: nil) { (url: NSURL?, error: NSError?) in
                
                if error != nil {
                    completion(url: nil, error: "Could not write image to album")
                    return
                }
                
                assetsLibrary.assetForURL(url, resultBlock: { (asset: ALAsset?) in
                    
                    guard let asset = asset else {
                        completion(url: nil, error: "Retrieved asset is nil")
                        return
                    }
                    
                    PhotoLibraryService.getAlPhotoAlbum(assetsLibrary, album: album, completion: { (assetsGroup: ALAssetsGroup?, error: String?) in
                        
                        if (error != nil) {
                            completion(url: nil, error: "getting photo album caused error: \(error)")
                            return
                        }
                        
                        assetsGroup!.addAsset(asset)
                        completion(url: url, error: nil)
                        
                    })
                    
                    }, failureBlock: { (error: NSError!) in
                        completion(url: nil, error: "Could not retrieve saved asset: \(error)")
                })
                return
            }
        }
        
        if let photoAlbum = PhotoLibraryService.getPhotoAlbum(album) {
            saveImage(photoAlbum)
            return
        }
        
        PhotoLibraryService.createAlbum(album) { (photoAlbum: PHAssetCollection?, error: String?) in
            
            guard let photoAlbum = photoAlbum else {
                completion(url: nil, error: error)
                return
            }
            
            saveImage(photoAlbum)
            
        }
        
    }
    
    func saveVideo(url: String, album: String, completion: (url: NSURL?, error: String?)->Void) {
        
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            completion(url: nil, error: PERMISSION_ERROR)
            return
        }
        
    }
    
    struct PictureData {
        var data: NSData?
        var mimeType: String?
    }
    
    // TODO: currently seems useless
    enum PhotoLibraryError: ErrorType, CustomStringConvertible {
        case Error(description: String)
        
        var description: String {
            switch self {
            case .Error(let description): return description
            }
        }
    }
    
    private func getImageData(url: String) throws -> NSData {
        if url.hasPrefix("data:") {
            
            guard let match = self.dataURLPattern.firstMatchInString(url, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, url.characters.count)) else { // TODO: firstMatchInString seems to be slow for unknown reason
                throw PhotoLibraryError.Error(description: "The dataURL could not be parsed")
            }
            let dataPos = match.rangeAtIndex(0).length
            let base64 = (url as NSString).substringFromIndex(dataPos)
            guard let decoded = NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions(rawValue: 0)) else {
                throw PhotoLibraryError.Error(description: "The dataURL could not be decoded")
            }
            
            return decoded
            
        } else {
            
            guard let nsURL = NSURL(string: url) else {
                throw PhotoLibraryError.Error(description: "The url could not be decoded: " + url)
            }
            guard let fileContent = NSData(contentsOfURL: nsURL) else {
                throw PhotoLibraryError.Error(description: "The url could not be read: " + url)
            }
            
            return fileContent
            
        }
    }
    
    private static func image2PictureData(image: UIImage, quality: Float) -> PictureData {
        //        This returns raw data, but mime type is unknown. Anyway, crodova performs base64 for messageAsArrayBuffer, so there's no performance gain visible
        //        let provider: CGDataProvider = CGImageGetDataProvider(image.CGImage)!
        //        let data = CGDataProviderCopyData(provider)
        //        return data;
        
        var data: NSData?
        var mimeType: String?
        
        if (imageHasAlpha(image)){
            data = UIImagePNGRepresentation(image)
            mimeType = data != nil ? "image/png" : nil
        } else {
            data = UIImageJPEGRepresentation(image, CGFloat(quality))
            mimeType = data != nil ? "image/jpeg" : nil
        }
        
        return PictureData(data: data, mimeType: mimeType);
    }
    
    private static func imageHasAlpha(image: UIImage) -> Bool {
        let alphaInfo = CGImageGetAlphaInfo(image.CGImage)
        return alphaInfo == .First || alphaInfo == .Last || alphaInfo == .PremultipliedFirst || alphaInfo == .PremultipliedLast
    }
    
    private static func getPhotoAlbum(album: String) -> PHAssetCollection? {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", album)
        let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject as? PHAssetCollection else {
            return nil
        }
        
        return photoAlbum
        
    }
    
    private static func createAlbum(album: String, completion: (photoAlbum: PHAssetCollection?, error: String?)->()) {
        
        var albumPlaceholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(album)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            
        }) { success, error in
            
            guard let placeholder = albumPlaceholder else {
                completion(photoAlbum: nil, error: "Album placeholder is nil")
                return
            }
            
            let fetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([placeholder.localIdentifier], options: nil)
            
            guard let photoAlbum = fetchResult.firstObject as? PHAssetCollection else {
                completion(photoAlbum: nil, error: "FetchResult has no PHAssetCollection")
                return
            }
            
            if success {
                completion(photoAlbum: photoAlbum, error: nil)
            }
            else {
                completion(photoAlbum: nil, error: "\(error)")
            }
        }
    }
    
    private static func getAlPhotoAlbum(assetsLibrary: ALAssetsLibrary, album: String, completion: (photoAlbum: ALAssetsGroup?, error: String?)->Void) {
        
        var groupPlaceHolder: ALAssetsGroup?
        
        assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupAlbum, usingBlock: { (group: ALAssetsGroup?, _ ) in
            
            guard let group = group else { // done enumerating
                guard let groupPlaceHolder = groupPlaceHolder else {
                    completion(photoAlbum: nil, error: "Could not find album")
                    return
                }
                completion(photoAlbum: groupPlaceHolder, error: nil)
                return
            }
            
            if group.valueForProperty(ALAssetsGroupPropertyName) as? String == album {
                groupPlaceHolder = group
            }
            
            }, failureBlock: { (error: NSError?) in
                completion(photoAlbum: nil, error: "Could not enumerate assets library")
        })
        
    }
    
    //    private static func putImageToAlbum(fileURL: NSURL, album: PHAssetCollection, completion: (PHAsset?, PhotoLibraryError?)->()) {
    //
    //        var placeholder: PHObjectPlaceholder?
    //
    //        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
    //
    //            guard let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(fileURL) else {
    //                completion(nil, PhotoLibraryError.IOError(description: "Creating change request failed"))
    //                return
    //            }
    //
    //            guard let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album) else {
    //                completion(nil, PhotoLibraryError.IOError(description: "Album change request failed"))
    //                return
    //            }
    //
    //            guard let photoPlaceholder = createAssetRequest.placeholderForCreatedAsset else {
    //                completion(nil, PhotoLibraryError.IOError(description: "photoPlaceholder is nil"))
    //                return
    //            }
    //
    //            placeholder = photoPlaceholder
    //
    //            albumChangeRequest.addAssets([photoPlaceholder])
    //
    //            }, completionHandler: { success, error in
    //
    //                guard let placeholder = placeholder else {
    //                    completion(nil, PhotoLibraryError.IOError(description: "placeholder is nil"))
    //                    return
    //                }
    //
    //                if success {
    //                    //completion(PHAsset.ah_fetchAssetWithLocalIdentifier(placeholder.localIdentifier, options:nil), nil)
    //                    completion(nil, nil)
    //                }
    //                else {
    //                    completion(nil, PhotoLibraryError.IOError(description: "\(error)"))
    //                }
    //        })
    //    }
    
}
