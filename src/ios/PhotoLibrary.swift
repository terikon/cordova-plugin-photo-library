@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {
    
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