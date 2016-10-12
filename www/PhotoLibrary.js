var exec = require('cordova/exec');

var defaultThumbnailWidth = 512; // optimal for android
var defaultThumbnailHeight = 384; // optimal for android

var defaultQuality = 0.5;

var isBrowser = cordova.platformId == 'browser';

// Will start caching for specified size
exports.getLibrary = function (success, error, options) {

  if (!options) {
    options = {};
  }

  options = {
    thumbnailWidth: options.thumbnailWidth ? options.thumbnailWidth : defaultThumbnailWidth,
    thumbnailHeight: options.thumbnailHeight ? options.thumbnailHeight : defaultThumbnailHeight,
  };

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getLibrary', [options]
  );

};

// Generates url that can be accessed directly, so it will work more efficiently than getThumbnail, which does base64 encode/decode.
// If success callback not provided, will return value immediately, but use success to make it browser-friendly
exports.getThumbnailUrl = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  if (typeof success !== 'function' && typeof options === 'undefined') {
    options = success;
    success = undefined;
  }

  options = getThumbnailOptionsWithDefaults(options);

  var thumbnailUrl = 'cdvphotolibrary://thumbnail?photoId=' + encodeURIComponent(photoId) +
      '&width=' + encodeURIComponent(options.thumbnailWidth) +
      '&height=' + encodeURIComponent(options.thumbnailHeight) +
      '&quality=' + encodeURIComponent(options.quality);

  if (success) {
    if (isBrowser) {
      cordova.exec(success, success, 'PhotoLibrary', '_getThumbnailUrlBrowser', [photoId, options]);
    } else {
      success(thumbnailUrl);
    }
  } else {
    return thumbnailUrl;
  }
};

// Provide same size as when calling getLibrary for better performance
exports.getThumbnail = function (photoIdOrLibraryItem, success, error, options) {

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

exports.getPhoto = function (photoIdOrLibraryItem, success, error, options) {

  var photoId = typeof photoIdOrLibraryItem.id !== 'undefined' ? photoIdOrLibraryItem.id : photoIdOrLibraryItem;

  if (!options) {
    options = {};
  }

  options = {};

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
exports.stopCaching = function (success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'stopCaching', []
  );

};

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
