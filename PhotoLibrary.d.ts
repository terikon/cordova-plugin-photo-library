// TODO: add types for options

interface PhotoLibraryCordovaPlugin {
  getLibrary(success: (any) => void, error: (err: any) => void, options: any);
  getThumbnail(photoId: string, success: (any) => void, error: (err: any) => void, options: any);
  getPhoto(photoId: string, success: (any) => void, error: (err: any) => void, options: any);
  stopCaching(success: () => void, error: (err: any) => void);
}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordovaPlugin;
}
