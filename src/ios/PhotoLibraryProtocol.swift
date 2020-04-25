import Foundation

@objc(PhotoLibraryProtocol) class PhotoLibraryProtocol : CDVURLProtocol {
    
    static let PHOTO_LIBRARY_PROTOCOL = "cdvphotolibrary"
    static let DEFAULT_WIDTH = "512"
    static let DEFAULT_HEIGHT = "384"
    static let DEFAULT_QUALITY = "0.5"
    
    lazy var concurrentQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "PhotoLibrary Protocol Queue"
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        let scheme = request.url?.scheme
        
        if scheme?.lowercased() == PHOTO_LIBRARY_PROTOCOL {
            return true
        }
        
        return false
    }
    
    override func startLoading() {
        
        if let url = self.request.url {
            if url.path == "" {
                
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let queryItems = urlComponents?.queryItems
                
                // Errors are 404 as android plugin only supports returning 404
                
                let photoId = queryItems?.filter({$0.name == "photoId"}).first?.value
                if photoId == nil {
                    self.sendErrorResponse(404, error: "Missing 'photoId' query parameter")
                    return
                }
                
                if !PhotoLibraryService.hasPermission() {
                    self.sendErrorResponse(404, error: PhotoLibraryService.PERMISSION_ERROR)
                    return
                }
                
                let service = PhotoLibraryService.instance
                
                if url.host?.lowercased() == "thumbnail" {
                    
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
                    
                    concurrentQueue.addOperation {
                        service.getThumbnail(photoId!, thumbnailWidth: width!, thumbnailHeight: height!, quality: quality!) { (imageData) in
                            if (imageData == nil) {
                                self.sendErrorResponse(404, error: PhotoLibraryService.PERMISSION_ERROR)
                                return
                            }
                            self.sendResponseWithResponseCode(200, data: imageData!.data, mimeType: imageData!.mimeType)
                        }
                    }
                    
                    return
                    
                } else if url.host?.lowercased() == "photo" {
                    
                    concurrentQueue.addOperation {
                        service.getPhoto(photoId!) { (imageData) in
                            if (imageData == nil) {
                                self.sendErrorResponse(404, error: PhotoLibraryService.PERMISSION_ERROR)
                                return
                            }
                            self.sendResponseWithResponseCode(200, data: imageData!.data, mimeType: imageData!.mimeType)
                        }
                    }
                    
                    return
                    
                } else if url.host?.lowercased() == "video" {
                    
                    concurrentQueue.addOperation {
                        service.getVideo(photoId!) { (videoData) in
                            if (videoData == nil) {
                                self.sendErrorResponse(404, error: PhotoLibraryService.PERMISSION_ERROR)
                                return
                            }
                            self.sendResponseWithResponseCode(200, data: videoData!.data, mimeType: videoData!.mimeType)
                        }
                    }
                    
                    return
                    
                }
                
            }
        }
        
        let body = "URI not supported by PhotoLibrary"
        self.sendResponseWithResponseCode(404, data: body.data(using: String.Encoding.ascii), mimeType: nil)
        
    }
    
    
    override func stopLoading() {
        // do any cleanup here
    }
    
    fileprivate func sendErrorResponse(_ statusCode: Int, error: String) {
        self.sendResponseWithResponseCode(statusCode, data: error.data(using: String.Encoding.ascii), mimeType: nil)
    }
    
    // Cannot use sendResponseWithResponseCode from CDVURLProtocol, so copied one here.
    fileprivate func sendResponseWithResponseCode(_ statusCode: Int, data: Data?, mimeType: String?) {
        
        var mimeType = mimeType
        if mimeType == nil {
            mimeType = "text/plain"
        }
        
        let encodingName: String? = mimeType == "text/plain" ? "UTF-8" : nil
        
        let response: CDVHTTPURLResponse = CDVHTTPURLResponse(url: self.request.url!, mimeType: mimeType, expectedContentLength: data?.count ?? 0, textEncodingName: encodingName)
        response.statusCode = statusCode
        
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
        
        if (data != nil) {
            self.client?.urlProtocol(self, didLoad: data!)
        }
        self.client?.urlProtocolDidFinishLoading(self)
        
    }
    
    class CDVHTTPURLResponse: HTTPURLResponse {
        var _statusCode: Int = 0
        override var statusCode: Int {
            get {
                return _statusCode
            }
            set {
                _statusCode = newValue
            }
        }
        
        override var allHeaderFields: [AnyHashable: Any] {
            get {
                return [:]
            }
        }
    }
    
}
