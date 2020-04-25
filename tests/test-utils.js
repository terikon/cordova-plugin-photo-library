exports.resolveLocalFileSystemURL = function  (fileSystem) {

  return new Promise(function (resolve, reject) {

    window.resolveLocalFileSystemURL(fileSystem, resolve, reject);

  });

};

exports.createFile = function (dirEntry, fileName) {

  return new Promise(function (resolve, reject) {

    dirEntry.getFile(fileName, {create: true, exclusive: false}, resolve, reject);

  });

};

exports.writeFile = function (fileEntry, dataObj) {

  return new Promise(function (resolve, reject) {

    fileEntry.createWriter(function (fileWriter) {

      fileWriter.onwriteend = function () { resolve (fileEntry); };
      fileWriter.onerror = reject;

      fileWriter.write(dataObj);

    });

  });

};
