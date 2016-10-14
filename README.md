**Work in progress**

We needed a library that displays photo libraty in HTML. That gets thumbnail of arbitrary sizes, works on multiple platforms, and is fast. 

So here it is.

- Displays photo gallery as web page, and not as native screen.
- Works on android, ios and browser (cordova serve).
- Fast - does not do base64 and uses browser cache.
- On device, provides custom schema to access thumbnails: cdvphotolibrary://thumbnail?fileid=xxx&width=128&height=128&quality=0.5
- On ios, written in Swift and not Objective-C.

Contributions are welcome.

# Usage

Add cdvphotolibrary protocol to Content-Security-Policy, like this:

```
<meta http-equiv="Content-Security-Policy" content="default-src 'self' data: gap: https://ssl.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: cdvphotolibrary:">
```

```js
cordova.plugins.photoLibrary.getLibrary(
  function (library) {
    
    // Here we have the library as array

    library.forEach(function(libraryItem) {
      console.log(libraryItem.id);          // Id of the photo
      console.log(libraryItem.photoURL);    // Cross-platform access to photo
      console.log(libraryItem.thumbnailURL);// Cross-platform access to thumbnail
      console.log(libraryItem.filename);
      console.log(libraryItem.width);
      console.log(libraryItem.height);
      console.log(libraryItem.creationDate);
      console.log(libraryItem.nativeURL);   // Do not use, as it is not accessible on all platforms
    });

  },
  function (err) {
    console.log('Error occured');
  },
  {
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  }
);
```

This method is fast, as thumbails will be generated on demand.

## In addition you can ask thumbnail or full image for each photo separately, as cross-platform url or as blob

```js
// Use this method to get url. It's better to use it and not directly access cdvphotolibrary://, as it will also work on browser.
cordova.plugins.photoLibrary.getThumbnailURL(
  libraryItem, // or libraryItem.id 
  function (thumbnailURL) {

    image.src = thumbnailURL;

  },
  function (err) {
    console.log('Error occured');
  },
  {
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });
```

```js
cordova.plugins.photoLibrary.getPhotoURL(
  libraryItem, // or libraryItem.id 
  function (photoURL) {

    image.src = photoURL;

  },
  function (err) {
    console.log('Error occured');
  });
```

```js
// This method is slower as it does base64
cordova.plugins.photoLibrary.getThumbnail(
  libraryItem, // or libraryItem.id
  function (thumbnailBlob) {

  },
  function (err) {
    console.log('Error occured');
  },
  {
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });
```

```js
// This method is slower as it does base64
cordova.plugins.photoLibrary.getPhoto(
  libraryItem, // or libraryItem.id
  function (fullPhotoBlob) {

  },
  function (err) {
    console.log('Error occured');
  });
```

# TypeScript

TypeScript definitions are provided in [PhotoLibrary.d.ts](https://github.com/terikon/cordova-plugin-photo-library/blob/master/PhotoLibrary.d.ts)

# TODO

- iOS: Bug: It seems to ignore png files
- iOS: Handle (theoretical) cases where image returned by requestImageDataForAsset is null
- iOS: PHImageContentMode.AspectFill returns images that larger than requested. Perform manual resizing.
- Browser platform: Separate to multiple files
- Browser platform: Compile plugin with webpack
- Android: caching mechanism like [this one](https://developer.android.com/training/displaying-bitmaps/cache-bitmap.html) can be helpful

# References

Parts are based on

- https://github.com/subitolabs/cordova-gallery-api
- https://github.com/SuryaL/cordova-gallery-api
- https://github.com/ryouaki/Cordova-Plugin-Photos

## Relevant platform documentation

https://developer.android.com/reference/org/json/JSONObject.html
https://developer.android.com/reference/android/provider/MediaStore.Images.Media.html
https://developer.android.com/reference/android/provider/MediaStore.Images.Thumbnails.html
https://developer.android.com/reference/android/graphics/BitmapFactory.Options.html
https://developer.android.com/reference/android/media/ThumbnailUtils.html
