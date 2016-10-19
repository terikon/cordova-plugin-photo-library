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

        self.service.requestAuthorization({
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
            }, failure: { (err) in
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: err)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
            })

    }
    
    func saveImage(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            self.service.saveImage(url, album: album) { (url: NSURL?, error: PhotoLibraryService.PhotoLibraryError?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.description)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }
    
    func saveVideo(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            self.service.saveVideo(url, album: album) { (url: NSURL?, error: PhotoLibraryService.PhotoLibraryError?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error!.description)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }

}
