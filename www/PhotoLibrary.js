var exec = require('cordova/exec');

exports.getLibrary = function (success, error, options) {

  if (!options) {
    options = {};
  }

  var params = {};

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getLibrary',
    [params]
  );
};

exports.getThumbnailURL = function (photoId, success, error, options) {

  if (!options) {
    options = {};
  }

  var params = {
    height: options.height ? options.height : 200,
    quality: options.quality ? options.quality : 0.5,
  };

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getThumbnailURL',
    [photoId, params]
  );
};

exports.getPhotoURL = function (photoId, success, error, options) {

  if (!options) {
    options = {};
  }

  var params = {};

  cordova.exec(
    success,
    error,
    'PhotoLibrary',
    'getPhotoURL',
    [photoId, params]
  );
}

//TODO: remove this
exports.echo = function (arg0, success, error) {
  exec(success, error, "PhotoLibrary", "echo", [arg0]);
};

//TODO: remove this
exports.echojs = function (arg0, success, error) {
  if (arg0 && typeof (arg0) === 'string' && arg0.length > 0) {
    success(arg0);
  } else {
    error('Empty message!');
  }
};
