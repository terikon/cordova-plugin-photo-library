// TODO: make it real test

import { PhotoLibrary, LibraryItem } from 'ionic-native';

class Test {

  test () {

    PhotoLibrary.requestAuthorization({ read: true, write: true })
      .then(() => {
        console.log('permission granted');
        return this.getLibrary();
      })
      .then((library: LibraryItem[]) => {
        return this.getThumbnailURL(library[0]).then(() => library);
      })
      .then((library: LibraryItem[]) => {
        return this.getPhotoURL(library[0]).then(() => library);
      })
      .then((library: LibraryItem[]) => {
        return this.getThumbnail(library[0]).then(() => library);
      })
      .then((library: LibraryItem[]) => {
        return this.getPhoto(library[0]).then(() => library);
      })
      .then(() => {
        return this.getAlbums();
      })
      .then(() => {
        return this.saveImage();
      })
      .catch(err => {
        console.log(err);
      });

  }

  getLibrary() {
    return new Promise((resolve, reject) => {
      let library = [];
      PhotoLibrary.getLibrary({ itemsInChunk: 1000 }).subscribe({
        next: chunk => {
          console.log(`chunk arrived: ${chunk.length}`);
          library = library.concat(chunk);
        }, error: err => {
          console.log('getLibrary error: ' + err);
          reject(err);
        }, complete: () => {
          console.log(`completed: ${library.length}`);
          resolve(library);
        }
      });
    });
  }

  getAlbums() {
    return PhotoLibrary.getAlbums().then(albums => {
      albums.forEach(album => console.log(JSON.stringify(album)));
    });
  }

  getThumbnailURL(libraryItem: LibraryItem) {
    return PhotoLibrary.getThumbnailURL(libraryItem).then(url => console.log(url));
  }

  getPhotoURL(libraryItem: LibraryItem) {
    return PhotoLibrary.getPhotoURL(libraryItem).then(url => console.log(url));
  }

  getThumbnail(libraryItem: LibraryItem) {
    return PhotoLibrary.getThumbnail(libraryItem).then(url => console.log(url));
  }

  getPhoto(libraryItem: LibraryItem) {
    return PhotoLibrary.getPhoto(libraryItem).then(url => console.log(url));
  }

  saveImage() {
    var canvas = document.createElement('canvas');
    canvas.width = 150;
    canvas.height = 150;
    var ctx = canvas.getContext('2d');
    ctx.fillRect(25, 25, 100, 100);
    ctx.clearRect(45, 45, 60, 60);
    ctx.strokeRect(50, 50, 50, 50);
    var dataURL = canvas.toDataURL('image/jpg');

    return PhotoLibrary.saveImage(dataURL, 'ionic-native').then(libraryItem => console.log(JSON.stringify(libraryItem)));
  }

}
