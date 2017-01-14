// Will grant permission for READ_EXTERNAL_STORAGE, if running inside TRAVIS.
module.exports = function (ctx) {

  console.log('Executing paramedic-grant-permissions hook...');

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

  var command = 'pm grant io.cordova.hellocordova android.permission.READ_EXTERNAL_STORAGE';
  // See https://www.maketecheasier.com/run-bash-commands-background-linux/, http://stackoverflow.com/questions/3099092/why-cant-i-use-unix-nohup-with-bash-for-loop
  // This command will run the loop in background, until the app installed, so it will set the permission.
  var loop_command = 'adb -e shell "nohup sh -c \'until ' + command + '; do sleep 0.01; done\' & >/dev/null &"';

  console.log('Running ' + loop_command);
  exec(loop_command, function (error, stdout, stderr) {
    if (error) {
      deferral.reject(error);
    } else {
      deferral.resolve();
    }
  });

  return deferral.promise;
};
