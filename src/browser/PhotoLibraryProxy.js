var browser = require('cordova/platform');

module.exports = {
  getLibrary: function (success, error) {

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
