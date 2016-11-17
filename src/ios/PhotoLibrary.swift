import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {
    
    override func pluginInitialize() {
        
        // Do not call PhotoLibraryService here, as it will cause permission prompt to appear on app start.
        
        URLProtocol.registerClass(PhotoLibraryProtocol.self)
        
    }
    
    //    override func onMemoryWarning() {
    //        self.service.stopCaching()
    //    }
    
    // Will sort by creation date
    func getLibrary(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            
            func createResult (library: [NSDictionary], isPartial: Bool) -> [String: AnyObject] {
                let result: NSDictionary = [
                    "isPartial": isPartial,
                    "library": library
                ]
                return result as! [String: AnyObject]
            }
            
            service.getLibrary(
                thumbnailWidth, thumbnailHeight: thumbnailHeight,
                partialCallback: { (library) in
                    
                    let result = createResult(library: library, isPartial: true)
                    
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
                    pluginResult!.setKeepCallbackAs(true)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                    
                },
                completion: { (library) in
                    
                    let result = createResult(library: library, isPartial: false)
                    
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                    
                })
            
        }
    }
    
    func getThumbnail(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let quality = options["quality"] as! Float
            
            service.getThumbnail(photoId, thumbnailWidth: thumbnailWidth, thumbnailHeight: thumbnailHeight, quality: quality) { (imageData) in
                
                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "Could not fetch the thumbnail")
                
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId )
                
            }
            
        }
    }
    
    func getPhoto(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let photoId = command.arguments[0] as! String
            
            service.getPhoto(photoId) { (imageData) in
                
                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "Could not fetch the image")
                
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
                
            }
            
        }
    }
    
    func stopCaching(_ command: CDVInvokedUrlCommand) {
        
        let service = PhotoLibraryService.instance
        
        service.stopCaching()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
        
    }
    
    func requestAuthorization(_ command: CDVInvokedUrlCommand) {
        
        let service = PhotoLibraryService.instance
        
        service.requestAuthorization({
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
        }, failure: { (err) in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: err)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
        })
        
    }
    
    func saveImage(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            service.saveImage(url, album: album) { (url: URL?, error: String?) in
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
        DispatchQueue.global(qos: .default).async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            
            service.saveVideo(url, album: album) { (url: URL?, error: String?) in
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
