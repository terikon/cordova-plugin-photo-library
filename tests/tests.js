// Include shims for useful javascript functions to work on all devices
cordova.require('cordova-plugin-photo-library-tests.es5shim');
cordova.require('cordova-plugin-photo-library-tests.es6shim');
cordova.require('cordova-plugin-photo-library-tests.es7shim');

var testImages = [
  'Landscape_1.jpg',
  'Landscape_2.jpg',
  'Landscape_3.jpg',
  'Landscape_4.jpg',
  'Landscape_5.jpg',
  'Landscape_6.jpg',
  'Landscape_7.jpg',
  'Landscape_8.jpg',
  'Portrait_1.jpg',
  'Portrait_2.jpg',
  'Portrait_3.jpg',
  'Portrait_4.jpg',
  'Portrait_5.jpg',
  'Portrait_6.jpg',
  'Portrait_7.jpg',
  'Portrait_8.jpg',
];

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
    'Expected result: If authorized, this fact will be logged. On iOS: settings page will open. On Android: confirmation prompt will open.' +
    '<h3>Press the button to visually inspect test-images</h3>' +
    '<div id="inspect_test_images"></div>' +
    'Expected result: All the images should be rotated right way'+
    '<h3>Press the button to visually inspect thumbnails of test-images</h3>' +
    '<div id="inspect_thumbnail_test_images"></div>' +
    'Expected result: All the images should be rotated right way';

  contentEl.innerHTML = '<div id="info" style="overflow:scroll; width:100%; height:400px;"></div>' + photo_library_tests;

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

  createActionButton('inspect test images', function () {
    clearLog();
    cordova.plugins.photoLibrary.getLibrary(
      function (library) {
        var found = 0;
        library.forEach(function(libraryItem) {
          if (testImages.includes(libraryItem.filename)) {
            found += 1;
            logMessage('<img src="' + libraryItem.photoURL + '" width="256">');
          }
        });
        if (found < testImages.length) {
          logMessage('Some test-images are missing. Please put photos from test-images folder to device library.')
        }
      },
      function (err) {
        logMessage('Error occured in getLibrary: ' + err);
      }
    );
  }, 'inspect_test_images');

  createActionButton('inspect thumbnail test images', function () {
    clearLog();
    cordova.plugins.photoLibrary.getLibrary(
      function (library) {
        var found = 0;
        library.forEach(function(libraryItem) {
          if (testImages.includes(libraryItem.filename)) {
            found += 1;
            logMessage('<img src="' + libraryItem.thumbnailURL + '" width="256">');
          }
        });
        if (found < testImages.length) {
          logMessage('Some test-images are missing. Please put photos from test-images folder to device library.')
        }
      },
      function (err) {
        logMessage('Error occured in getLibrary: ' + err);
      },
      {
        thumbnailWidth: 256,
        thumbnailHeight: 256,
      }
    );
  }, 'inspect_thumbnail_test_images');

};
