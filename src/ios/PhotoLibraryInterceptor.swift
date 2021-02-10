import Foundation
import Photos
import WebKit

class PhotoLibraryInterceptor {
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

    init() {
    }

    func handleSchemeTask(_ urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let url = urlSchemeTask.request.url else {
            return false
        }

        if url.lastPathComponent.lowercased() != "_app_file_thumbnail"
            && url.lastPathComponent.lowercased() != "_app_file_photo"
            && url.lastPathComponent.lowercased() != "_app_file_video" {
            return false
        }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        //Errors are 404 as android plugin inly supports returning 404

        guard let photoId = queryItems?.filter({$0.name == "photoId"}).first?.value else {
            self.sendErrorResponse(urlSchemeTask, 404, error: "Missing 'photoId' query parameter")
            return true
        }

        if PHPhotoLibrary.authorizationStatus() != .authorized {
            self.sendErrorResponse(urlSchemeTask, 404, error: PhotoLibraryService.PERMISSION_ERROR)
            return true
        }

        let service = PhotoLibraryService.instance

        if url.lastPathComponent.lowercased() == "_app_file_thumbnail" {

            let widthStr = queryItems?.filter({$0.name == "width"}).first?.value ?? PhotoLibraryInterceptor.DEFAULT_WIDTH
            guard let width = Int(widthStr) else {
                self.sendErrorResponse(urlSchemeTask, 404, error: "Incorrect 'width' query parameter")
                return true
            }

            let heightStr = queryItems?.filter({$0.name == "height"}).first?.value ?? PhotoLibraryInterceptor.DEFAULT_HEIGHT
            guard let height = Int(heightStr) else {
                self.sendErrorResponse(urlSchemeTask, 404, error: "Incorrect 'height' query parameter")
                return true
            }

            let qualityStr = queryItems?.filter({$0.name == "quality"}).first?.value ?? PhotoLibraryInterceptor.DEFAULT_QUALITY
            guard let quality = Float(qualityStr) else {
                self.sendErrorResponse(urlSchemeTask, 404, error: "Incorrect 'quality' query parameter")
                return true
            }

            concurrentQueue.addOperation {
                service.getThumbnail(photoId, thumbnailWidth: width, thumbnailHeight: height, quality: quality) { (imageData) in

                    guard let imageData = imageData else {
                        self.sendErrorResponse(urlSchemeTask, 404, error: PhotoLibraryService.PERMISSION_ERROR)
                        return
                    }

                    self.sendResponse(urlSchemeTask, 200, data: imageData.data, mimeType: imageData.mimeType)
                }
            }

        } else if url.lastPathComponent.lowercased() == "_app_file_photo" {

            concurrentQueue.addOperation {
                service.getPhoto(photoId) { (imageData) in
                    guard let imageData = imageData else {
                        self.sendErrorResponse(urlSchemeTask, 404, error: PhotoLibraryService.PERMISSION_ERROR)
                        return
                    }
                    self.sendResponse(urlSchemeTask, 200, data: imageData.data, mimeType: imageData.mimeType)
                }
            }

        } else if url.lastPathComponent.lowercased() == "_app_file_video" {

            concurrentQueue.addOperation {
                service.getVideo(photoId) { (videoData) in
                    guard let videoData = videoData else {
                        self.sendErrorResponse(urlSchemeTask, 404, error: PhotoLibraryService.PERMISSION_ERROR)
                        return
                    }
                    self.sendResponse(urlSchemeTask, 200, data: videoData.data, mimeType: videoData.mimeType)
                }
            }

        } else {
            return false
        }

        return true
    }

    func sendErrorResponse(_ urlSchemeTask: WKURLSchemeTask, _ statusCode: Int, error: String) {
        print(error);
        
        let response = HTTPURLResponse(url: urlSchemeTask.request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        urlSchemeTask.didReceive(response!)
        urlSchemeTask.didFinish()
    }

    func sendResponse(_ urlSchemeTask: WKURLSchemeTask, _ statusCode: Int, data: Data?, mimeType: String?) {
        let mimeType: String = mimeType ?? "text/plain"
        let encodingName: String? = mimeType == "text/plain" ? "UTF-8" : nil

        let response: CDVHTTPURLResponse = CDVHTTPURLResponse(url: urlSchemeTask.request.url!, mimeType: mimeType, expectedContentLength: data?.count ?? 0, textEncodingName: encodingName)
        response.statusCode = statusCode

        urlSchemeTask.didReceive(response)
        if data != nil {
            urlSchemeTask.didReceive(data!)
        }

        urlSchemeTask.didFinish()
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
