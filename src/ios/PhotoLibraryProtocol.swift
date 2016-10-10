import Foundation

@objc(PhotoLibrary) class PhotoLibraryProtocol : CDVURLProtocol {

    let service: PhotoLibraryService

    public init() {
      service = PhotoLibraryService.instance
    }

}
