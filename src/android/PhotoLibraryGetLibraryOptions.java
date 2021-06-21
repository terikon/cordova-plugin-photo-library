package com.terikon.cordova.photolibrary;

public class PhotoLibraryGetLibraryOptions {

  public final int itemsInChunk;
  public final int maxItems;
  public final double chunkTimeSec;
  public final boolean includeAlbumData;

  public PhotoLibraryGetLibraryOptions(int itemsInChunk, int maxItems, double chunkTimeSec, boolean includeAlbumData) {
    this.itemsInChunk = itemsInChunk;
    this.maxItems = maxItems;
    this.chunkTimeSec = chunkTimeSec;
    this.includeAlbumData = includeAlbumData;
  }

}
