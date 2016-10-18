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
    func getThumbnail(photoId: String, thumbnailWidth: Int, thumbnailHeight: Int, quality: Float, resultCallback: (result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            if PHPhotoLibrary.authorizationStatus() != .Authorized {
                resultCallback(result: nil)
                return
            }
            resultCallback(result: PictureData(data:nil, mimeType: nil))
            return
        }
        
        fetchResult.enumerateObjectsUsingBlock {
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            self.cachingImageManager.requestImageForAsset(asset, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions) {
                (image: UIImage?, imageInfo: [NSObject : AnyObject]?) in
                
                if image == nil {
                    resultCallback(result: PictureData(data:nil, mimeType: nil))
                    return
                }
                
                let imageData = self.image2PictureData(image!, quality: quality)
                
                resultCallback(result: imageData)
            }
        }
        
    }
    
    // Result will be null if permissions not granted, or result.data will be empty if processing of image failed
    func getPhoto(photoId: String, resultCallback: (result: PictureData?) -> Void) {
        
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)
        
        if fetchResult.count == 0 {
            if PHPhotoLibrary.authorizationStatus() != .Authorized {
                resultCallback(result: nil)
                return
            }
            resultCallback(result: PictureData(data:nil, mimeType: nil))
            return
        }
        
        fetchResult.enumerateObjectsUsingBlock {
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let asset = obj as! PHAsset
            
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
                (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in
                
                let image = imageData != nil ? UIImage(data: imageData!) : nil
                
                if image == nil {
                    resultCallback(result: PictureData(data:nil, mimeType: nil))
                    return
                }
                
                let imageData = self.image2PictureData(image!, quality: 1.0)
                
                resultCallback(result: imageData)
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
    
    func saveImage(url: String, album: String, imageFileName: String, completionBlock: (url: NSURL?, error: PhotoLibraryError?)->Void) {
        
        var sourceData: NSData
        
        if url.hasPrefix("data:") {
            
            let regex = try? NSRegularExpression(pattern: "data:.+;base64,", options: NSRegularExpressionOptions(rawValue: 0))
            let base64 = regex?.stringByReplacingMatchesInString(url, options: .WithTransparentBounds, range: NSMakeRange(0, url.characters.count), withTemplate: "")
            if (base64 == nil) {
                completionBlock(url: nil, error: PhotoLibraryError.ArgumentError(description: "The dataURL could not be parsed"))
                return
            }
            let decoded = NSData(base64EncodedString: base64!, options: NSDataBase64DecodingOptions(rawValue: 0))
            if (decoded == nil) {
                completionBlock(url: nil, error: PhotoLibraryError.ArgumentError(description: "The dataURL could not be decoded"))
                return
            }
            
            sourceData = decoded!
            
        } else {
            
            let fileContent = NSData(contentsOfURL: NSURL(fileURLWithPath: url))
            if (fileContent == nil) {
                completionBlock(url: nil, error: PhotoLibraryError.ArgumentError(description: "The url could not be read: " + url))
                return
            }
            sourceData = fileContent!
            
        }
        
        let assetsLibrary = ALAssetsLibrary()
        
        func writeImageDataToSavedPhotosAlbum (sourceData: NSData, group: ALAssetsGroup) {
            assetsLibrary.writeImageDataToSavedPhotosAlbum(sourceData, metadata: nil) { (url: NSURL?, error: NSError?) in
                if error != nil {
                    assetsLibrary.assetForURL(url, resultBlock: { (asset: ALAsset!) in
                        group.addAsset(asset)
                        }, failureBlock: { (error: NSError!) in
                            completionBlock(url: nil, error: PhotoLibraryError.IOError(description: "Could not retrieve saved asset"))
                    })
                    completionBlock(url: nil, error: PhotoLibraryError.IOError(description: "Could not write image to album"))
                    return
                }
                completionBlock(url: url, error: nil)
            }
        }
        
        assetsLibrary.addAssetsGroupAlbumWithName(album, resultBlock: { (group: ALAssetsGroup?) in
            
            if group == nil { // i.e. group previously created
                assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupAlbum, usingBlock: { (group: ALAssetsGroup?, _: UnsafeMutablePointer<ObjCBool>) in
                    if (group!.valueForProperty(ALAssetsGroupPropertyName)) as! String? == album {
                        writeImageDataToSavedPhotosAlbum(sourceData, group: group!)
                    }
                    }, failureBlock: { (error: NSError!) in
                        completionBlock(url: nil, error: PhotoLibraryError.IOError(description: "Could not enumerate albums"))
                })
            } else { // group added
                writeImageDataToSavedPhotosAlbum(sourceData, group: group!)
            }
            
            }, failureBlock: { (error: NSError!) in
                completionBlock(url: nil, error: PhotoLibraryError.IOError(description: "Could not add album"))
        })
        
    }
    
    func saveVideo(url: String, album: String, videoFileName: String) {
        
    }
    
    struct PictureData {
        var data: NSData?
        var mimeType: String?
    }
    
    enum PhotoLibraryError: ErrorType {
        case ArgumentError(description: String)
        case IOError(description: String)
    }
    
    private func image2PictureData(image: UIImage, quality: Float) -> PictureData {
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
    
    private func imageHasAlpha(image: UIImage) -> Bool {
        let alphaInfo = CGImageGetAlphaInfo(image.CGImage)
        return alphaInfo == .First || alphaInfo == .Last || alphaInfo == .PremultipliedFirst || alphaInfo == .PremultipliedLast
    }
    
    
}
