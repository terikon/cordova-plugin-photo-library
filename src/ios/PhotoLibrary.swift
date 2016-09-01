import Photos

class ResultImage {
  var id: String?
  var title: String?
  var width: Int?
  var height: Int?
  var data: String?
  var thumbnail: String?
  var creationDate: Int?
}

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

  var fetchOptions: PHFetchOptions!

  override func pluginInitialize() {
    fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    if #available(iOS 9.0, *) {
      fetchOptions.includeAssetSourceTypes = [.TypeUserLibrary, .TypeiTunesSynced, .TypeCloudShared]
    }
  }

  // Will sort by creation date
  func getPhotos(command: CDVInvokedUrlCommand) {
    dispatch_async(dispatch_get_main_queue(), {

      let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: self.fetchOptions)

      var images = [ResultImage]()

      fetchResult.enumerateObjectsUsingBlock {
        (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
        let asset = obj as! PHAsset
        let resultImage = ResultImage()
        resultImage.id = asset.localIdentifier
        resultImage.title = ""
        resultImage.width = asset.pixelWidth
        resultImage.height = asset.pixelHeight
        resultImage.data = ""
        resultImage.thumbnail = ""
        resultImage.creationDate = 0
        images.append(resultImage)
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
