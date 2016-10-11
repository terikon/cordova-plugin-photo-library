import Foundation

@objc class PhotoLibrary : CDVPlugin {

    var service: PhotoLibraryService!

    override func pluginInitialize() {
        service = PhotoLibraryService.instance

        //[NSURLProtocol registerClass:[CDVFilesystemURLProtocol class]];
        NSURLProtocol.registerClass(PhotoLibraryProtocol)
    }

    override func onMemoryWarning() {
        self.service.stopCaching()
    }

    // TODO: handleOpenURL?
    // override func handleOpenURL(NSNotification notification) {
    // override to handle urls sent to your app
    // register your url schemes in your App-Info.plist
    // NSURL* url = [notification object];
    // if ([url isKindOfClass:[NSURL class]]) {
    //     /* Do your thing! */
    // }
    // }

    // TODO: override this:
    // - (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;
    // {
    //     NSURL *url = [request URL];
    //     NSDictionary *settings = [(CDVViewController *)self.viewController settings];
    //     if ([[url scheme] isEqualToString:@"maps"] || [[settings objectForKey:@"launchexternalforhost"] isEqualToString:[url host]]) {
    //         if ([[UIApplication sharedApplication] canOpenURL:url]) {
    //             [[UIApplication sharedApplication] openURL:url];
    //             return YES;
    //         }
    //     }
    //     return NO;
    // }
    // and this:
    //startLoading
    // handle self.request
    // - (void)startLoading
    // {
    //   NSURL* *uriRequest = [[self request] URL];
    //   if(NSOrderedSame == [[*uriRequest scheme] caseInsensitiveCompare:@"file"]){
    //     NSError * error = [NSError errorWithDomain:@"Forbidden" code:403 userInfo:nil];
    //     [[self client] URLProtocol:self didFailWithError:error];
    //     return;
    //   }
    //   NSURLConnection *connection = [NSURLConnection connectionWithRequest:[self request] delegate:self];
    //   [self setConnection:connection];
    // }

    // Will sort by creation date
    func getLibrary(command: CDVInvokedUrlCommand) {
        dispatch_async(dispatch_get_main_queue()) {
            
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
        dispatch_async(dispatch_get_main_queue()) {

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
        dispatch_async(dispatch_get_main_queue()) {

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

        self.service.stopCaching()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId	)

    }

}
