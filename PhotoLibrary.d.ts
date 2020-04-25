declare module PhotoLibraryCordova {

  export interface Plugin {

    getLibrary(success: (chunk: { library: LibraryItem[], isLastChunk: boolean }) => void, error: (err: any) => void, options?: GetLibraryOptions): void;

    requestAuthorization(success: () => void, error: (err: any) => void, options?: RequestAuthorizationOptions): void;

    getAlbums(success: (result: AlbumItem[]) => void, error: (err:any) => void): void;
    isAuthorized(success: (result: boolean) => void, error: (err:any) => void): void;

    getThumbnailURL(photoId: string, success: (result: string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnailURL(libraryItem: LibraryItem, success: (result: string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnailURL(photoId: string, options?: GetThumbnailOptions): string; // Will not work in browser
    getThumbnailURL(libraryItem: LibraryItem, options?: GetThumbnailOptions): string; // Will not work in browser

    getPhotoURL(photoId: string, success: (result: string) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhotoURL(libraryItem: LibraryItem, success: (result: string) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhotoURL(photoId: string, options?: GetPhotoOptions): string; // Will not work in browser
    getPhotoURL(libraryItem: LibraryItem, options?: GetPhotoOptions): string; // Will not work in browser

    getThumbnail(photoId: string, success: (result: Blob) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnail(libraryItem: LibraryItem, success: (result: Blob) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;

    getPhoto(photoId: string, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhoto(libraryItem: LibraryItem, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getLibraryItem(libraryItem: LibraryItem, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;

    stopCaching(success: () => void, error: (err: any) => void): void;

    saveImage(url: string, album: AlbumItem | string, success: (libraryItem: LibraryItem) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;

    saveVideo(url: string, album: AlbumItem | string, success: () => void, error: (err: any) => void): void;

  }

  export interface LibraryItem {
    id: string;
    photoURL: string;
    thumbnailURL: string;
    fileName: string;
    width: number;
    height: number;
    creationDate: Date;
    latitude?: number;
    longitude?: number;
    albumIds?: string[];
  }

  export interface AlbumItem {
    id: string;
    title: string;
  }

  export interface GetLibraryOptions {
    thumbnailWidth?: number;
    thumbnailHeight?: number;
    quality?: number;
    itemsInChunk?: number;
    chunkTimeSec?: number;
    useOriginalFileNames?: boolean;
    includeImages?: boolean;
    includeAlbumData?: boolean;
    includeCloudData?: boolean;
    includeVideos?: boolean;
    maxItems?: number;
  }

  export interface RequestAuthorizationOptions {
    read?: boolean;
    write?: boolean;
  }

  export interface GetThumbnailOptions {
    thumbnailWidth?: number;
    thumbnailHeight?: number;
    quality?: number;
  }

  export interface GetPhotoOptions {
  }

}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordova.Plugin;
}
