exports.defineAutoTests = function () {

  describe('cordova.plugins', function () {

    it('photoLibrary should exist', function () {
      expect(cordova.plugins.photoLibrary).toBeDefined();
    });

    describe('cordova.plugins.photoLibrary', function () {

      var library = null;
      var libraryError = '';

      beforeAll(function (done) {
        cordova.plugins.photoLibrary.getLibrary(function (lib) {
          library = lib;
          done();
        },
        function (err) {
          libraryError = err;
          done.fail(err);
        });
      }, 20000); // In browser platform, gives a time to select photos.

      it('should load library', function() {
        expect(library).not.toBeNull('getLibrary failed with error: ' + libraryError);
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

  var photo_library_tests = '<h3>Press requestAuthorization button to authorize storage</h3>' +
    '<div id="request_authorization"></div>' +
    'Expected result: If authorized, this fact will be logged. On iOS: settings page will open. On Android: confirmation prompt will open.';

  contentEl.innerHTML = '<div id="info"></div>' + photo_library_tests;

  createActionButton('requestAuthorization', function () {
    clearLog();
    cordova.plugins.photoLibrary.requestAuthorization(
      function () {
        logMessage('User gave us permission to his library');
      },
      function (err) {
        logMessage('User denied the access: ' + err);
      }
    );
  }, 'request_authorization');

};
