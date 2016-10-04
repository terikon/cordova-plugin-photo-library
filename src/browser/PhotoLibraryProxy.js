module.exports = {

  getLibrary: function (success, error, [options]) {

    checkSupported();

    let filesElement = createFilesElement();

    filesElement.addEventListener('change', (evt) => {

      let files = getFiles(evt.target);
      files2Library(files).then(lib => {
        library = lib;
        removeFilesElement(filesElement);
        success(library);
      });

    }, false);

  },

  getThumbnail: function (success, error, [photoId, options]) {

    let libraryItem = library.find(li => li.id === photoId);
    if (!libraryItem) {
      error(`Photo with id ${photoId} not found in the library`);
      return;
    }

    let {thumbnailWidth, thumbnailHeight, quality} = options;

    readDataUrlAsImage(libraryItem.nativeURL).then(image => {
      let canvas = document.createElement('canvas');
      let context = canvas.getContext('2d');
      canvas.width = thumbnailWidth;
      canvas.height = thumbnailHeight;
      context.drawImage(image, 0, 0, thumbnailWidth, thumbnailHeight);
      canvas.toBlob((blob) => {
        success(blob);
      }, 'image/jpeg', quality);
    });

  },

  getPhoto: function (success, error, [photoId, options]) {

    let libraryItem = library.find(li => li.id === photoId);
    if (!libraryItem) {
      error(`Photo with id ${photoId} not found in the library`);
      return;
    }

    let blob = dataURLToBlob(libraryItem.nativeURL);
    success(blob);

  },

  stopCaching: function (success, error) {
    // Nothing to do
  },

};

require('cordova/exec/proxy').add('PhotoLibrary', module.exports);

const HIGHEST_POSSIBLE_Z_INDEX = 2147483647;

var library = [];
var counter = 0;

function checkSupported() {
  // Check for the various File API support.
  if (!(window.File && window.FileReader && window.FileList && window.Blob)) {
    throw ('The File APIs are not fully supported in this browser.');
  }
}

function createFilesElement() {
  var filesElement = document.createElement('input');
  filesElement.type = 'file';
  filesElement.name = 'files[]';
  filesElement.multiple = true;
  filesElement.style.zIndex = HIGHEST_POSSIBLE_Z_INDEX;
  filesElement.style.position = 'relative';
  filesElement.className = 'cordova-photo-library-select';
  document.body.appendChild(filesElement);
  return filesElement;
}

function removeFilesElement(filesElement) {
  filesElement.parentNode.removeChild(filesElement);
}

function getFiles(filesElement) {
  //convert from array-like to real array
  let files = Array.from(filesElement.files); // FileList object
  return files.filter(f => f.type.match('image.*'));
}

function readFileAsDataURL(file) {
  return new Promise((resolve, reject) => {
    let reader = new FileReader();
    reader.onload = (e) => {
      resolve(e.target.result);
    };
    reader.readAsDataURL(file);
  });
}

function readDataUrlAsImage(dataURL) {
  return new Promise((resolve, reject) => {
    var imageObj = new Image();
    imageObj.onload = () => {
      resolve(imageObj);
    };
    imageObj.src = dataURL;
  });
}

function files2Library(files) {
  return new Promise((resolve, reject) => {

    let filesWithDataPromises = files.map(f => {
      return new Promise((resolve, reject) => {
        readFileAsDataURL(f)
          .then(dataURL => {
            return readDataUrlAsImage(dataURL).then(image => {
              return { dataURL, image };
            });
          })
          .then(dataURLwithImage => {
            let {image} = dataURLwithImage;
            resolve({
              file: f,
              dataURL: dataURLwithImage.dataURL,
              width: image.width,
              height: image.height
            });
          });
      });
    });

    Promise.all(filesWithDataPromises)
      .then(filesWithData => {
        let result = filesWithData.map(fileWithData => {

          let {file, dataURL} = fileWithData;

          let libraryItem = {
            id: `${counter}#${file.name}`,
            filename: file.name,
            nativeURL: dataURL,
            width: fileWithData.width,
            height: fileWithData.height,
            creationDate: file.lastModifiedDate, // file contains only lastModifiedDate
          };
          counter += 1;
          return libraryItem;

        });

        resolve(result);

      });

  });
}

// From here: https://gist.github.com/davoclavo/4424731
function dataURLToBlob(dataURL) {
  // convert base64 to raw binary data held in a string
  var byteString = atob(dataURL.split(',')[1]);

  // separate out the mime component
  var mimeString = dataURL.split(',')[0].split(':')[1].split(';')[0];

  // write the bytes of the string to an ArrayBuffer
  var arrayBuffer = new ArrayBuffer(byteString.length);
  var _ia = new Uint8Array(arrayBuffer);
  for (var i = 0; i < byteString.length; i++) {
    _ia[i] = byteString.charCodeAt(i);
  }

  var dataView = new DataView(arrayBuffer);
  var blob = new Blob([dataView], { type: mimeString });
  return blob;
}
