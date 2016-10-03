package com.terikon.cordova.photolibrary;

import android.provider.MediaStore;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.Date;
import java.text.SimpleDateFormat;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PhotoLibrary extends CordovaPlugin {

  public static final String ACTION_GET_LIBRARY = "getLibrary";
  public static final String ACTION_GET_THUMBNAIL= "getThumbnail";
  public static final String ACTION_GET_PHOTO = "getPhoto";
  public static final String ACTION_STOP_CACHING = "stopCaching";

  //TODO: remove
  public static final String ACTION_ECHO = "echo";

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

        final int photoId = args.getInt(0);
        final JSONObject options = args.optJSONObject(1);
        final int thumbnailWidth = options.getInt("thumbnailWidth");
        final int thumbnailHeight = options.getInt("thumbnailHeight");
        final double quality = options.getDouble("quality");
        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              byte[] thumbnail = getThumbnail(photoId, thumbnailWidth, thumbnailHeight, quality);
              callbackContext.success(thumbnail);
            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      } else if (ACTION_GET_PHOTO.equals(action)) {

        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              // TODO
              callbackContext.success();
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

      } else if (ACTION_ECHO.equals(action)) { // TODO: remove this

        String message = args.getString(0);
        this.echo(message, callbackContext);
        return true;

      }
      return false;

    } catch(Exception e) {
      e.printStackTrace();
      callbackContext.error(e.getMessage());
      return false;
    }
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
      //put("mime_type", MediaStore.Images.ImageColumns.MIME_TYPE);
      //put("int.size", MediaStore.Images.ImageColumns.SIZE);
      //put("int.thumbnail_id", MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC);
    }};

    final ArrayList<JSONObject> queryResults = queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, ""); // TODO: order by

    ArrayList<JSONObject> results = new ArrayList<JSONObject>();

    for (JSONObject queryResult : queryResults) {
      if (queryResult.getInt("height") <=0 || queryResult.getInt("width") <= 0) {
        System.err.println(queryResult);
      } else {
        results.add(queryResult);
      }
    }

    Collections.reverse(results);

    return results;
  }

  private byte[] getThumbnail(int photoId, int thumbnailWidth, int thumbnailHeight, double quality) {
    return null;
  }

  private void getPhoto() {

  }

  private void stopCaching() {

  }

  // TODO: remove this
  private void echo(String message, CallbackContext callbackContext) {
    if (message != null && message.length() > 0) {
      callbackContext.success(message);
    } else {
      callbackContext.error("Expected one non-empty string argument.");
    }
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

    final Cursor cursor = getContext().getContentResolver().query(collection, columnValues.toArray(new String[columns.length()]), whereClause, null, null);
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

  private Context getContext() {
    return this.cordova.getActivity().getApplicationContext();
  }

  private SimpleDateFormat dateFormatter;

}
