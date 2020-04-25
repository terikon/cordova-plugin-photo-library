// Tests should be written on JavaScript version that supported on both iOS and Android WebView (no lambdas).
// But functionality provided by esshims can be used :)

// Include shims for useful javascript functions to work on all devices
cordova.require('cordova-plugin-photo-library-tests.es5-shim');
cordova.require('cordova-plugin-photo-library-tests.es6-shim');
cordova.require('cordova-plugin-photo-library-tests.es7-shim');
cordova.require('cordova-plugin-photo-library-tests.blueimp-canvastoblob');

var testUtils = cordova.require('cordova-plugin-photo-library-tests.test-utils');

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

  // Configure jasmine
  var jasmineEnv = jasmine.getEnv();
  jasmineEnv.catchExceptions(true); // without this, syntax error will hang a test, instead of reporting it failed

  describe('cordova.plugins', function () {

    it('photoLibrary should exist', function () {
      expect(cordova.plugins.photoLibrary).toBeDefined();
    });

    describe('cordova.plugins.photoLibrary', function () {

      var library = null;
      var libraryError = null;
      var getLibraryResultCalledTimes = 0;
      var getLibraryIsLastChunk = null;

      beforeAll(function (done) {
        cordova.plugins.photoLibrary.getLibrary(function (result) {
          library = result.library;
          getLibraryResultCalledTimes += 1;
          getLibraryIsLastChunk = result.isLastChunk;
          done();
        },
        function (err) {
          libraryError = err;
          done.fail(err);
        },
          {
            useOriginalFileNames: true, // We want to compare file names in test
            includeAlbumData: true, // We want to check albums
          });
      }, 20000); // In browser platform, gives a time to select photos.

      it('should not fail', function () {
        expect(libraryError).toBeNull('getLibrary failed with error: ' + libraryError);
      });

      it('should load library', function () {
        expect(library).not.toBeNull();
      });

      it('result callback should be executed exactly once', function () {
        expect(getLibraryResultCalledTimes).toEqual(1);
      });

      it('result callback should be treated as last chunk', function () {
        expect(getLibraryIsLastChunk).toBeTruthy();
      });

      describe('cordova.plugins.photoLibrary.getAlbums', function () {

        var albums = null;
        var getAlbumsError = null;

        beforeAll(function (done) {
          cordova.plugins.photoLibrary.getAlbums(function (albs) {
            albums = albs;
            done();
          },
          function (err) {
            getAlbumsError = err;
            done.fail(err);
          });
        });

        it('should not fail', function() {
          expect(getAlbumsError).toBeNull('getAlbums failed with error: ' + getAlbumsError);
        });

        it('should return an array', function() {
          expect(albums).toEqual(jasmine.any(Array));
        });

        it('shoud return at least one album', function() {
          expect(albums.length).toBeGreaterThan(0);
        });

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

            it('should have albumIds array', function() {
              expect(this.libraryItem.albumIds).toEqual(jasmine.any(Array));
            });

            it('albumIds array should contain at least one album', function() {
              expect(this.libraryItem.albumIds.length).toBeGreaterThan(0);
            });

          });

        });

        describe('geotagged image', function() {

          beforeEach(function () {
            this.libraryItem = library.find(function (libraryItem) { return libraryItem.fileName === 'geotagged.jpg'; });
          });

          it('should have correct latitude', function() {
            expect(this.libraryItem.latitude).toBeCloseTo(32.517078, 5); // 32' 31'' 1.482'''
          });

          it('should have correct longitude', function() {
            expect(this.libraryItem.longitude).toBeCloseTo(34.955096, 5); // 34' 57'' 18.348'''
          });

        });

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

      var chunkOptionsArray = [{itemsInChunk: 1, chunkTimeSec: 0}, {itemsInChunk: 0, chunkTimeSec: 0.000000001}];

      chunkOptionsArray.forEach(function (chunkOptions) {

        describe('chunked output by ' + (chunkOptions.itemsInChunk > 0? 'itemsInChunk' : 'chunkTimeSec'), function () {
          var libraryChunks = [];
          var chunkedError = null;

          beforeAll(function (done) {
            cordova.plugins.photoLibrary.getLibrary(function (result) {
              libraryChunks.push(result.library);
              if (result.isLastChunk) {
                done();
              }
            },
            function (err) {
              chunkedError = err;
              done.fail(err);
            },
              {
                itemsInChunk: chunkOptions.itemsInChunk,
                chunkTimeSec: chunkOptions.chunkTimeSec,
                useOriginalFileNames: true,
              });
          }, 20000); // In browser platform, gives a time to select photos.

          it('should not fail', function () {
            expect(chunkedError).toBeNull('chunked getLibrary failed with error: ' + chunkedError);
          });

          if (chunkOptions.itemsInChunk > 0) {
            it('should return correct number of chunks', function () {
              expect(libraryChunks.length).toEqual(library.length);
            });
          }

          if (chunkOptions.chunkTimeSec > 0) {
            it('should return multiple chunks', function () {
              expect(libraryChunks.length).toBeGreaterThan(0);
            });
          }

          it('should return same photos in chunks as without chunks', function () {
            var unchunkedNames = library.map(function(item) { return item.id; });
            var flattenedChunks = [].concat.apply([], libraryChunks);
            var chunkedNames = flattenedChunks.map(function(item) { return item.id; });
            expect(chunkedNames).toEqual(unchunkedNames);
          });

        });

      });

    });

    describe('cordova.plugins.photoLibrary.saveImage', function () {

      it('should be defined', function () {
        expect(cordova.plugins.photoLibrary.saveImage).toEqual(jasmine.any(Function));
      });

      describe('saving image as dataURL', function() {

        var saveImageLibraryItem = null;
        var saveImageError = null;

        beforeAll(function(done) {
          var canvas = document.createElement('canvas');
          canvas.width = 150;
          canvas.height = 150;
          var ctx = canvas.getContext('2d');
          ctx.fillRect(25, 25, 100, 100);
          ctx.clearRect(45, 45, 60, 60);
          ctx.strokeRect(50, 50, 50, 50);
          var dataURL = canvas.toDataURL('image/jpg');

          cordova.plugins.photoLibrary.saveImage(dataURL, 'PhotoLibraryTests',
            function(libraryItem) {
              saveImageLibraryItem = libraryItem;
              done();
            },
            function(err) {
              saveImageError = err;
              done.fail(err);
            });
        });

        it('should not fail', function() {
          expect(saveImageError).toBeNull('failed with error: ' + saveImageError);
        });

        it('should return valid library item', function() {
          expect(saveImageLibraryItem).not.toBeNull();
          expect(saveImageLibraryItem.id).toBeDefined();
        });

      });

      describe('saving image from local URL', function() {

        var saveImageLibraryItem = null;
        var saveImageError = null;

        beforeAll(function(done) {
          var canvas = document.createElement('canvas');
          canvas.width = 150;
          canvas.height = 150;
          var ctx = canvas.getContext('2d');
          ctx.fillRect(25, 25, 100, 100);
          ctx.clearRect(45, 45, 60, 60);
          ctx.strokeStyle = '#87CEEB'; // Sky blue
          ctx.strokeRect(50, 50, 50, 50);

          testUtils.resolveLocalFileSystemURL(cordova.file.cacheDirectory)
          .then(function (dirEntry) {

            return testUtils.createFile(dirEntry, 'test-image.jpg');

          })
          .then(function (fileEntry) {

            return new Promise(function (resolve, reject) {
              canvas.toBlob(function(blob) {
                resolve({fileEntry: fileEntry, blob: blob});
              }, 'image/jpeg');
            });

          })
          .then(function (result) {

            var fileEntry = result.fileEntry;
            var blob = result.blob;
            return testUtils.writeFile(fileEntry, blob);

          })
          .then(function(fileEntry) {

            var localURL = fileEntry.toURL();
            return new Promise(function (resolve, reject) {
              cordova.plugins.photoLibrary.saveImage(localURL, 'PhotoLibraryTests',
              function(libraryItem) {
                saveImageLibraryItem = libraryItem;
                resolve();
              },
              function(err) {
                saveImageError = err;
                reject(err);
              });
            });

          })
          .then(done)
          .catch(function (err) { done.fail(err); });
        });

        it('should not fail', function() {
          expect(saveImageError).toBeNull('failed with error: ' + saveImageError);
        });

        it('should return valid library item', function() {
          expect(saveImageLibraryItem).not.toBeNull();
          expect(saveImageLibraryItem.id).toBeDefined();
        });

      });

      describe('saving image from remote URL', function() {

        var saveImageLibraryItem = null;
        var saveImageError = null;

        beforeAll(function(done) {
          var remoteURL = 'http://openphoto.net/volumes/nmarchildon/20041218/opl_imgp0196.jpg';

          cordova.plugins.photoLibrary.saveImage(remoteURL, 'PhotoLibraryTests',
            function(libraryItem) {
              saveImageLibraryItem = libraryItem;
              done();
            },
            function(err) {
              saveImageError = err;
              done.fail(err);
            });
        });

        it('should not fail', function() {
          expect(saveImageError).toBeNull('failed with error: ' + saveImageError);
        });

        it('should return valid library item', function() {
          expect(saveImageLibraryItem).not.toBeNull();
          expect(saveImageLibraryItem.id).toBeDefined();
        });

      });

    });

    describe('cordova.plugins.photoLibrary.saveVideo', function () {

      it('should be defined', function () {
        expect(cordova.plugins.photoLibrary.saveVideo).toEqual(jasmine.any(Function));
      });

      // TODO: add more tests

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
    'Expected result: All the images should be rotated right way' +

    '<h3>Press the button to measure speed of getLibrary</h3>' +
    '<div id="measure_get_library_speed"></div>' +
    'Expected result: Time per image should be adequate' +

    '<h3>Press the button to display albums</h3>' +
    '<div id="display_albums"></div>' +
    'Expected result: Should return all the albums'
    ;

  contentEl.innerHTML = '<div id="info" style="width:100%; max-height:none;"></div>' + photo_library_tests;

  createActionButton('requestAuthorization', function () {
    clearLog();
    cordova.plugins.photoLibrary.requestAuthorization(
      function () {
        logMessage('User gave us permission to his library');
      },
      function (err) {
        logMessage('User denied the access: ' + err);
      },
      {
        read: true,
        write: true // Needed for saveImage tests
      }
    );
  }, 'request_authorization');

  createActionButton('inspect test images', function () {
    clearLog();
    cordova.plugins.photoLibrary.getLibrary(
      function (result) {
        var found = 0;
        result.library.forEach(function (libraryItem) {
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
      },
      {
        useOriginalFileNames: true,
      }
    );
  }, 'inspect_test_images');

  createActionButton('inspect thumbnail test images', function () {
    clearLog();
    cordova.plugins.photoLibrary.getLibrary(
      function (result) {
        var found = 0;
        result.library.forEach(function (libraryItem) {
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
        useOriginalFileNames: true,
      }
    );
  }, 'inspect_thumbnail_test_images');

  createActionButton('measure', function () {
    clearLog();
    logMessage('measuring, please wait...');
    var start = performance.now();
    cordova.plugins.photoLibrary.getLibrary(
      function (result) {
        var library = result.library;
        var end = performance.now();
        var elapsedMs = end - start;
        logMessage('getLibrary returned ' + library.length + ' items.');
        logMessage('it took ' + Math.round(elapsedMs) + ' ms.');
        logMessage('time per photo is ' + Math.round(elapsedMs / library.length) + ' ms.');
      },
      function (err) {
        logMessage('Error occured in getLibrary: ' + err);
      }
    );
  }, 'measure_get_library_speed');

  createActionButton('display albums', function () {
    clearLog();
    cordova.plugins.photoLibrary.getAlbums(
      function (albums) {
        albums.forEach(function(album) {
          logMessage(JSON.stringify(album));
        });
      },
      function (err) {
        logMessage('Error occured in getAlbums: ' + err);
      }
    );
  }, 'display_albums');

};
