// Include shims for useful javascript functions to work on all devices
cordova.require('cordova-plugin-photo-library-tests.es5shim');
cordova.require('cordova-plugin-photo-library-tests.es6shim');
cordova.require('cordova-plugin-photo-library-tests.es7shim');

var expectedImages = [
    { fileName: 'Landscape_1.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_2.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_3.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_4.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_5.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_6.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_7.jpg', width: 600, height: 450, },
    { fileName: 'Landscape_8.jpg', width: 600, height: 450, },
    { fileName: 'Portrait_1.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_2.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_3.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_4.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_5.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_6.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_7.jpg', width: 450, height: 600, },
    { fileName: 'Portrait_8.jpg', width: 450, height: 600, },
];

exports.defineAutoTests = function () {

  describe('cordova.plugins', function () {

    it('photoLibrary should exist', function () {
      expect(cordova.plugins.photoLibrary).toBeDefined();
    });

    describe('cordova.plugins.photoLibrary', function () {

      var library = null;
      var libraryError = null;

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

      it('should not fail', function () {
        expect(libraryError).toBeNull('getLibrary failed with error: ' + libraryError);
      });

      it('should load library', function () {
        expect(library).not.toBeNull();
      });

      describe('cordova.plugins.photoLibrary.getLibrary', function () {

        it('should return multiple photos', function () {
          expect(library.length).toBeGreaterThan(0);
        });

        expectedImages.forEach(function (expectedImage) {

          describe('test-images/' + expectedImage.fileName, function () {

            beforeEach(function () {
              this.libraryItem = library.find(function (libraryItem) { return libraryItem.fileName === expectedImage.fileName });
            });

            it('should exist', function () {
              expect(this.libraryItem).toBeDefined();
            });

            it('should have not-empty id', function () {
              expect(this.libraryItem.id).toEqual(jasmine.any(String));
              expect(this.libraryItem.id.length).not.toEqual(0);
            });

            it('should have not-empty photoURL', function () {
              expect(this.libraryItem.photoURL).toEqual(jasmine.any(String));
              expect(this.libraryItem.photoURL.length).not.toEqual(0);
            });

            it('should have not-empty thumbnailURL', function () {
              expect(this.libraryItem.thumbnailURL).toEqual(jasmine.any(String));
              expect(this.libraryItem.thumbnailURL.length).not.toEqual(0);
            });

            it('should have right width', function () {
              expect(this.libraryItem.width).toBe(expectedImage.width);
            });

            it('should have right height', function () {
              expect(this.libraryItem.height).toBe(expectedImage.height);
            });

            it('should have creationDate', function () {
              expect(this.libraryItem.creationDate).toEqual(jasmine.any(Date));
              expect(this.libraryItem.creationDate.getFullYear()).toBeGreaterThan(2015);
            });

            it('should have "image/jpeg" mimeType', function () {
              expect(this.libraryItem.mimeType).toBe('image/jpeg');
            });

            it('should have not-empty nativeURL', function () {
              expect(this.libraryItem.nativeURL).toEqual(jasmine.any(String));
              expect(this.libraryItem.nativeURL.length).not.toEqual(0);
            });

          });

        });

        // TODO: test partialCallback

      });

      describe('cordova.plugins.photoLibrary.getThumbnailURL', function () {

        var thumbnailURL = null;
        var getThumbnailURLError = null;

        beforeAll(function (done) {
          cordova.plugins.photoLibrary.getThumbnailURL(
            library[0],
            function (url) {
              thumbnailURL = url;
              done();
            },
            function (err) {
              getThumbnailURLError = err;
              done.fail(err);
            }, {
              thumbnailWidth: 123,
              thumbnailHeight: 234,
              quality: 0.25
            });
        });

        it('should not fail', function () {
          expect(getThumbnailURLError).toBeNull('failed with error: ' + getThumbnailURLError);
        });

        it('should return non-empty url', function () {
          expect(thumbnailURL).toEqual(jasmine.any(String));
          expect(thumbnailURL.length).not.toEqual(0);
        });

        it('thumbnailURL should contain requested width', function () {
          expect(thumbnailURL).toContain('width=123');
        });

        it('thumbnailURL should contain requested height', function () {
          expect(thumbnailURL).toContain('height=234');
        });

        it('thumbnailURL should contain requested quality', function () {
          expect(thumbnailURL).toContain('quality=0.25');
        });

      });

      describe('cordova.plugins.photoLibrary.getPhotoURL', function () {

        var photoURL = null;
        var getPhotoURLError = null;

        beforeAll(function (done) {
          cordova.plugins.photoLibrary.getPhotoURL(
            library[0],
            function (url) {
              photoURL = url;
              done();
            },
            function (err) {
              getPhotoURLError = err;
              done.fail(err);
            });
        });

        it('should not fail', function () {
          expect(getPhotoURLError).toBeNull('failed with error: ' + getPhotoURLError);
        });

        it('should return non-empty url', function () {
          expect(photoURL).toEqual(jasmine.any(String));
          expect(photoURL.length).not.toEqual(0);
        });

      });

      describe('cordova.plugins.photoLibrary.getThumbnail', function () {

        var thumbnailBlob = null;
        var getThumbnailError = null;

        beforeAll(function (done) {
          cordova.plugins.photoLibrary.getThumbnail(
            library[0].id,
            function (blob) {
              thumbnailBlob = blob;
              done();
            },
            function (err) {
              getThumbnailError = err;
              done.fail(err);
            }, {
              thumbnailWidth: 123,
              thumbnailHeight: 234,
              quality: 0.25
            });
        });

        it('should not fail', function () {
          expect(getThumbnailError).toBeNull('failed with error: ' + getThumbnailError);
        });

        it('should return non-empty blob', function () {
          expect(thumbnailBlob).toEqual(jasmine.any(Blob));
          expect(thumbnailBlob.size).not.toEqual(0);
        });

        describe('thumbnailBlob', function () {

          var imageObj;

          beforeAll(function (done) {
            imageObj = new Image();
            imageObj.onload = function () {
              done();
            };
            var dataURL = URL.createObjectURL(thumbnailBlob);
            imageObj.src = dataURL;
          });

          it('width should be as requested', function () {
            expect(imageObj.width).toBe(123);
          });

          it('height should be as requested', function () {
            expect(imageObj.height).toBe(234);
          });

        });

      });

      describe('cordova.plugins.photoLibrary.getPhoto', function () {

        var photoBlob = null;
        var getPhotoError = null;

        beforeAll(function (done) {
          cordova.plugins.photoLibrary.getPhoto(
            library[0],
            function (blob) {
              photoBlob = blob;
              done();
            },
            function (err) {
              getPhotoError = err;
              done.fail(err);
            });
        });

        it('should not fail', function () {
          expect(getPhotoError).toBeNull('failed with error: ' + getPhotoError);
        });

        it('should return non-empty blob', function () {
          expect(photoBlob).toEqual(jasmine.any(Blob));
          expect(photoBlob.size).not.toEqual(0);
        });

      });

      describe('cordova.plugins.photoLibrary.requestAuthorization', function () {

        it('should be defined', function () {
          expect(cordova.plugins.photoLibrary.requestAuthorization).toEqual(jasmine.any(Function));
        });

        // Use manual tests to check it working

      });

      describe('cordova.plugins.photoLibrary.saveImage', function () {

        it('should be defined', function () {
          expect(cordova.plugins.photoLibrary.saveImage).toEqual(jasmine.any(Function));
        });

        // TODO: add more tests

      });

      describe('cordova.plugins.photoLibrary.saveVideo', function () {

        it('should be defined', function () {
          expect(cordova.plugins.photoLibrary.saveVideo).toEqual(jasmine.any(Function));
        });

        // TODO: add more tests

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
    'Expected result: All the images should be rotated right way' +
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
        library.forEach(function (libraryItem) {
          if (expectedImages.some(function (expectedImage) { return expectedImage.fileName === libraryItem.fileName; })) {
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
        library.forEach(function (libraryItem) {
          if (expectedImages.some(function (expectedImage) { return expectedImage.fileName === libraryItem.fileName; })) {
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
