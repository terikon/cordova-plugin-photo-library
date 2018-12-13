import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    lazy var concurrentQueue: DispatchQueue = DispatchQueue(label: "photo-library.queue.plugin", qos: DispatchQoS.utility, attributes: [.concurrent])
    
    override func pluginInitialize() {

        // Do not call PhotoLibraryService here, as it will cause permission prompt to appear on app start.

        URLProtocol.registerClass(PhotoLibraryProtocol.self)

    }

    //    override func onMemoryWarning() {
    //        self.service.stopCaching()
    //    }

    // Will sort by creation date
    func getLibrary(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let options = command.arguments[0] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let itemsInChunk = options["itemsInChunk"] as! Int
            let chunkTimeSec = options["chunkTimeSec"] as! Double
            let useOriginalFileNames = options["useOriginalFileNames"] as! Bool
            let includeAlbumData = options["includeAlbumData"] as! Bool

            func createResult (library: [NSDictionary], chunkNum: Int, isLastChunk: Bool) -> [String: AnyObject] {
                let result: NSDictionary = [
                    "chunkNum": chunkNum,
                    "isLastChunk": isLastChunk,
                    "library": library
                ]
                return result as! [String: AnyObject]
            }

            let getLibraryOptions = PhotoLibraryGetLibraryOptions(thumbnailWidth: thumbnailWidth,
                                                                  thumbnailHeight: thumbnailHeight,
                                                                  itemsInChunk: itemsInChunk,
                                                                  chunkTimeSec: chunkTimeSec,
                                                                  useOriginalFileNames: useOriginalFileNames,
                                                                  includeAlbumData: includeAlbumData)

            service.getLibrary(getLibraryOptions,
                completion: { (library, chunkNum, isLastChunk) in

                    let result = createResult(library: library, chunkNum: chunkNum, isLastChunk: isLastChunk)

                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
                    pluginResult!.setKeepCallbackAs(!isLastChunk)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)

                })

        }
    }
    
    func getAlbums(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let albums = service.getAlbums()
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: albums)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            
        }
    }
    
    func getThumbnail(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

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
        concurrentQueue.async {

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
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String

            service.saveImage(url, album: album) { (libraryItem: NSDictionary?, error: String?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: libraryItem as! [String: AnyObject]?)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
                }
            }

        }
    }

    func saveVideo(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

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
