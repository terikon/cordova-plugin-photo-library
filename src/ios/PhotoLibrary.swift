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
    }

    // Will sort by creation date
    func getLibrary(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: self.fetchOptions)

            var library = [NSDictionary]()

            fetchResult.enumerateObjectsUsingBlock {
                (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                let asset = obj as! PHAsset

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

    func getThumbnailURL(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailHeight = options["height"] as! Int
            let quality = options["quality"] as! Float

            let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)

            fetchResult.enumerateObjectsUsingBlock {
                (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                let asset = obj as! PHAsset
                let ratio = asset.pixelWidth / asset.pixelHeight

                PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: thumbnailHeight * ratio, height: thumbnailHeight), contentMode: .AspectFill, options: self.imageRequestOptions) {
                    (image: UIImage?, imageInfo: [NSObject : AnyObject]?) in

                    let imageURL:String? = image != nil ? self.image2DataURL(image!, quality: CGFloat(quality)) : nil

                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsString: imageURL
                    )

                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }

    func getPhotoURL(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {

            let photoId = command.arguments[0] as! String

            let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([photoId], options: self.fetchOptions)

            fetchResult.enumerateObjectsUsingBlock {
                (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                let asset = obj as! PHAsset

                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
                    (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in

                    let image = imageData != nil ? UIImage(data: imageData!) : nil

                    let imageURL:String? = image != nil ? self.image2DataURL(image!, quality: 1.0) : nil

                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsString: imageURL
                    )

                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }

    //TODO: remove this
    private func image2DataURL(image: UIImage, quality: CGFloat) -> String? {
        var imageData: NSData?
        var mimeType: String
        if (imageHasAlpha(image)){
            imageData = UIImagePNGRepresentation(image)
            mimeType = "image/png"
        } else {
            imageData = UIImageJPEGRepresentation(image, quality)
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

    func echo(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        let msg = command.arguments[0] as? String ?? ""

        if msg.characters.count > 0 {
            /* UIAlertController is iOS 8 or newer only. */
            let toastController: UIAlertController =
                UIAlertController(
                    title: "",
                    message: msg,
                    preferredStyle: .Alert
            )

            self.viewController?.presentViewController(
                toastController,
                animated: true,
                completion: nil
            )

            let duration = Double(NSEC_PER_SEC) * 3.0

            dispatch_after(
                dispatch_time(
                    DISPATCH_TIME_NOW,
                    Int64(duration)
                ),
                dispatch_get_main_queue(),
                {
                    toastController.dismissViewControllerAnimated(
                        true,
                        completion: nil
                    )
                }
            )

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsString: msg
            )
        }

        self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}
