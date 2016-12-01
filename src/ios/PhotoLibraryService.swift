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
    let thumbnailRequestOptions: PHImageRequestOptions!
    let imageRequestOptions: PHImageRequestOptions!
    let dateFormatter: DateFormatter! //TODO: remove in Swift 3, use JSONRepresentable
    let cachingImageManager: PHCachingImageManager!

    let contentMode = PHImageContentMode.aspectFill // AspectFit: can be smaller, AspectFill - can be larger. TODO: resize to exact size

    var cacheActive = false

    static let PERMISSION_ERROR = "Permission Denial: This application is not allowed to access Photo data."

    let dataURLPattern = try! NSRegularExpression(pattern: "^data:.+?;base64,", options: NSRegularExpression.Options(rawValue: 0))
    
    // TODO: provide it as option to getLibrary
    static let PARTIAL_RESULT_PERIOD_SEC = 0.5 // Waiting time for returning partial results in getLibrary

    fileprivate init() {
        fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
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
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

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

    func getLibrary(_ thumbnailWidth: Int, thumbnailHeight: Int, partialCallback: @escaping (_ result: [NSDictionary]) -> Void, completion: @escaping (_ result: [NSDictionary]) -> Void) {

        let fetchResult = PHAsset.fetchAssets(with: .image, options: self.fetchOptions)

        if fetchResult.count > 0 {

            var assets = [PHAsset]()
            fetchResult.enumerateObjects({(asset, index, stop) in
                assets.append(asset)
            })

            self.stopCaching()
            self.cachingImageManager.startCachingImages(for: assets, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions)
            self.cacheActive = true
        }

        var library = [NSDictionary?](repeating: nil, count: fetchResult.count)

        var requestsLeft = fetchResult.count
        
        var lastPartialResultTime = NSDate()
        
        func sendPartialResult(_ library: [NSDictionary?]) {
            let libraryCopy = library.filter { $0 != nil }
            partialCallback(libraryCopy as! [NSDictionary])
        }

        fetchResult.enumerateObjects({ (asset: PHAsset, index, stop) in

            // requestImageData call is async
            PHImageManager.default().requestImageData(for: asset, options: self.thumbnailRequestOptions) {
                (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) in

                let imageURL = info?["PHImageFileURLKey"] as? URL

                let libraryItem = NSMutableDictionary()

                libraryItem["id"] = asset.localIdentifier
                libraryItem["filename"] = imageURL?.pathComponents.last
                libraryItem["nativeURL"] = imageURL?.absoluteString //TODO: in Swift 3, use JSONRepresentable
                libraryItem["width"] = asset.pixelWidth
                libraryItem["height"] = asset.pixelHeight
                libraryItem["creationDate"] = self.dateFormatter.string(from: asset.creationDate!) //TODO: in Swift 3, use JSONRepresentable
                // TODO: asset.faceRegions, asset.locationData

                library[index] = libraryItem

                requestsLeft -= 1

                if requestsLeft == 0 {
                    completion(library as! [NSDictionary])
                } else {
                    // Each PARTIAL_RESULT_PERIOD_SEC seconds provide partial result
                    let elapsedSec = abs(lastPartialResultTime.timeIntervalSinceNow)
                    if elapsedSec > PhotoLibraryService.PARTIAL_RESULT_PERIOD_SEC {
                        lastPartialResultTime = NSDate()
                        
                        sendPartialResult(library)
                    }
                }
            }
        })

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

    // TODO: implement with PHPhotoLibrary (UIImageWriteToSavedPhotosAlbum) instead of deprecated ALAssetsLibrary,
    // as described here: http://stackoverflow.com/questions/11972185/ios-save-photo-in-an-app-specific-album
    // but first find a way to save animated gif with it.
    // TODO: should return library item
    func saveImage(_ url: String, album: String, completion: @escaping (_ url: URL?, _ error: String?)->Void) {

        let sourceData: Data
        do {
            sourceData = try getDataFromURL(url)
        } catch {
            completion(nil, "\(error)")
            return
        }

        let assetsLibrary = ALAssetsLibrary()

        func saveImage(_ photoAlbum: PHAssetCollection) {
            assetsLibrary.writeImageData(toSavedPhotosAlbum: sourceData, metadata: nil) { (assetUrl: URL?, error: Error?) in

                if error != nil {
                    completion(nil, "Could not write image to album: \(error)")
                    return
                }

                guard let assetUrl = assetUrl else {
                    completion(nil, "Writing image to album resulted empty asset")
                    return
                }

                self.putMediaToAlbum(assetsLibrary, url: assetUrl, album: album, completion: { (error) in
                    if error != nil {
                        completion(nil, error)
                    } else {
                        completion(assetUrl, nil)
                    }
                })

            }
        }

        if let photoAlbum = PhotoLibraryService.getPhotoAlbum(album) {
            saveImage(photoAlbum)
            return
        }

        PhotoLibraryService.createPhotoAlbum(album) { (photoAlbum: PHAssetCollection?, error: String?) in

            guard let photoAlbum = photoAlbum else {
                completion(nil, error)
                return
            }

            saveImage(photoAlbum)

        }

    }

    func saveVideo(_ url: String, album: String, completion: @escaping (_ url: URL?, _ error: String?)->Void) { // TODO: should return library item

        guard let videoURL = URL(string: url) else {
            completion(nil, "Could not parse DataURL")
            return
        }

        let assetsLibrary = ALAssetsLibrary()

        func saveVideo(_ photoAlbum: PHAssetCollection) {

            // TODO: new way, seems not supports dataURL
            //            if !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL.relativePath!) {
            //                completion(url: nil, error: "Provided video is not compatible with Saved Photo album")
            //                return
            //            }
            //            UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath!, nil, nil, nil)

            if !assetsLibrary.videoAtPathIs(compatibleWithSavedPhotosAlbum: videoURL) {

                // TODO: try to convert to MP4 as described here?: http://stackoverflow.com/a/39329155/1691132

                completion(nil, "Provided video is not compatible with Saved Photo album")
                return
            }

            assetsLibrary.writeVideoAtPath(toSavedPhotosAlbum: videoURL) { (assetUrl: URL?, error: Error?) in

                if error != nil {
                    completion(nil, "Could not write video to album: \(error)")
                    return
                }

                guard let assetUrl = assetUrl else {
                    completion(nil, "Writing video to album resulted empty asset")
                    return
                }

                self.putMediaToAlbum(assetsLibrary, url: assetUrl, album: album, completion: { (error) in
                    if error != nil {
                        completion(nil, error)
                    } else {
                        completion(assetUrl, nil)
                    }
                })
            }

        }

        if let photoAlbum = PhotoLibraryService.getPhotoAlbum(album) {
            saveVideo(photoAlbum)
            return
        }

        PhotoLibraryService.createPhotoAlbum(album) { (photoAlbum: PHAssetCollection?, error: String?) in

            guard let photoAlbum = photoAlbum else {
                completion(nil, error)
                return
            }

            saveVideo(photoAlbum)

        }

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

            guard let match = self.dataURLPattern.firstMatch(in: url, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, url.characters.count)) else { // TODO: firstMatchInString seems to be slow for unknown reason
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

    fileprivate func putMediaToAlbum(_ assetsLibrary: ALAssetsLibrary, url: URL, album: String, completion: @escaping (_ error: String?)->Void) {

        assetsLibrary.asset(for: url, resultBlock: { (asset: ALAsset?) in

            guard let asset = asset else {
                completion("Retrieved asset is nil")
                return
            }

            PhotoLibraryService.getAlPhotoAlbum(assetsLibrary, album: album, completion: { (alPhotoAlbum: ALAssetsGroup?, error: String?) in

                if error != nil {
                    completion("getting photo album caused error: \(error)")
                    return
                }

                alPhotoAlbum!.add(asset)
                completion(nil)

            })

            }, failureBlock: { (error: Error?) in
                completion("Could not retrieve saved asset: \(error)")
        })

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

    fileprivate static func getPhotoAlbum(_ album: String) -> PHAssetCollection? {

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", album)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }

        return photoAlbum

    }

    fileprivate static func createPhotoAlbum(_ album: String, completion: @escaping (_ photoAlbum: PHAssetCollection?, _ error: String?)->()) {

        var albumPlaceholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({

            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection

        }) { success, error in

            guard let placeholder = albumPlaceholder else {
                completion(nil, "Album placeholder is nil")
                return
            }

            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)

            guard let photoAlbum = fetchResult.firstObject else {
                completion(nil, "FetchResult has no PHAssetCollection")
                return
            }

            if success {
                completion(photoAlbum, nil)
            }
            else {
                completion(nil, "\(error)")
            }
        }
    }

    fileprivate static func getAlPhotoAlbum(_ assetsLibrary: ALAssetsLibrary, album: String, completion: @escaping (_ alPhotoAlbum: ALAssetsGroup?, _ error: String?)->Void) {

        var groupPlaceHolder: ALAssetsGroup?

        assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupAlbum, usingBlock: { (group: ALAssetsGroup?, _ ) in

            guard let group = group else { // done enumerating
                guard let groupPlaceHolder = groupPlaceHolder else {
                    completion(nil, "Could not find album")
                    return
                }
                completion(groupPlaceHolder, nil)
                return
            }

            if group.value(forProperty: ALAssetsGroupPropertyName) as? String == album {
                groupPlaceHolder = group
            }

            }, failureBlock: { (error: Error?) in
                completion(nil, "Could not enumerate assets library")
        })

    }

}
