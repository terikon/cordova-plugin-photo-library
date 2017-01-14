module.exports = function (ctx) {

  // make sure android platform is part of build
  if (ctx.opts.platforms.indexOf('android') < 0) {
    return;
  }

  var IS_TRAVIS = process.env.TRAVIS;
  //CORDOVA_VERSION = process.env.CORDOVA_VERSION,

  /*
  if (!IS_TRAVIS) {
    return;
  }
  */

  var fs = ctx.requireCordovaModule('fs'),
    path = ctx.requireCordovaModule('path'),
    exec = ctx.requireCordovaModule('child_process').exec,
    deferral = ctx.requireCordovaModule('q').defer();

  var command = 'adb -e shell pm grant io.cordova.hellocordova android.permission.READ_EXTERNAL_STORAGE';

  console.log('Running ' + command);
  exec(command, function (error, stdout, stderr) {
    if (error) {
      deferral.reject(error);
    } else {
      deferral.resolve();
    }
  });

  return deferral.promise;
};
