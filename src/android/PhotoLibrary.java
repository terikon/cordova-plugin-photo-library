package com.terikon.cordova.photolibrary;

import android.provider.MediaStore;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;

import java.util.ArrayList;
import java.util.Iterator;

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
  }

  @Override
  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    try {

      if (ACTION_GET_LIBRARY.equals(action)) {
        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              ArrayOfObjects library = getLibrary();
              callbackContext.success(new JSONArray(library));
            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;
      } else if (ACTION_GET_THUMBNAIL.equals(action)) {
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

  private ArrayOfObjects getLibrary() {

    return null;
  }

  private void getThumbnail() {

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

  private ArrayOfObjects queryContentProvider(Uri collection, Object columns, String whereClause) throws JSONException {
    final ArrayList<String> columnNames = new ArrayList<String>();
    final ArrayList<String> columnValues = new ArrayList<String>();

    Iterator<String> iteratorFields = columns.keys();

    while (iteratorFields.hasNext()) {
      String column = iteratorFields.next();

      columnNames.add(column);
      columnValues.add("" + columns.getString(column));
    }

    final Cursor cursor = getContext().getContentResolver().query(collection, columnValues.toArray(new String[columns.length()]), whereClause, null, null);
    final ArrayOfObjects buffer = new ArrayOfObjects();

    if (cursor.moveToFirst()) {
      do {
        Object item = new Object();

        for (String column : columnNames) {
          int columnIndex = cursor.getColumnIndex(columns.get(column).toString());

          if (column.startsWith("int.")) {
            item.put(column.substring(4), cursor.getInt(columnIndex));
            if (column.substring(4).equals("width") && item.getInt("width") == 0)
            {
              System.err.println("cursor: " + cursor.getInt(columnIndex));

            }
          } else if (column.startsWith("float.")) {
            item.put(column.substring(6), cursor.getFloat(columnIndex));
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

  private class Object extends JSONObject { }

  private class ArrayOfObjects extends ArrayList<Object> { }

}
