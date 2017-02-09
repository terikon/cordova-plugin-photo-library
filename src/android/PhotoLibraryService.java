package com.terikon.cordova.photolibrary;

import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;

import org.apache.cordova.CordovaInterface;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PhotoLibraryService {

  // TODO: implement cache
  //int cacheSize = 4 * 1024 * 1024; // 4MB
  //private LruCache<String, byte[]> imageCache = new LruCache<String, byte[]>(cacheSize);

  protected PhotoLibraryService() {
    dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  }

  public static final String PERMISSION_ERROR = "Permission Denial: This application is not allowed to access Photo data.";

  public static PhotoLibraryService getInstance() {
    if (instance == null) {
      synchronized (PhotoLibraryService.class) {
        if (instance == null) {
          instance = new PhotoLibraryService();
        }
      }
    }
    return instance;
  }

  public void getLibrary(Context context, MyRunnable partialCallback, MyRunnable completion) throws JSONException {

    // TODO: make use of partialCallback

    String whereClause = "";
    completion.run(queryLibrary(context, whereClause));

  }

  public PictureData getThumbnail(Context context, String photoId, int thumbnailWidth, int thumbnailHeight, double quality) throws IOException {

    Bitmap bitmap = null;

    String imageURL = getImageURL(photoId);
    File imageFile = new File(imageURL);

    // TODO: maybe it never worth using MediaStore.Images.Thumbnails.getThumbnail, as it returns sizes less than 512x384?
    if (thumbnailWidth == 512 && thumbnailHeight == 384) { // In such case, thumbnail will be cached by MediaStore
      int imageId = getImageId(photoId);
      // For some reason and against documentation, MINI_KIND image can be returned in size different from 512x384, so the image will be scaled later if needed
      bitmap = MediaStore.Images.Thumbnails.getThumbnail(
        context.getContentResolver(),
        imageId ,
        MediaStore.Images.Thumbnails.MINI_KIND,
        (BitmapFactory.Options) null);
    }

    if (bitmap == null) { // No free caching here
      Uri imageUri = Uri.fromFile(imageFile);
      BitmapFactory.Options options = new BitmapFactory.Options();

      options.inJustDecodeBounds = true;
      InputStream is = context.getContentResolver().openInputStream(imageUri);
      BitmapFactory.decodeStream(is, null, options);

      // get bitmap with size of closest power of 2
      options.inSampleSize = calculateInSampleSize(options, thumbnailWidth, thumbnailHeight);
      options.inJustDecodeBounds = false;
      is = context.getContentResolver().openInputStream(imageUri);
      bitmap = BitmapFactory.decodeStream(is, null, options);
      is.close();
    }

    if (bitmap != null) {

      // correct image orientation
      int orientation = getImageOrientation(imageFile);
      Bitmap rotatedBitmap = rotateImage(bitmap, orientation);
      if (bitmap != rotatedBitmap) {
        bitmap.recycle();
      }

      Bitmap thumbnailBitmap = ThumbnailUtils.extractThumbnail(rotatedBitmap, thumbnailWidth, thumbnailHeight);
      if (rotatedBitmap != thumbnailBitmap) {
        rotatedBitmap.recycle();
      }

      // TODO: cache bytes for performance

      byte[] bytes = getJpegBytesFromBitmap(thumbnailBitmap, quality);
      String mimeType = "image/jpeg";

      thumbnailBitmap.recycle();

      return new PictureData(bytes, mimeType);

    }

    return null;

  }

  public PictureAsStream getPhotoAsStream(Context context, String photoId) throws IOException {

    int imageId = getImageId(photoId);
    String imageURL = getImageURL(photoId);
    File imageFile = new File(imageURL);
    Uri imageUri = Uri.fromFile(imageFile);

    String mimeType = queryMimeType(context, imageId);

    InputStream is = context.getContentResolver().openInputStream(imageUri);

    if (mimeType.equals("image/jpeg")) {
      int orientation = getImageOrientation(imageFile);
      if (orientation > 1) { // Image should be rotated

        Bitmap bitmap = BitmapFactory.decodeStream(is, null, null);
        is.close();

        Bitmap rotatedBitmap = rotateImage(bitmap, orientation);

        bitmap.recycle();

        // Here we perform conversion with data loss, but it seems better than handling orientation in JavaScript.
        // Converting to PNG can be an option to prevent data loss, but in price of very large files.
        byte[] bytes = getJpegBytesFromBitmap(rotatedBitmap, 1.0); // minimize data loss with 1.0 quality

        is = new ByteArrayInputStream(bytes);
      }
    }

    return new PictureAsStream(is, mimeType);

  }

  public PictureData getPhoto(Context context, String photoId) throws IOException {

    PictureAsStream pictureAsStream = getPhotoAsStream(context, photoId);

    byte[] bytes =  readBytes(pictureAsStream.getStream());
    pictureAsStream.getStream().close();

    return new PictureData(bytes, pictureAsStream.getMimeType());

  }

  public void saveImage(CordovaInterface cordova, String url, String album) throws IOException, URISyntaxException {

    saveMedia(cordova, url, album, imageMimeToExtension);

    // TODO: call queryLibrary and return libraryItem of what was saved

  }

  public void saveVideo(CordovaInterface cordova, String url, String album) throws IOException, URISyntaxException {

    saveMedia(cordova, url, album, videMimeToExtension);

    // TODO: call queryLibrary and return libraryItem of what was saved

  }

  public class PictureData {

    public PictureData(byte[] bytes, String mimeType) {
      this.bytes = bytes;
      this.mimeType = mimeType;
    }

    public byte[] getBytes() { return this.bytes; }

    public String getMimeType() { return this.mimeType; }

    private byte[] bytes;
    private String mimeType;

  }

  public class PictureAsStream {

    public PictureAsStream(InputStream stream, String mimeType) {
      this.stream = stream;
      this.mimeType = mimeType;
    }

    public InputStream getStream() { return this.stream; }

    public String getMimeType() { return this.mimeType; }

    private InputStream stream;
    private String mimeType;

  }

  private static PhotoLibraryService instance = null;

  private SimpleDateFormat dateFormatter;

  private Pattern dataURLPattern = Pattern.compile("^data:(.+?)/(.+?);base64,");

  private ArrayList<JSONObject> queryContentProvider(Context context, Uri collection, JSONObject columns, String whereClause) throws JSONException {

    final ArrayList<String> columnNames = new ArrayList<String>();
    final ArrayList<String> columnValues = new ArrayList<String>();

    Iterator<String> iteratorFields = columns.keys();

    while (iteratorFields.hasNext()) {
      String column = iteratorFields.next();

      columnNames.add(column);
      columnValues.add("" + columns.getString(column));
    }

    final String sortOrder = MediaStore.Images.Media.DATE_TAKEN;

    final Cursor cursor = context.getContentResolver().query(
      collection,
      columnValues.toArray(new String[columns.length()]),
      whereClause, null, sortOrder);

    final ArrayList<JSONObject> buffer = new ArrayList<JSONObject>();

    if (cursor.moveToFirst()) {
      do {
        JSONObject item = new JSONObject();

        for (String column : columnNames) {
          int columnIndex = cursor.getColumnIndex(columns.get(column).toString());

          if (column.startsWith("int.")) {
            item.put(column.substring(4), cursor.getInt(columnIndex));
            if (column.substring(4).equals("width") && item.getInt("width") == 0) {
              System.err.println("cursor: " + cursor.getInt(columnIndex));
            }
          } else if (column.startsWith("float.")) {
            item.put(column.substring(6), cursor.getFloat(columnIndex));
          } else if (column.startsWith("date.")) {
            long intDate = cursor.getLong(columnIndex);
            Date date = new Date(intDate);
            item.put(column.substring(5), dateFormatter.format(date));
          } else {
            item.put(column, cursor.getString(columnIndex));
          }
        }
        buffer.add(item);
      }
      while (cursor.moveToNext());
    }

    cursor.close();

    return buffer;

  }

  private ArrayList<JSONObject> queryLibrary(Context context, String whereClause) throws JSONException {

    // All columns here: https://developer.android.com/reference/android/provider/MediaStore.Images.ImageColumns.html,
    // https://developer.android.com/reference/android/provider/MediaStore.MediaColumns.html
    JSONObject columns = new JSONObject() {{
      put("int.id", MediaStore.Images.Media._ID);
      put("fileName", MediaStore.Images.ImageColumns.DISPLAY_NAME);
      put("int.width", MediaStore.Images.ImageColumns.WIDTH);
      put("int.height", MediaStore.Images.ImageColumns.HEIGHT);
      put("date.creationDate", MediaStore.Images.ImageColumns.DATE_TAKEN);
      put("float.latitude", MediaStore.Images.ImageColumns.LATITUDE);
      put("float.longitude", MediaStore.Images.ImageColumns.LONGITUDE);
    }};

    final ArrayList<JSONObject> queryResults = queryContentProvider(context, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, whereClause);

    ArrayList<JSONObject> results = new ArrayList<JSONObject>();

    for (JSONObject queryResult : queryResults) {
      if (queryResult.getInt("height") <=0 || queryResult.getInt("width") <= 0) {
        System.err.println(queryResult);
      } else {

        // swap width and height if needed
        try {
          int orientation = getImageOrientation(new File(queryResult.getString("nativeURL")));
          if (isOrientationSwapsDimensions(orientation)) { // swap width and height
            int tempWidth = queryResult.getInt("width");
            queryResult.put("width", queryResult.getInt("height"));
            queryResult.put("height", tempWidth);
          }
        } catch (IOException e) {
          // Do nothing
        }

        // photoId is in format "imageid;imageurl"
        queryResult.put("id",
            queryResult.get("id") + ";" +
            queryResult.get("nativeURL"));

        results.add(queryResult);
      }
    }

    Collections.reverse(results);

    return results;

  }

  private String queryMimeType(Context context, int imageId) {

    Cursor cursor = context.getContentResolver().query(
      MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
      new String[] { MediaStore.Images.ImageColumns.MIME_TYPE },
      MediaStore.MediaColumns._ID + "=?",
      new String[] {Integer.toString(imageId)}, null);

    if (cursor != null && cursor.moveToFirst()) {
      String mimeType = cursor.getString(cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE));
      cursor.close();

      return mimeType;

    }

    cursor.close();
    return null;
  }

  // From https://developer.android.com/training/displaying-bitmaps/load-bitmap.html
  private static int calculateInSampleSize(

    BitmapFactory.Options options, int reqWidth, int reqHeight) {
    // Raw height and width of image
    final int height = options.outHeight;
    final int width = options.outWidth;
    int inSampleSize = 1;

    if (height > reqHeight || width > reqWidth) {

      final int halfHeight = height / 2;
      final int halfWidth = width / 2;

      // Calculate the largest inSampleSize value that is a power of 2 and keeps both
      // height and width larger than the requested height and width.
      while ((halfHeight / inSampleSize) >= reqHeight
        && (halfWidth / inSampleSize) >= reqWidth) {
        inSampleSize *= 2;
      }
    }

    return inSampleSize;

  }

  private static byte[] getJpegBytesFromBitmap(Bitmap bitmap, double quality) {

    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, (int)(quality * 100), stream);

    return stream.toByteArray();

  }

  private static void copyStream(InputStream source, OutputStream target) throws IOException {

    int bufferSize = 1024;
    byte[] buffer = new byte[bufferSize];

    int len;
    while ((len = source.read(buffer)) != -1) {
      target.write(buffer, 0, len);
    }

  }

  private static byte[] readBytes(InputStream inputStream) throws IOException {

    ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();

    int bufferSize = 1024;
    byte[] buffer = new byte[bufferSize];

    int len;
    while ((len = inputStream.read(buffer)) != -1) {
      byteBuffer.write(buffer, 0, len);
    }

    return byteBuffer.toByteArray();

  }

  // photoId is in format "imageid;imageurl;[swap]"
  private static int getImageId(String photoId) {
    return Integer.parseInt(photoId.split(";")[0]);
  }

  // photoId is in format "imageid;imageurl;[swap]"
  private static String getImageURL(String photoId) {
    return photoId.split(";")[1];
  }

  private static int getImageOrientation(File imageFile) throws IOException {

    ExifInterface exif = new ExifInterface(imageFile.getAbsolutePath());
    int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);

    return orientation;

  }

  // see http://www.daveperrett.com/articles/2012/07/28/exif-orientation-handling-is-a-ghetto/
  private static Bitmap rotateImage(Bitmap source, int orientation) {

    Matrix matrix = new Matrix();

    switch (orientation) {
      case ExifInterface.ORIENTATION_NORMAL: // 1
          return source;
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL: // 2
        matrix.setScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_ROTATE_180: // 3
        matrix.setRotate(180);
        break;
      case ExifInterface.ORIENTATION_FLIP_VERTICAL: // 4
        matrix.setRotate(180);
        matrix.postScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_TRANSPOSE: // 5
        matrix.setRotate(90);
        matrix.postScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_ROTATE_90: // 6
        matrix.setRotate(90);
        break;
      case ExifInterface.ORIENTATION_TRANSVERSE: // 7
        matrix.setRotate(-90);
        matrix.postScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_ROTATE_270: // 8
        matrix.setRotate(-90);
        break;
      default:
        return source;
    }

    return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, false);

  }

  // Returns true if orientation rotates image by 90 or 270 degrees.
  private static boolean isOrientationSwapsDimensions(int orientation) {
    return orientation == ExifInterface.ORIENTATION_TRANSPOSE // 5
      || orientation == ExifInterface.ORIENTATION_ROTATE_90 // 6
      || orientation == ExifInterface.ORIENTATION_TRANSVERSE // 7
      || orientation == ExifInterface.ORIENTATION_ROTATE_270; // 8
  }

  private static File makeAlbumInPhotoLibrary(String album) {
    File albumDirectory = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), album);
    if (!albumDirectory.exists()) {
      albumDirectory.mkdirs();
    }
    return albumDirectory;
  }

  private File getImageFileName(File albumDirectory, String extension) {
    Calendar calendar = Calendar.getInstance();
    String dateStr = calendar.get(Calendar.YEAR) +
      "-" + calendar.get(Calendar.MONTH) +
      "-" + calendar.get(Calendar.DAY_OF_MONTH);
    int i = 1;
    File result;
    do {
      String fileName = dateStr + "-" + i + extension;
      i += 1;
      result = new File(albumDirectory, fileName);
    } while (result.exists());
    return result;
  }

  private void addFileToMediaLibrary(CordovaInterface cordova, File file) {
    Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
    Uri contentUri = Uri.fromFile(file);
    mediaScanIntent.setData(contentUri);
    cordova.getActivity().sendBroadcast(mediaScanIntent);
  }

  private Map<String, String> imageMimeToExtension = new HashMap<String, String>(){{
    put("jpeg", ".jpg");
  }};

  private Map<String, String> videMimeToExtension = new HashMap<String, String>(){{
    put("quicktime", ".mov");
    put("ogg", ".ogv");
  }};

  private void saveMedia(CordovaInterface cordova, String url, String album, Map<String, String> mimeToExtension) throws IOException, URISyntaxException {

    File albumDirectory = makeAlbumInPhotoLibrary(album);
    File targetFile;

    if (url.startsWith("data:")) {

      Matcher matcher = dataURLPattern.matcher(url);
      if (!matcher.find()) {
        throw new IllegalArgumentException("The dataURL is in incorrect format");
      }
      String mime = matcher.group(2);
      int dataPos = matcher.end();

      String base64 = url.substring(dataPos); // Use substring and not replace to keep memory footprint small
      byte[] decoded = Base64.decode(base64, Base64.DEFAULT);

      if (decoded == null) {
        throw new IllegalArgumentException("The dataURL could not be decoded");
      }

      String extension = mimeToExtension.get(mime);
      if (extension == null) {
        extension = "." + mime;
      }

      targetFile = getImageFileName(albumDirectory, extension);

      FileOutputStream os = new FileOutputStream(targetFile);

      os.write(decoded);

      os.flush();
      os.close();

    } else {

      String extension = url.contains(".") ? url.substring(url.lastIndexOf(".")) : "";
      targetFile = getImageFileName(albumDirectory, extension);

      InputStream is;
      FileOutputStream os = new FileOutputStream(targetFile);

      if(url.startsWith("file:///android_asset/")) {
        String assetUrl = url.replace("file:///android_asset/", "");
        is = cordova.getActivity().getApplicationContext().getAssets().open(assetUrl);
      } else {
        File sourceFile = new File(new URI(url));
        is = new FileInputStream(sourceFile);
      }

      copyStream(is, os);

      os.flush();
      os.close();
      is.close();

    }

    addFileToMediaLibrary(cordova, targetFile);

  }

  public interface MyRunnable {

    void run(ArrayList<JSONObject> data);

  }

}
