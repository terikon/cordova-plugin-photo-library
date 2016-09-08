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
      resolve({ file: file, dataURL: e.target.result });
    };
    reader.readAsDataURL(file);
  });
}

function files2Library(files) {
  return new Promise((resolve, reject) => {

    let fileURLPromises = files.map(f => readFileAsDataURL(f));

    Promise.all(fileURLPromises)
      .then(filesWithDataURL => {
        let result = filesWithDataURL.map(fileWithURL => {

          let {file} = fileWithURL;
          let {dataURL} = fileWithURL;

          let libraryItem = {
            id: `${counter}#${file.name}`,
            filename: file.name,
            nativeURL: dataURL,
            width: '',
            height: '',
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
      library = files2Library(files);
      removeFilesElement(filesElement);
      success(library);

    }, false);

  },
  getThumbnail: function (success, error) {

  },
  getPhoto: function (success, error) {

  },
  stopCaching: function (success, error) {

  },
  echo: function (success, error) {

  },
};

require('cordova/exec/proxy').add('PhotoLibrary', module.exports);
