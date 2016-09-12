declare module PhotoLibraryCordova {

  export interface Plugin {
    getLibrary(success: (result: LibraryItem[]) => void, error: (err: any) => void, options: GetLibraryOptions): void;
    getThumbnail(photoId: string, success: (result: Photo) => void, error: (err: any) => void, options: GetThumbnailOptions): void;
    getPhoto(photoId: string, success: (result: Photo) => void, error: (err: any) => void, options: GetPhotoOptions): void;
    stopCaching(success: () => void, error: (err: any) => void): void;
  }

  export interface LibraryItem {
    id: string,
    filename: string,
    nativeURL: string,
    width: number,
    height: number,
    creationDate: any,
  }

  export interface Photo {
    data: Blob,
    mimeType: string,
  }

  export interface GetLibraryOptions {
    thumbnailWidth: number,
    thumbnailHeight: number,
  }

  export interface GetThumbnailOptions {
    thumbnailWidth: number,
    thumbnailHeight: number,
    quality: number,
  }

  export interface GetPhotoOptions {
  }

}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordova.Plugin;
}
