import Foundation

@objc(PhotoLibraryProtocol) class PhotoLibraryProtocol : CDVURLProtocol {

    static let PHOTO_LIBRARY_PROTOCOL = "cdvphotolibrary"
    
    let service: PhotoLibraryService

    override init(request: NSURLRequest, cachedResponse: NSCachedURLResponse?, client: NSURLProtocolClient?) {
        self.service = PhotoLibraryService.instance
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        let scheme = request.URL?.scheme
        if scheme?.lowercaseString == PHOTO_LIBRARY_PROTOCOL {
            return true
        }
        return false
    }
    
    override func startLoading() {
        
    }
    
    override func stopLoading() {
        
    }

}
