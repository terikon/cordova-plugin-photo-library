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

          let {file} = fileWithData;
          let {dataURL} = fileWithData;

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

module.exports = {
  getLibrary: function (success, error) {

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
  getThumbnail: function (success, error) {
    console.log('getThumbnail');
  },
  getPhoto: function (success, error) {

  },
  stopCaching: function (success, error) {

  },
  echo: function (success, error) {

  },
};

require('cordova/exec/proxy').add('PhotoLibrary', module.exports);
