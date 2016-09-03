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

    dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
  }

  // Will sort by creation date
  func getPhotos(command: CDVInvokedUrlCommand) {
    dispatch_async(dispatch_get_main_queue(), {

      let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: self.fetchOptions)

      var images = [NSDictionary]()

      fetchResult.enumerateObjectsUsingBlock {
        (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

        let asset = obj as! PHAsset

        PHImageManager.defaultManager().requestImageDataForAsset(asset, options: self.imageRequestOptions) {
            (imageDate: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) in

            PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: Double(asset.pixelWidth)*0.2, height: Double(asset.pixelHeight)*0.2), contentMode: .AspectFill, options: self.imageRequestOptions) {
                (image: UIImage?, imageInfo: [NSObject : AnyObject]?) in
                //TODO: convert image to url data

                let imageURL = info?["PHImageFileURLKey"] as? NSURL

                let resultImage = NSMutableDictionary()

                resultImage["id"] = asset.localIdentifier
                resultImage["filename"] = imageURL?.pathComponents?.last
                resultImage["fileUrl"] = imageURL?.absoluteString //TODO: in Swift 3, use JSONRepresentable
                resultImage["url"] = nil //convert to data url
                resultImage["width"] = asset.pixelWidth
                resultImage["height"] = asset.pixelHeight
                resultImage["creationDate"] = self.dateFormatter.stringFromDate(asset.creationDate!) //TODO: in Swift 3, use JSONRepresentable
                // TODO: asset.faceRegions, asset.locationData

                images.append(resultImage)
            }
        }
      }

      let pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAsArray: images
      )

      self.commandDelegate!.sendPluginResult(
        pluginResult,
        callbackId: command.callbackId
      )

    });
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
