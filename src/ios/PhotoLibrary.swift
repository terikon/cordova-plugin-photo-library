import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    var service: PhotoLibraryService!

    override func pluginInitialize() {
        
        service = PhotoLibraryService.instance

        NSURLProtocol.registerClass(PhotoLibraryProtocol)
        
    }

    override func onMemoryWarning() {
        do {
            try self.service.stopCaching()
        } catch {
            // nothing to do
        }
    }

    // Will sort by creation date
    func getLibrary(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            
            let library = self.service.getLibrary(thumbnailWidth, thumbnailHeight: thumbnailHeight)
            
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsArray: library
            )

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
                
                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsMultipart: [imageData.data ?? NSNull(), imageData.mimeType ?? NSNull()]
                )
                
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId )
                
            }
            
        }
    }

    func getPhoto(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let photoId = command.arguments[0] as! String

            self.service.getPhoto(photoId) { (imageData) in
                
                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsMultipart: [imageData.data ?? NSNull(), imageData.mimeType ?? NSNull()]
                )
                
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

            }
            
        }
    }

    func stopCaching(command: CDVInvokedUrlCommand) {

        var pluginResult: CDVPluginResult?
        
        do {
            try self.service.stopCaching()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } catch {
            let message = "" //error.domain == NSObjectInaccessibleException ? "" : ""
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: message)
        }
        
        self.commandDelegate!.sendPluginResult(pluginResult!, callbackId: command.callbackId	)

    }

}
