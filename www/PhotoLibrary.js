var exec = require('cordova/exec');

var defaultThumbnailWidth = 256;
var defaultThumbnailHeight = 128;

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

exports.getThumbnailURL = function (photoId, success, error, options) {

  if (!options) {
    options = {};
  }

  options = {
    thumbnailWidth: options.thumbnailWidth ? options.thumbnailWidth : defaultThumbnailWidth,
    thumbnailHeight: options.thumbnailHeight ? options.thumbnailHeight : defaultThumbnailHeight,
    quality: options.quality ? options.quality : 0.5,
  };

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getThumbnail',
    [photoId, options]
  );
};

exports.getPhotoURL = function (photoId, success, error, options) {

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
}

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
