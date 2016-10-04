var exec = require('cordova/exec');

var defaultThumbnailWidth = 512;  // optimal for android
var defaultThumbnailHeight = 384; // optimal for android

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
    'getLibrary',
    [options]
  );

};

// Provide same size as when calling getLibrary for better performance
exports.getThumbnail = function (photoId, success, error, options) {

  if (!options) {
    options = {};
  }

  options = {
    thumbnailWidth: options.thumbnailWidth ? options.thumbnailWidth : defaultThumbnailWidth,
    thumbnailHeight: options.thumbnailHeight ? options.thumbnailHeight : defaultThumbnailHeight,
    quality: options.quality ? options.quality : 0.5,
  };

  cordova.exec(
    function (data, mimeType) {
      if (!mimeType && data.data && data.mimeType) {
        // workaround for browser platform cannot return multipart result
        mimeType = data.mimeType;
        data = data.data;
      }
      var blob = new Blob([data], { type: mimeType });
      success(blob);
    },
    error,
    'PhotoLibrary',
    'getThumbnail',
    [photoId, options]
  );

};

exports.getPhoto = function (photoId, success, error, options) {

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
      var blob = new Blob([data], { type: mimeType });
      success(blob);
    },
    error,
    'PhotoLibrary',
    'getPhoto',
    [photoId, options]
  );

};

// Call when thumbnails are not longer needed for better performance
exports.stopCaching = function (success, error) {

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'stopCaching',
    []
  );

};
