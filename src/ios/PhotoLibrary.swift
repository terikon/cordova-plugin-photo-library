import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    var service: PhotoLibraryService!

    override func pluginInitialize() {

        service = PhotoLibraryService.instance

        URLProtocol.registerClass(PhotoLibraryProtocol.self)

    }

//    override func onMemoryWarning() {
//        self.service.stopCaching()
//    }

    // Will sort by creation date
    func getLibrary(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {

            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int

            let library = self.service.getLibrary(thumbnailWidth, thumbnailHeight: thumbnailHeight)

            let pluginResult = library != nil ?
                CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: library)
            :
                CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: self.service.PERMISSION_ERROR);

            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)

        }
    }

    func getThumbnail(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            
            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let quality = options["quality"] as! Float

            self.service.getThumbnail(photoId, thumbnailWidth: thumbnailWidth, thumbnailHeight: thumbnailHeight, quality: quality) { (imageData) in

                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: self.service.PERMISSION_ERROR);

                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId )

            }

        }
    }

    func getPhoto(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            
            let photoId = command.arguments[0] as! String

            self.service.getPhoto(photoId) { (imageData) in

                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: self.service.PERMISSION_ERROR);

                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)

            }

        }
    }

    func stopCaching(_ command: CDVInvokedUrlCommand) {

        self.service.stopCaching()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)

    }

    func requestAuthorization(_ command: CDVInvokedUrlCommand) {

        self.service.requestAuthorization({
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
            }, failure: { (err) in
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: err)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
            })

    }
    
    func saveImage(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            self.service.saveImage(url, album: album) { (url: URL?, error: String?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }
    
    func saveVideo(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            self.service.saveVideo(url, album: album) { (url: URL?, error: String?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
                }
            }
        }
    }

}
