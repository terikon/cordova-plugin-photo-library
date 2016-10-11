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
        let url = self.request.URL
 
        if url?.path?.lowercaseString == "/thumbnail" {
         
            return
        }
        
        let body = "Access not allowed"
        self.sendResponseWithResponseCode(401, data: body.dataUsingEncoding(NSASCIIStringEncoding), mimeType: nil)
    }
    
    override func stopLoading() {
        // do any cleanup here
    }
    
    func sendResponseWithResponseCode(statusCode: Int, data: NSData?, mimeType: String?) {
        
        var mimeType = mimeType
        if mimeType == nil {
            mimeType = "text/plain"
        }
        
        let encodingName: String? = mimeType == "text/plain" ? "UTF-8" : nil
        
        let response: CDVHTTPURLResponse = CDVHTTPURLResponse(URL: self.request.URL!, MIMEType: mimeType, expectedContentLength: data?.length ?? 0, textEncodingName: encodingName)
        response.statusCode = statusCode
        
        self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed)
        
        if (data != nil) {
            self.client?.URLProtocol(self, didLoadData: data!)
        }
        self.client?.URLProtocolDidFinishLoading(self)
        
    }
    
    class CDVHTTPURLResponse: NSHTTPURLResponse {
        var _statusCode: Int = 0
        override var statusCode: Int {
            get {
                return _statusCode
            }
            set {
                _statusCode = newValue
            }
        }
        
        override var allHeaderFields: [NSObject : AnyObject] {
            get {
                return [:]
            }
        }
    }
    
}
