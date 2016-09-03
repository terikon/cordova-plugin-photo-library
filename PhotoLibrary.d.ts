interface PhotoLibraryCordovaPlugin {
  getLibrary(success, error);
  getThumbnailURL(photoId, success, error);
  getPhotoURL(photoId, success, error);
}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordovaPlugin;
}
