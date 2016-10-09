package com.terikon.cordova.photolibrary;

import android.provider.MediaStore;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.Date;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PhotoLibrary extends CordovaPlugin {

  public static final String THUMBNAIL_PROTOCOL = "cdvthumbnail";

  public static final String ACTION_GET_LIBRARY = "getLibrary";
  public static final String ACTION_GET_THUMBNAIL= "getThumbnail";
  public static final String ACTION_GET_PHOTO = "getPhoto";
  public static final String ACTION_STOP_CACHING = "stopCaching";

  // TODO: implement cache
  //int cacheSize = 4 * 1024 * 1024; // 4MB
  //private LruCache<String, byte[]> imageCache = new LruCache<String, byte[]>(cacheSize);

  @Override
  protected void pluginInitialize() {
    super.pluginInitialize();
    // initialization
    dateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm a z");
  }

  @Override
  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    try {

      if (ACTION_GET_LIBRARY.equals(action)) {

        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              ArrayList<JSONObject> library = getLibrary();
              callbackContext.success(new JSONArray(library));
            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      } else if (ACTION_GET_THUMBNAIL.equals(action)) {

        final String photoId = args.getString(0);
        final JSONObject options = args.optJSONObject(1);
        final int thumbnailWidth = options.getInt("thumbnailWidth");
        final int thumbnailHeight = options.getInt("thumbnailHeight");
        final double quality = options.getDouble("quality");

        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              PictureData thumbnail = getThumbnail(photoId, thumbnailWidth, thumbnailHeight, quality);
              callbackContext.sendPluginResult(createPluginResult(PluginResult.Status.OK, thumbnail));
            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      } else if (ACTION_GET_PHOTO.equals(action)) {

        final String photoId = args.getString(0);

        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              PictureData thumbnail = getPhoto(photoId);
              callbackContext.sendPluginResult(createPluginResult(PluginResult.Status.OK, thumbnail));
            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      } else if (ACTION_STOP_CACHING.equals(action)) {

        // Nothing to do - it's ios only functionality
        callbackContext.success();
        return true;

      }

      return false;

    } catch(Exception e) {
      e.printStackTrace();
      callbackContext.error(e.getMessage());
      return false;
    }
  }

  @Override
  public Uri remapUri(Uri uri) {
    if (!THUMBNAIL_PROTOCOL.equals(uri.getScheme())) {
      return null;
    }
    return toPluginUri(uri);
  }

  @Override
  public CordovaResourceApi.OpenForReadResult handleOpenForRead(Uri uri) throws IOException {
    Uri origUri = fromPluginUri(uri);

    // TODO: implement real code
    if (origUri.path.toLowerCase() != "/thumbnail") {
      throw new FileNotFoundException("URI not supported by PhotoLibrary: " + uri);
    }

    Map<String, String> query = splitQuery(uri.toURL());
    String photoId = query.get('photoId');
    int width = Integer.parseInt(query.get('width'));
    int height = Integer.parseInt(query.get('height'));
    double quality = Double.parseDouble(query.get('quality'));

    //String resultText = "Result of handleOpenForRead: " + width + "," + height + "," + quality;
    //InputStream is = new ByteArrayInputStream( resultText.getBytes( Charset.defaultCharset() ) );
    //return new CordovaResourceApi.OpenForReadResult(uri, is, "text/plain", is.available(), null);

    PictureData thumbnailData = getThumbnail(photoId, width, height, quality);
    InputStream is = new ByteArrayInputStream(thumbnailData.getBytes());
    return new CordovaResourceApi.OpenForReadResult(uri, is, thumbnailData.getMimeType() , is.available(), null);
  }

  private ArrayList<JSONObject> getLibrary() throws JSONException {

    // All columns here: https://developer.android.com/reference/android/provider/MediaStore.Images.ImageColumns.html,
    // https://developer.android.com/reference/android/provider/MediaStore.MediaColumns.html
    JSONObject columns = new JSONObject() {{
      put("int.id", MediaStore.Images.Media._ID);
      put("filename", MediaStore.Images.ImageColumns.DISPLAY_NAME);
      put("nativeURL", MediaStore.MediaColumns.DATA);
      put("int.width", MediaStore.Images.ImageColumns.WIDTH);
      put("int.height", MediaStore.Images.ImageColumns.HEIGHT);
      put("date.creationDate", MediaStore.Images.ImageColumns.DATE_TAKEN);
    }};

    final ArrayList<JSONObject> queryResults = queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "");

    ArrayList<JSONObject> results = new ArrayList<JSONObject>();

    for (JSONObject queryResult : queryResults) {
      if (queryResult.getInt("height") <=0 || queryResult.getInt("width") <= 0) {
        System.err.println(queryResult);
      } else {
        queryResult.put("id", queryResult.get("id") + ";" + queryResult.get("nativeURL")); // photoId is in format "imageid;imageurl"
        results.add(queryResult);
      }
    }

    Collections.reverse(results);

    return results;
  }

  private PictureData getThumbnail(String photoId, int thumbnailWidth, int thumbnailHeight, double quality) throws IOException {
    Bitmap bitmap;

    if (thumbnailWidth == 512 && thumbnailHeight == 384) { // In such case, thumbnail will be cached by MediaStore
      int imageId = getImageId(photoId);
      bitmap = MediaStore.Images.Thumbnails.getThumbnail(
        getContext().getContentResolver(),
        imageId ,
        MediaStore.Images.Thumbnails.MINI_KIND,
        (BitmapFactory.Options) null);
    } else { // No free caching here
      String imageUrl = getImageUrl(photoId);
      Uri imageUri = Uri.fromFile(new File(imageUrl));
      BitmapFactory.Options options = new BitmapFactory.Options();

      options.inJustDecodeBounds = true;
      InputStream is = getContext().getContentResolver().openInputStream(imageUri);
      BitmapFactory.decodeStream(is, null, options);

      // get bitmap with size of closest power of 2
      options.inSampleSize = calculateInSampleSize(options, thumbnailWidth, thumbnailHeight);
      options.inJustDecodeBounds = false;
      is = getContext().getContentResolver().openInputStream(imageUri);
      Bitmap sampledBitmap = BitmapFactory.decodeStream(is, null, options);
      is.close();

      // resize to exact size needed
      bitmap = Bitmap.createScaledBitmap(sampledBitmap, thumbnailWidth, thumbnailHeight, true);
      if (sampledBitmap != bitmap) {
        sampledBitmap.recycle();
      }
    }

    // TODO: cache bytes
    byte[] bytes = getJpegBytesFromBitmap(bitmap, quality);
    String mimeType = "image/jpeg";

    bitmap.recycle();

    return new PictureData(bytes, mimeType);
  }

  private PictureData getPhoto(String photoId) throws IOException {
    int imageId = getImageId(photoId);
    String imageUrl = getImageUrl(photoId);
    Uri imageUri = Uri.fromFile(new File(imageUrl));

    String mimeType = queryMimeType(imageId);

    InputStream is = getContext().getContentResolver().openInputStream(imageUri);
    byte[] bytes =  readBytes(is);
    is.close();

    return new PictureData(bytes, mimeType);
  }

  private ArrayList<JSONObject> queryContentProvider(Uri collection, JSONObject columns, String whereClause) throws JSONException {

    final ArrayList<String> columnNames = new ArrayList<String>();
    final ArrayList<String> columnValues = new ArrayList<String>();

    Iterator<String> iteratorFields = columns.keys();

    while (iteratorFields.hasNext()) {
      String column = iteratorFields.next();

      columnNames.add(column);
      columnValues.add("" + columns.getString(column));
    }

    final String sortOrder = MediaStore.Images.Media.DATE_TAKEN;

    final Cursor cursor = getContext().getContentResolver().query(
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

  private String queryMimeType(int imageId) {

    Cursor cursor = getContext().getContentResolver().query(
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

  private Context getContext() {
    return this.cordova.getActivity().getApplicationContext();
  }

  private byte[] getJpegBytesFromBitmap(Bitmap bitmap, double quality) {
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, (int)(quality * 100), stream);
    return stream.toByteArray();
  }

  private SimpleDateFormat dateFormatter;

  // photoId is in format "imageid;imageurl"
  private int getImageId(String photoId) {
    return Integer.parseInt(photoId.substring(0, photoId.indexOf(';')));
  }

  // photoId is in format "imageid;imageurl"
  private String getImageUrl(String photoId) {
    return photoId.substring(photoId.indexOf(';') + 1);
  }

  private PluginResult createPluginResult(PluginResult.Status status, PictureData pictureData) {
    return new PluginResult(status,
      Arrays.asList(
        new PluginResult(status, pictureData.getBytes()),
        new PluginResult(status, pictureData.getMimeType())));
  }

  public byte[] readBytes(InputStream inputStream) throws IOException {
    ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();

    int bufferSize = 1024;
    byte[] buffer = new byte[bufferSize];

    int len = 0;
    while ((len = inputStream.read(buffer)) != -1) {
      byteBuffer.write(buffer, 0, len);
    }

    return byteBuffer.toByteArray();
  }

  // From https://developer.android.com/training/displaying-bitmaps/load-bitmap.html
  public static int calculateInSampleSize(
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

  private class PictureData {
    private byte[] bytes;
    private String mimeType;

    public PictureData(byte[] bytes, String mimeType) {
      this.bytes = bytes;
      this.mimeType = mimeType;
    }

    public byte[] getBytes() { return this.bytes; }
    public String getMimeType() { return this.mimeType; }
  }

  // From http://stackoverflow.com/a/13592567/1691132
  public static Map<String, String> splitQuery(URL url) throws UnsupportedEncodingException {
    Map<String, String> query_pairs = new LinkedHashMap<String, String>();
    String query = url.getQuery();
    String[] pairs = query.split("&");
    for (String pair : pairs) {
      int idx = pair.indexOf("=");
      query_pairs.put(URLDecoder.decode(pair.substring(0, idx), "UTF-8"), URLDecoder.decode(pair.substring(idx + 1), "UTF-8"));
    }
    return query_pairs;
  }

}
