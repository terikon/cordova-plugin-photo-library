// TODO: add types for optios

interface PhotoLibraryCordovaPlugin {
  getLibrary(success, error, options);
  getThumbnailURL(photoId, success, error, options);
  getPhotoURL(photoId, success, error, options);
}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordovaPlugin;
}
