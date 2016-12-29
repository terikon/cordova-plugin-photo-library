exports.defineAutoTests = function () {

  describe('Device Information (window.device)', function () {
    it("should exist", function () {
      expect(window.device).toBeDefined();
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

  var device_tests = '<h3>Press Dump Device button to get device information</h3>' +
    '<div id="dump_device"></div>' +
    'Expected result: Status box will get updated with device info. (i.e. platform, version, uuid, model, etc)';

  contentEl.innerHTML = '<div id="info"></div>' + device_tests;

  createActionButton('Dump device', function () {
    clearLog();
    //logMessage(JSON.stringify(window.device, null, '\t'));
    logMessage('Test result can be here...');
  }, 'dump_device');

};
