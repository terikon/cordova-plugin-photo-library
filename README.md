**Work in progress**

Parts are based on

- https://github.com/subitolabs/cordova-gallery-api
- https://github.com/SuryaL/cordova-gallery-api
- https://github.com/ryouaki/Cordova-Plugin-Photos 

# TODO

- iOS: Bug: It seems to ignore png files
- iOS: Handle cases where image returned by requestImageDataForAsset is null
- Browser platform: Separate to multiple files
- Browser platform: Compile plugin with webpack
- Android: caching mechanism like [this one](https://developer.android.com/training/displaying-bitmaps/cache-bitmap.html) can be helpful
- Implement cdvphotolibrary schema. Currenly on android added stub that returns text result. It will be something like cdvphotolibrary://thumbnail?fileid=xxx&width=128&height=128&quality=0.5
- Implement cdvphotolibrary upload (post), which will enable efficient file saving to gallery.

# Usage

```js
var library = cordova.plugins.photoLibrary.getLibrary(
  function(library) {

  },
  function(err) {
    console.log('Error occured');
  }
);
```

```js
cordova.plugins.photoLibrary.getThumbnail(
  libraryItem.id,
  function(thumbnailBlob) {

  },
  function(err) {
    console.log('Error occured');
  },
  {
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });
```

```js
cordova.plugins.photoLibrary.getPhoto(
  libraryItem.id,
  function(fullPhotoBlob) {

  },
  function(err) {
    console.log('Error occured');
  });
```

```js
var thumbnailUrl = cordova.plugins.photoLibrary.getThumbnailUrl(
  libraryItem,
  {
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });

image.src = thumbnailUrl; 
```

# TypeScript

TypeScript definitions are provided in [PhotoLibrary.d.ts](https://github.com/terikon/cordova-plugin-photo-library/blob/master/PhotoLibrary.d.ts)

# References

## Android relevant documentation

https://developer.android.com/reference/org/json/JSONObject.html
https://developer.android.com/reference/android/provider/MediaStore.Images.Media.html
https://developer.android.com/reference/android/provider/MediaStore.Images.Thumbnails.html
https://developer.android.com/reference/android/graphics/BitmapFactory.Options.html
https://developer.android.com/reference/android/media/ThumbnailUtils.html
