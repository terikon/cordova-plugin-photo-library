package com.terikon.cordova.photolibrary;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.provider.MediaStore;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.Iterator;

public class PhotoLibraryService {

  // TODO: implement cache
  //int cacheSize = 4 * 1024 * 1024; // 4MB
  //private LruCache<String, byte[]> imageCache = new LruCache<String, byte[]>(cacheSize);

	protected PhotoLibraryService() {
    dateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm a z");
	}

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

  public ArrayList<JSONObject> getLibrary(Context context) throws JSONException {

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

    final ArrayList<JSONObject> queryResults = queryContentProvider(context, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "");

    ArrayList<JSONObject> results = new ArrayList<>();

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

  public PictureData getThumbnail(Context context, String photoId, int thumbnailWidth, int thumbnailHeight, double quality) throws IOException {

    Bitmap bitmap;

    // TODO: maybe it never worth using MediaStore.Images.Thumbnails.getThumbnail, as it returns sizes less than 512x384?
    if (thumbnailWidth == 512 && thumbnailHeight == 384) { // In such case, thumbnail will be cached by MediaStore
      int imageId = getImageId(photoId);
      // For some reason and against documentation, MINI_KIND image can be returned in size different from 512x384, so the image will be scaled later if needed
      bitmap = MediaStore.Images.Thumbnails.getThumbnail(
        context.getContentResolver(),
        imageId ,
        MediaStore.Images.Thumbnails.MINI_KIND,
        (BitmapFactory.Options) null);
    } else { // No free caching here
      String imageURL = getImageURL(photoId);
      Uri imageUri = Uri.fromFile(new File(imageURL));
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

    // resize to exact size needed
    Bitmap resizedBitmap = Bitmap.createScaledBitmap(bitmap, thumbnailWidth, thumbnailHeight, true);
    if (bitmap != resizedBitmap) {
      bitmap.recycle();
    }

    // TODO: cache bytes
    byte[] bytes = getJpegBytesFromBitmap(resizedBitmap, quality);
    String mimeType = "image/jpeg";

    bitmap.recycle();

    return new PictureData(bytes, mimeType);

  }

  public PictureAsStream getPhotoAsStream(Context context, String photoId) throws IOException {

    int imageId = getImageId(photoId);
    String imageURL = getImageURL(photoId);
    Uri imageUri = Uri.fromFile(new File(imageURL));

    String mimeType = queryMimeType(context, imageId);

    InputStream is = context.getContentResolver().openInputStream(imageUri);

    return new PictureAsStream(is, mimeType);

  }

  public PictureData getPhoto(Context context, String photoId) throws IOException {

    PictureAsStream pictureAsStream = getPhotoAsStream(context, photoId);

    byte[] bytes =  readBytes(pictureAsStream.getStream());
    pictureAsStream.getStream().close();

    return new PictureData(bytes, pictureAsStream.getMimeType());

  }

  private static PhotoLibraryService instance = null;

  private SimpleDateFormat dateFormatter;

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

  private static byte[] readBytes(InputStream inputStream) throws IOException {

    ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();

    int bufferSize = 1024;
    byte[] buffer = new byte[bufferSize];

    int len = 0;
    while ((len = inputStream.read(buffer)) != -1) {
      byteBuffer.write(buffer, 0, len);
    }

    return byteBuffer.toByteArray();

  }

  // photoId is in format "imageid;imageurl"
  private static int getImageId(String photoId) {
    return Integer.parseInt(photoId.substring(0, photoId.indexOf(';')));
  }

  // photoId is in format "imageid;imageurl"
  private static String getImageURL(String photoId) {
    return photoId.substring(photoId.indexOf(';') + 1);
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

}
