import Foundation

@objc(PhotoLibraryProtocol) class PhotoLibraryProtocol : CDVURLProtocol {
    
    static let PHOTO_LIBRARY_PROTOCOL = "cdvphotolibrary"
    static let DEFAULT_WIDTH = "512"
    static let DEFAULT_HEIGHT = "384"
    static let DEFAULT_QUALITY = "0.5"
    
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
        
        if let url = self.request.URL {
            if url.path == "" {
                
                let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
                let queryItems = urlComponents?.queryItems
                
                // Errors are 404 as android plugin only supports returning 404
                
                let photoId = queryItems?.filter({$0.name == "photoId"}).first?.value
                if photoId == nil {
                    self.sendErrorResponse(404, error: "Missing 'photoId' query parameter")
                    return
                }
                
                if url.host?.lowercaseString == "thumbnail" {
                    
                    let widthStr = queryItems?.filter({$0.name == "width"}).first?.value ?? PhotoLibraryProtocol.DEFAULT_WIDTH
                    let width = Int(widthStr)
                    if width == nil {
                        self.sendErrorResponse(404, error: "Incorrect 'width' query parameter")
                        return
                    }
                    
                    let heightStr = queryItems?.filter({$0.name == "height"}).first?.value ?? PhotoLibraryProtocol.DEFAULT_HEIGHT
                    let height = Int(heightStr)
                    if height == nil {
                        self.sendErrorResponse(404, error: "Incorrect 'height' query parameter")
                        return
                    }
                    
                    let qualityStr = queryItems?.filter({$0.name == "quality"}).first?.value ?? PhotoLibraryProtocol.DEFAULT_QUALITY
                    let quality = Float(qualityStr)
                    if quality == nil {
                        self.sendErrorResponse(404, error: "Incorrect 'quality' query parameter")
                        return
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        self.service.getThumbnail(photoId!, thumbnailWidth: width!, thumbnailHeight: height!, quality: quality!) { (imageData) in
                            self.sendResponseWithResponseCode(200, data: imageData.data, mimeType: imageData.mimeType)
                        }
                    }
                    
                    return
                    
                } else if url.host?.lowercaseString == "photo" {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        self.service.getPhoto(photoId!) { (imageData) in
                            self.sendResponseWithResponseCode(200, data: imageData.data, mimeType: imageData.mimeType)
                        }
                    }
                    
                    return
                    
                }
            }
        }
        
        let body = "URI not supported by PhotoLibrary"
        self.sendResponseWithResponseCode(404, data: body.dataUsingEncoding(NSASCIIStringEncoding), mimeType: nil)
        
    }
    
    
    override func stopLoading() {
        // do any cleanup here
    }
    
    private func sendErrorResponse(statusCode: Int, error: String) {
        self.sendResponseWithResponseCode(statusCode, data: error.dataUsingEncoding(NSASCIIStringEncoding), mimeType: nil)
    }
    
    // Cannot use sendResponseWithResponseCode from CDVURLProtocol, so copied one here.
    private func sendResponseWithResponseCode(statusCode: Int, data: NSData?, mimeType: String?) {
        
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
