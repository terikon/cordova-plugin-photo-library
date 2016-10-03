package com.terikon.cordova.photolibrary;

import android.provider.MediaStore;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

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

  private class Object extends JSONObject { }

  private class ArrayOfObjects extends ArrayList<Object> { }

}
