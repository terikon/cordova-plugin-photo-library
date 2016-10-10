final class PhotoLibraryService {

  private init() {

  }

  class var instance: PhotoLibraryService {
    struct SingletonWrapper {
      static let singleton = PhotoLibraryService()
    }
    return SingletonWrapper.singleton
  }

}
