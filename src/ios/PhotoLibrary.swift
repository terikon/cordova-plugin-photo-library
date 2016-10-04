import Photos
import Foundation

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

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    var fetchOptions: PHFetchOptions!
    var imageRequestOptions: PHImageRequestOptions!
    var dateFormatter: NSDateFormatter! //TODO: remove in Swift 3, use JSONRepresentable
    var cachingImageManager: PHCachingImageManager!

    let contentMode = PHImageContentMode.AspectFill

    override func pluginInitialize() {

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

    // Will sort by creation date
    func getLibrary(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int

            let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: self.fetchOptions)

            var library = [NSDictionary]()

            var assets = [PHAsset]()
            fetchResult.enumerateObjectsUsingBlock{ (obj, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                assets.append(obj as! PHAsset)
            }

            self.cachingImageManager.stopCachingImagesForAllAssets()
            self.cachingImageManager.startCachingImagesForAssets(assets, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions)

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

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsArray: library
            )

            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        }
    }

    func getThumbnail(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let quality = options["quality"] as! Float

            let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)

            // TODO: why enumeration needed for one asset?
            fetchResult.enumerateObjectsUsingBlock {
                (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                let asset = obj as! PHAsset

                self.cachingImageManager.requestImageForAsset(asset, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions) {
                    (image: UIImage?, imageInfo: [NSObject : AnyObject]?) in

                    let imageTuple = self.image2BlobData(image!, quality: quality)

                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageTuple.data ?? NSNull(), imageTuple.mimeType ?? NSNull()]
                    )

                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

                }
            }
        }
    }

    func getPhoto(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let photoId = command.arguments[0] as! String

            let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)

            fetchResult.enumerateObjectsUsingBlock {
                (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                let asset = obj as! PHAsset

                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
                    (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in

                    let image = imageData != nil ? UIImage(data: imageData!) : nil

                    let imageTuple = self.image2BlobData(image!, quality: 1.0)

                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageTuple.data ?? NSNull(), imageTuple.mimeType ?? NSNull()]
                    )

                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }

    func stopCaching(command: CDVInvokedUrlCommand) {

        self.cachingImageManager.stopCachingImagesForAllAssets()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

    }

    private func image2BlobData(image: UIImage, quality: Float) -> (data: NSData?, mimeType: String?) {
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

        return (data, mimeType);
    }

    private func image2DataURL(image: UIImage, quality: Float) -> String? {
        var imageData: NSData?
        var mimeType: String
        if (imageHasAlpha(image)){
            imageData = UIImagePNGRepresentation(image)
            mimeType = "image/png"
        } else {
            imageData = UIImageJPEGRepresentation(image, CGFloat(quality))
            mimeType = "image/jpeg"
        }
        if (imageData != nil) {
            let encodedString = imageData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            if (encodedString != nil) {
                return String(format: "data:%@;base64,%@", mimeType, encodedString!)
            }
        }
        return nil
    }

    private func imageHasAlpha(image: UIImage) -> Bool {
        let alphaInfo = CGImageGetAlphaInfo(image.CGImage)
        return alphaInfo == .First || alphaInfo == .Last || alphaInfo == .PremultipliedFirst || alphaInfo == .PremultipliedLast
    }

}
