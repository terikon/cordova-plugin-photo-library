exports.defineAutoTests = function () {

  jasmine.DEFAULT_TIMEOUT_INTERVAL = 20000; // In browser platform, gives a time to select photos.

  describe('cordova.plugins', function () {

    it('photoLibrary should exist', function () {
      expect(cordova.plugins.photoLibrary).toBeDefined();
    });

    describe('cordova.plugins.photoLibrary', function () {

      var library = null;

      beforeAll(function (done) {
        cordova.plugins.photoLibrary.getLibrary(function (lib) {
          library = lib;
          done();
        },
        function (err) {
          fail('expected to succeed, failed with error instead: ' + err);
        });
      });

      describe('cordova.plugins.photoLibrary.getLibrary', function () {

        it('should return multiple photos', function () {
          expect(library.length).toBeGreaterThan(0);
        });

      });

      describe('cordova.plugins.photoLibrary.getThumbnailURL', function () {

      });

      describe('cordova.plugins.photoLibrary.getPhotoURL', function () {

      });

      describe('cordova.plugins.photoLibrary.getThumbnail', function () {

      });

      describe('cordova.plugins.photoLibrary.getPhoto', function () {

      });

      describe('cordova.plugins.photoLibrary.requestAuthorization', function () {

      });

      describe('cordova.plugins.photoLibrary.saveImage', function () {

      });

      describe('cordova.plugins.photoLibrary.saveVideo', function () {

      });

    });

  });

};

exports.defineManualTests = function (contentEl, createActionButton) {

  var logMessage = function (message, color) {
    var log = document.getElementById('info');
    var logLine = document.createElement('div');
    if (color) {
      logLine.style.color = color;
    }
    logLine.innerHTML = message;
    log.appendChild(logLine);
  };

  var clearLog = function () {
    var log = document.getElementById('info');
    log.innerHTML = '';
  };

  var device_tests = '<h3>Press Dump Device button to get device information</h3>' +
    '<div id="dump_device"></div>' +
    'Expected result: Status box will get updated with device info. (i.e. platform, version, uuid, model, etc)';

  contentEl.innerHTML = '<div id="info"></div>' + device_tests;

  createActionButton('Dump device', function () {
    clearLog();
    //logMessage(JSON.stringify(window.device, null, '\t'));
    logMessage('Test result can be here...');
  }, 'dump_device');

};
