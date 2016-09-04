Parts are based on

- https://github.com/ryouaki/Cordova-Plugin-Photos
- https://github.com/subitolabs/cordova-gallery-api 

TODO:

- check why cordova-plugin-file returns error for file:///var/.../DCIM folder
- use PHCachingImageManager to faster load images
- maybe use messageAsArrayBuffer of CDVPluginResult, and load img from blob:

    var blob = new Blob( [ arrayBufferView ], { type: "image/jpeg" } );
    var urlCreator = window.URL || window.webkitURL;
    var imageUrl = urlCreator.createObjectURL( blob );
    img.src = imageUrl;
