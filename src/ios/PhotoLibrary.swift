import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    var service: PhotoLibraryService!

    override func pluginInitialize() {

        service = PhotoLibraryService.instance

        NSURLProtocol.registerClass(PhotoLibraryProtocol)

    }

//    override func onMemoryWarning() {
//        self.service.stopCaching()
//    }

    // Will sort by creation date
    func getLibrary(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int

            let library = self.service.getLibrary(thumbnailWidth, thumbnailHeight: thumbnailHeight)

            let pluginResult = library != nil ?
                CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsArray: library)
            :
                CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAsString: self.service.PERMISSION_ERROR);

            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)

        }
    }

    func getThumbnail(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let quality = options["quality"] as! Float

            self.service.getThumbnail(photoId, thumbnailWidth: thumbnailWidth, thumbnailHeight: thumbnailHeight, quality: quality) { (imageData) in

                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data ?? NSNull(), imageData!.mimeType ?? NSNull()])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAsString: self.service.PERMISSION_ERROR);

                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId )

            }

        }
    }

    func getPhoto(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let photoId = command.arguments[0] as! String

            self.service.getPhoto(photoId) { (imageData) in

                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data ?? NSNull(), imageData!.mimeType ?? NSNull()])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAsString: self.service.PERMISSION_ERROR);

                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

            }

        }
    }

    func stopCaching(command: CDVInvokedUrlCommand) {

        self.service.stopCaching()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

    }

    func requestAuthorization(command: CDVInvokedUrlCommand) {

        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            UIApplication.sharedApplication().openURL(url)
            // TODO: run callback only when return ?
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

    }

}
