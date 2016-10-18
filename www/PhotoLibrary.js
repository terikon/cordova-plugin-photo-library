var exec = require('cordova/exec');

var defaultThumbnailWidth = 512; // optimal for android
var defaultThumbnailHeight = 384; // optimal for android

var defaultQuality = 0.5;

var isBrowser = cordova.platformId == 'browser';

var photoLibrary = {};

// Will start caching for specified size
photoLibrary.getLibrary = function (success, error, options) {

  if (!options) {
    options = {};
  }

  options = {
    thumbnailWidth: options.thumbnailWidth ? options.thumbnailWidth : defaultThumbnailWidth,
    thumbnailHeight: options.thumbnailHeight ? options.thumbnailHeight : defaultThumbnailHeight,
  };

  cordova.exec(
    function (library) {
      addUrlsToLibrary(library, success, options);
    },
    error,
    'PhotoLibrary',
    'getLibrary', [options]
  );

};

// Generates url that can be accessed directly, so it will work more efficiently than getThumbnail, which does base64 encode/decode.
// If success callback not provided, will return value immediately, but use overload with success as it browser-friendly
photoLibrary.getThumbnailURL = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  if (typeof success !== 'function' && typeof options === 'undefined') {
    options = success;
    success = undefined;
  }

  options = getThumbnailOptionsWithDefaults(options);

  var thumbnailURL = 'cdvphotolibrary://thumbnail?photoId=' + fixedEncodeURIComponent(photoId) +
    '&width=' + fixedEncodeURIComponent(options.thumbnailWidth) +
    '&height=' + fixedEncodeURIComponent(options.thumbnailHeight) +
    '&quality=' + fixedEncodeURIComponent(options.quality);

  if (success) {
    if (isBrowser) {
      cordova.exec(success, error, 'PhotoLibrary', '_getThumbnailURLBrowser', [photoId, options]);
    } else {
      success(thumbnailURL);
    }
  } else {
    return thumbnailURL;
  }

};

// Generates url that can be accessed directly, so it will work more efficiently than getPhoto, which does base64 encode/decode.
// If success callback not provided, will return value immediately, but use overload with success as it browser-friendly
photoLibrary.getPhotoURL = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  if (typeof success !== 'function' && typeof options === 'undefined') {
    options = success;
    success = undefined;
  }

  if (!options) {
    options = {};
  }

  var photoURL = 'cdvphotolibrary://photo?photoId=' + fixedEncodeURIComponent(photoId);

  if (success) {
    if (isBrowser) {
      cordova.exec(success, success, 'PhotoLibrary', '_getPhotoURLBrowser', [photoId, options]);
    } else {
      success(photoURL);
    }
  } else {
    return photoURL;
  }

};

// Provide same size as when calling getLibrary for better performance
photoLibrary.getThumbnail = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  options = getThumbnailOptionsWithDefaults(options);

  cordova.exec(
    function (data, mimeType) {
      if (!mimeType && data.data && data.mimeType) {
        // workaround for browser platform cannot return multipart result
        mimeType = data.mimeType;
        data = data.data;
      }
      var blob = new Blob([data], {
        type: mimeType
      });
      success(blob);
    },
    error,
    'PhotoLibrary',
    'getThumbnail', [photoId, options]
  );

};

photoLibrary.getPhoto = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  if (!options) {
    options = {};
  }

  cordova.exec(
    function (data, mimeType) {
      if (!mimeType && data.data && data.mimeType) {
        // workaround for browser platform cannot return multipart result
        mimeType = data.mimeType;
        data = data.data;
      }
      var blob = new Blob([data], {
        type: mimeType
      });
      success(blob);
    },
    error,
    'PhotoLibrary',
    'getPhoto', [photoId, options]
  );

};

// Call when thumbnails are not longer needed for better performance
photoLibrary.stopCaching = function (success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'stopCaching', []
  );

};

// Call when getting errors that begin with 'Permission Denial'
photoLibrary.requestAuthorization = function (success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'requestAuthorization', []
  );

};

// url is file url or dataURL
photoLibrary.saveImage = function (url, album, imageFileName, success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'saveImage', [url, album, imageFileName]
  );

};

// url is file url or dataURL
photoLibrary.saveVideo = function (url, album, videoFileName, success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'saveVideo', [url, album, videoFileName]
  );

};

module.exports = photoLibrary;

var getThumbnailOptionsWithDefaults = function (options) {

  if (!options) {
    options = {};
  }

  options = {
    thumbnailWidth: options.thumbnailWidth ? options.thumbnailWidth : defaultThumbnailWidth,
    thumbnailHeight: options.thumbnailHeight ? options.thumbnailHeight : defaultThumbnailHeight,
    quality: options.quality ? options.quality : defaultQuality,
  };

  return options;

};

var addUrlsToLibrary = function (library, success, options) {

  var urlsLeft = library.length;

  var handlePhotoURL = function (libraryItem, photoURL) {
    libraryItem.photoURL = photoURL;
    urlsLeft -= 1;
    if (urlsLeft === 0) {
      success(library);
    }
  };

  var handleThumbnailURL = function (libraryItem, thumbnailURL) {
    libraryItem.thumbnailURL = thumbnailURL;
    photoLibrary.getPhotoURL(libraryItem, handlePhotoURL.bind(null, libraryItem), handleUrlError);
  };

  var handleUrlError = function () {}; // Should never happen

  var i;
  for (i = 0; i < library.length; i++) {
    var libraryItem = library[i];
    photoLibrary.getThumbnailURL(libraryItem, handleThumbnailURL.bind(null, libraryItem), handleUrlError, options);
  }

};

// from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
function fixedEncodeURIComponent(str) {
  return encodeURIComponent(str).replace(/[!'()*]/g, function (c) {
    return '%' + c.charCodeAt(0).toString(16);
  });
}
