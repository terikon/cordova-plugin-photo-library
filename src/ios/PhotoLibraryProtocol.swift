import Foundation

@objc class PhotoLibraryProtocol : CDVURLProtocol {

    let service: PhotoLibraryService

    override init(request: NSURLRequest, cachedResponse: NSCachedURLResponse?, client: NSURLProtocolClient?) {
        self.service = PhotoLibraryService.instance
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
   

}
