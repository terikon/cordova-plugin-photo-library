const HIGHEST_POSSIBLE_Z_INDEX = 2147483647;

var library = [];

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
  let files = filesElement.files; // FileList object
  return files.filter(f => f.type.match('image.*'));
}

function files2Library(files) {

}

module.exports = {
  getLibrary: function (success, error) {

    checkSupported();

    var filesElement = createFilesElement();
    filesElement.addEventListener('change', (evt) => {

      getFiles(evt.target)
        .then((files) => {
          library = files2Library(files);
          removeFilesElement(filesElement);
          success(library);
        });

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
