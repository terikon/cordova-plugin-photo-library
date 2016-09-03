var exec = require('cordova/exec');

exports.echo = function (arg0, success, error) {
  exec(success, error, "PhotoLibrary", "echo", [arg0]);
};

exports.echojs = function (arg0, success, error) {
  if (arg0 && typeof (arg0) === 'string' && arg0.length > 0) {
    success(arg0);
  } else {
    error('Empty message!');
  }

};

exports.getLibrary = function (success, error, options) {
  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getLibrary',
    []
  );
}

exports.getThumbnailURL = function (photoId, success, error, options) {
  var thumbnailHeight = options && options.height;
  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getThumbnailURL',
    [photoId, thumbnailHeight]
  );
}

exports.getPhotoURL = function (photoId, success, error, options) {
  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getPhotoURL',
    [photoId]
  );
}
