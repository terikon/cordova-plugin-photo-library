package com.terikon.cordova.photolibrary;

import android.content.Context;
import android.net.Uri;

import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PhotoLibrary extends CordovaPlugin {

  public static final String PHOTO_LIBRARY_PROTOCOL = "cdvphotolibrary";

  public static final String ACTION_GET_LIBRARY = "getLibrary";
  public static final String ACTION_GET_THUMBNAIL= "getThumbnail";
  public static final String ACTION_GET_PHOTO = "getPhoto";
  public static final String ACTION_STOP_CACHING = "stopCaching";

  private PhotoLibraryService service;

  @Override
  protected void pluginInitialize() {
    super.pluginInitialize();

    service = PhotoLibraryService.getInstance();

  }

  @Override
  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    try {

      if (ACTION_GET_LIBRARY.equals(action)) {

        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {
              ArrayList<JSONObject> library = service.getLibrary(getContext());
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
              PhotoLibraryService.PictureData thumbnail = service.getThumbnail(getContext(), photoId, thumbnailWidth, thumbnailHeight, quality);
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
              PhotoLibraryService.PictureData thumbnail = service.getPhoto(getContext(), photoId);
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

    if (!PHOTO_LIBRARY_PROTOCOL.equals(uri.getScheme())) {
      return null;
    }
    return toPluginUri(uri);

  }

  @Override
  public CordovaResourceApi.OpenForReadResult handleOpenForRead(Uri uri) throws IOException {

    Uri origUri = fromPluginUri(uri);

    if (origUri.getPath().toLowerCase() != "/thumbnail") {
      throw new FileNotFoundException("URI not supported by PhotoLibrary: " + uri);
    }

    String photoId = origUri.getQueryParameter("photoId");
    int width = Integer.parseInt(origUri.getQueryParameter("width"));
    int height = Integer.parseInt(origUri.getQueryParameter("height"));
    double quality = Double.parseDouble(origUri.getQueryParameter("quality"));

    //String resultText = "Result of handleOpenForRead: " + width + "," + height + "," + quality;
    //InputStream is = new ByteArrayInputStream( resultText.getBytes( Charset.defaultCharset() ) );
    //return new CordovaResourceApi.OpenForReadResult(uri, is, "text/plain", is.available(), null);

    PhotoLibraryService.PictureData thumbnailData = service.getThumbnail(getContext(), photoId, width, height, quality);
    InputStream is = new ByteArrayInputStream(thumbnailData.getBytes());

    return new CordovaResourceApi.OpenForReadResult(uri, is, thumbnailData.getMimeType() , is.available(), null);

  }

  private Context getContext() {

    return this.cordova.getActivity().getApplicationContext();

  }

  private PluginResult createPluginResult(PluginResult.Status status, PhotoLibraryService.PictureData pictureData) {

    return new PluginResult(status,
      Arrays.asList(
        new PluginResult(status, pictureData.getBytes()),
        new PluginResult(status, pictureData.getMimeType())));

  }

}
