var exec = require('cordova/exec');

var defaultThumbnailWidth = 256;
var defaultThumbnailHeight = 128;

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
    function (result) {
      success({ data: result[0], mimeType: result[1] });
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
    success,
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

//TODO: remove this
exports.echo = function (arg0, success, error) {
  exec(success, error, 'PhotoLibrary', 'echo', [arg0]);
};

//TODO: remove this
exports.echojs = function (arg0, success, error) {
  if (arg0 && typeof (arg0) === 'string' && arg0.length > 0) {
    success(arg0);
  } else {
    error('Empty message!');
  }
};
