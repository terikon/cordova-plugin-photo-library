package com.terikon.cordova.photolibrary;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.Uri;

import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PhotoLibrary extends CordovaPlugin {

  public static final String PHOTO_LIBRARY_PROTOCOL = "cdvphotolibrary";

  public static final int DEFAULT_WIDTH = 512;
  public static final int DEFAULT_HEIGHT = 384;
  public static final double DEFAULT_QUALITY = 0.5;

  public static final String ACTION_GET_LIBRARY = "getLibrary";
  public static final String ACTION_GET_THUMBNAIL = "getThumbnail";
  public static final String ACTION_GET_PHOTO = "getPhoto";
  public static final String ACTION_STOP_CACHING = "stopCaching";
  public static final String ACTION_REQUEST_AUTHORIZATION = "requestAuthorization";
  public static final String ACTION_SAVE_IMAGE = "saveImage";
  public static final String ACTION_SAVE_VIDEO = "saveVideo";

  public CallbackContext callbackContext;

  @Override
  protected void pluginInitialize() {
    super.pluginInitialize();

    service = PhotoLibraryService.getInstance();

  }

  @Override
  public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {

    this.callbackContext = callbackContext;

    try {

      if (ACTION_GET_LIBRARY.equals(action)) {
        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {

              if (!cordova.hasPermission(READ_EXTERNAL_STORAGE)) {
                callbackContext.error(service.PERMISSION_ERROR);
                return;
              }

              ArrayList<JSONObject> library = service.getLibrary(getContext());
              JSONObject result = new JSONObject();
              result.put("isPartial", false);
              result.put("library", new JSONArray(library));
              callbackContext.success(result);

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

              final String photoId = args.getString(0);
              final JSONObject options = args.optJSONObject(1);
              final int thumbnailWidth = options.getInt("thumbnailWidth");
              final int thumbnailHeight = options.getInt("thumbnailHeight");
              final double quality = options.getDouble("quality");

              if (!cordova.hasPermission(READ_EXTERNAL_STORAGE)) {
                callbackContext.error(service.PERMISSION_ERROR);
                return;
              }

              PhotoLibraryService.PictureData thumbnail = service.getThumbnail(getContext(), photoId, thumbnailWidth, thumbnailHeight, quality);
              callbackContext.sendPluginResult(createMultipartPluginResult(PluginResult.Status.OK, thumbnail));

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

              final String photoId = args.getString(0);

              if (!cordova.hasPermission(READ_EXTERNAL_STORAGE)) {
                callbackContext.error(service.PERMISSION_ERROR);
                return;
              }

              PhotoLibraryService.PictureData photo = service.getPhoto(getContext(), photoId);
              callbackContext.sendPluginResult(createMultipartPluginResult(PluginResult.Status.OK, photo));

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

      } else if (ACTION_REQUEST_AUTHORIZATION.equals(action)) {
        try {

          final JSONObject options = args.optJSONObject(0);
          final boolean read = options.getBoolean("read");
          final boolean write = options.getBoolean("write");

          if (read && !cordova.hasPermission(READ_EXTERNAL_STORAGE)
            || write && !cordova.hasPermission(WRITE_EXTERNAL_STORAGE)) {
            requestAuthorization(read, write);
          } else {
            callbackContext.success();
          }
        } catch (Exception e) {
          e.printStackTrace();
          callbackContext.error(e.getMessage());
        }
        return true;

      } else if (ACTION_SAVE_IMAGE.equals(action)) {
        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {

              final String url = args.getString(0);
              final String album = args.getString(1);

              if (!cordova.hasPermission(WRITE_EXTERNAL_STORAGE)) {
                callbackContext.error(service.PERMISSION_ERROR);
                return;
              }

              service.saveImage(cordova, url, album);
              callbackContext.success();

            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      } else if (ACTION_SAVE_VIDEO.equals(action)) {
        cordova.getThreadPool().execute(new Runnable() {
          public void run() {
            try {

              final String url = args.getString(0);
              final String album = args.getString(1);

              if (!cordova.hasPermission(WRITE_EXTERNAL_STORAGE)) {
                callbackContext.error(service.PERMISSION_ERROR);
                return;
              }

              service.saveVideo(cordova, url, album);
              callbackContext.success();

            } catch (Exception e) {
              e.printStackTrace();
              callbackContext.error(e.getMessage());
            }
          }
        });
        return true;

      }

      return false;

    } catch (Exception e) {
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

    boolean isThumbnail = origUri.getHost().toLowerCase().equals("thumbnail") && origUri.getPath().isEmpty();
    boolean isPhoto = origUri.getHost().toLowerCase().equals("photo") && origUri.getPath().isEmpty();

    if (!isThumbnail && !isPhoto) {
      throw new FileNotFoundException("URI not supported by PhotoLibrary");
    }

    String photoId = origUri.getQueryParameter("photoId");
    if (photoId == null || photoId.isEmpty()) {
      throw new FileNotFoundException("Missing 'photoId' query parameter");
    }

    if (isThumbnail) {

      String widthStr = origUri.getQueryParameter("width");
      int width;
      try {
        width = widthStr == null || widthStr.isEmpty() ? DEFAULT_WIDTH : Integer.parseInt(widthStr);
      } catch (NumberFormatException e) {
        throw new FileNotFoundException("Incorrect 'width' query parameter");
      }

      String heightStr = origUri.getQueryParameter("height");
      int height;
      try {
        height = heightStr == null || heightStr.isEmpty() ? DEFAULT_HEIGHT : Integer.parseInt(heightStr);
      } catch (NumberFormatException e) {
        throw new FileNotFoundException("Incorrect 'height' query parameter");
      }

      String qualityStr = origUri.getQueryParameter("quality");
      double quality;
      try {
        quality = qualityStr == null || qualityStr.isEmpty() ? DEFAULT_QUALITY : Double.parseDouble(qualityStr);
      } catch (NumberFormatException e) {
        throw new FileNotFoundException("Incorrect 'quality' query parameter");
      }

      PhotoLibraryService.PictureData thumbnailData = service.getThumbnail(getContext(), photoId, width, height, quality);

      if (thumbnailData == null) {
        throw new FileNotFoundException("Could not create thumbnail");
      }

      InputStream is = new ByteArrayInputStream(thumbnailData.getBytes());

      return new CordovaResourceApi.OpenForReadResult(uri, is, thumbnailData.getMimeType(), is.available(), null);

    } else { // isPhoto == true

      PhotoLibraryService.PictureAsStream pictureAsStream = service.getPhotoAsStream(getContext(), photoId);
      InputStream is = pictureAsStream.getStream();

      return new CordovaResourceApi.OpenForReadResult(uri, is, pictureAsStream.getMimeType(), is.available(), null);

    }

  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    super.onRequestPermissionResult(requestCode, permissions, grantResults);

    for (int r : grantResults) {
      if (r == PackageManager.PERMISSION_DENIED) {
        this.callbackContext.error(PhotoLibraryService.PERMISSION_ERROR);
        return;
      }
    }

    this.callbackContext.success();
  }

  private static final String READ_EXTERNAL_STORAGE = android.Manifest.permission.READ_EXTERNAL_STORAGE;
  private static final String WRITE_EXTERNAL_STORAGE = Manifest.permission.WRITE_EXTERNAL_STORAGE;
  private static final int REQUEST_AUTHORIZATION_REQ_CODE = 0;

  private PhotoLibraryService service;

  private Context getContext() {

    return this.cordova.getActivity().getApplicationContext();

  }

  private PluginResult createMultipartPluginResult(PluginResult.Status status, PhotoLibraryService.PictureData pictureData) {

    return new PluginResult(status,
      Arrays.asList(
        new PluginResult(status, pictureData.getBytes()),
        new PluginResult(status, pictureData.getMimeType())));

  }

  private void requestAuthorization(boolean read, boolean write) {

    List<String> permissions = new ArrayList<String>();

    if (read) {
      permissions.add(READ_EXTERNAL_STORAGE);
    }

    if (write) {
      permissions.add(WRITE_EXTERNAL_STORAGE);
    }

    cordova.requestPermissions(this, REQUEST_AUTHORIZATION_REQ_CODE, permissions.toArray(new String[0]));
  }

}
