// Include shims for useful javascript functions to work on all devices
cordova.require('cordova-plugin-photo-library-tests.es5shim');
cordova.require('cordova-plugin-photo-library-tests.es6shim');
cordova.require('cordova-plugin-photo-library-tests.es7shim');

var expectedImages = [
    { filename: 'Landscape_1.jpg', width: 600, height: 450, },
    { filename: 'Landscape_2.jpg', width: 600, height: 450, },
    { filename: 'Landscape_3.jpg', width: 600, height: 450, },
    { filename: 'Landscape_4.jpg', width: 600, height: 450, },
    { filename: 'Landscape_5.jpg', width: 600, height: 450, },
    { filename: 'Landscape_6.jpg', width: 600, height: 450, },
    { filename: 'Landscape_7.jpg', width: 600, height: 450, },
    { filename: 'Landscape_8.jpg', width: 600, height: 450, },
    { filename: 'Portrait_1.jpg', width: 450, height: 600, },
    { filename: 'Portrait_2.jpg', width: 450, height: 600, },
    { filename: 'Portrait_3.jpg', width: 450, height: 600, },
    { filename: 'Portrait_4.jpg', width: 450, height: 600, },
    { filename: 'Portrait_5.jpg', width: 450, height: 600, },
    { filename: 'Portrait_6.jpg', width: 450, height: 600, },
    { filename: 'Portrait_7.jpg', width: 450, height: 600, },
    { filename: 'Portrait_8.jpg', width: 450, height: 600, },
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

        expectedImages.forEach(function(expectedImage) {

            describe('test-images/' + expectedImage.filename, function() {

                beforeEach(function() {
                    this.libraryItem = library.find(function(libraryItem) { return libraryItem.filename === expectedImage.filename });
                });

                it('should exist', function() {
                    expect(this.libraryItem).toBeDefined();
                });

                it('should have not-empty id', function () {
                    expect(this.libraryItem.id).toEqual(jasmine.any(String));
                    expect(this.libraryItem.id.length).not.toEqual(0);
                });

                it('should have not-empty nativeURL', function () {
                    expect(this.libraryItem.nativeURL).toEqual(jasmine.any(String));
                    expect(this.libraryItem.nativeURL.length).not.toEqual(0);
                });

                it('should have right width', function () {
                    expect(this.libraryItem.width).toBe(expectedImage.width);
                });

                it('should have right height', function () {
                    expect(this.libraryItem.height).toBe(expectedImage.height);
                });

                it('should have size greater than 0', function () {
                    expect(this.libraryItem.size).toEqual(jasmine.any(Number));
                    expect(this.libraryItem.size).toBeGreaterThan(0);
                });

                it('should have "image/jpeg" mimetype', function () {
                    expect(this.libraryItem.mimetype).toBe('image/jpeg');
                });

            });

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

  contentEl.innerHTML = '<div id="info" style="width:100%; max-height:none;"></div>' + photo_library_tests;

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
          if (expectedImages.some(function(expectedImage) { return expectedImage.filename === libraryItem.filename; })) {
            found += 1;
            logMessage('<img src="' + libraryItem.photoURL + '" width="256">');
          }
        });
        if (found < expectedImages.length) {
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
          if (expectedImages.some(function(expectedImage) { return expectedImage.filename === libraryItem.filename; })) {
            found += 1;
            logMessage('<img src="' + libraryItem.thumbnailURL + '" width="256">');
          }
        });
        if (found < expectedImages.length) {
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
