/****************************************************************************
Copyright (c) 2015-2016 Chukong Technologies Inc.
Copyright (c) 2017-2018 Xiamen Yaji Software Co., Ltd.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package org.cocos2dx.javascript;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;
import org.json.JSONException;
import org.json.JSONObject;

import android.os.Bundle;

import android.content.Intent;
import android.content.res.Configuration;
import android.util.Log;

import com.facebook.AccessToken;
import com.facebook.AccessTokenTracker;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.GraphRequest;
import com.facebook.GraphResponse;
import com.facebook.HttpMethod;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;

import java.util.Arrays;
import java.util.Iterator;

public class AppActivity extends Cocos2dxActivity {
    private final String TAG = "AppActivity";
    private static AppActivity app = null;
    CallbackManager callbackManager;
    AccessTokenTracker accessTokenTracker;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        app = this;
        // Workaround in
        // https://stackoverflow.com/questions/16283079/re-launch-of-activity-on-home-button-but-only-the-first-time/16447508
        if (!isTaskRoot()) {
            // Android launched another instance of the root activity into an existing task
            // so just quietly finish and go away, dropping the user back into the activity
            // at the top of the stack (ie: the last state of this task)
            // Don't need to finish it again since it's finished in super.onCreate .
            return;
        }
        callbackManager = CallbackManager.Factory.create();

        accessTokenTracker = new AccessTokenTracker() {
            @Override
            protected void onCurrentAccessTokenChanged(
                    AccessToken oldAccessToken,
                    AccessToken currentAccessToken) {
                // Set the access token using
                // currentAccessToken when it's loaded or set.
                if(oldAccessToken != null) {
                    Log.d("TAG", "old:" + oldAccessToken.getToken());
                }
                if(currentAccessToken != null){
                    Log.d("TAG","new:"+currentAccessToken.getToken());
                    app.FacebookFromNative("Refresh",currentAccessToken.getToken());
                }
            }
        };
        // Callback registration
        LoginManager.getInstance().registerCallback(callbackManager, new FacebookCallback<LoginResult>() {
            @Override
            public void onSuccess(LoginResult loginResult) {
                // App code
                Log.d("TAG",loginResult.getAccessToken().getUserId());
                try {
                    JSONObject data = new JSONObject();
                    data.put("token", loginResult.getAccessToken().getToken());
                    data.put("userID", loginResult.getAccessToken().getUserId());
                    AppActivity.this.FacebookFromNative("Login", data);
                }
                catch (JSONException ex){

                }
            }

            @Override
            public void onCancel() {
                // App code
            }

            @Override
            public void onError(FacebookException exception) {
                // App code
            }
        });
        // DO OTHER INITIALIZATION BELOW
        SDKWrapper.getInstance().init(this);

    }

    public void FacebookFromNative(final String key, final JSONObject value) {
        this.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                String returnValue = value.toString();
                String funcCall = "window.facebookManager.nativeCallBack('"+key+"','" + returnValue +"')";
                Log.d(TAG, returnValue);
                Log.d(TAG, funcCall);
                Cocos2dxJavascriptJavaBridge.evalString(funcCall);
            }
        });
    }

    public void FacebookFromNative(final String key, final String value) {
        this.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                String returnValue = value.toString();
                String funcCall = "window.facebookManager.nativeCallBack('"+key+"','" + returnValue +"')";
                Log.d(TAG, returnValue);
                Log.d(TAG, funcCall);
                Cocos2dxJavascriptJavaBridge.evalString(funcCall);
            }
        });
    }

    public static String FacebookFromJs(final String key, final String value){
        if(key.equals("CheckLogin")) {
            AccessToken accessToken = AccessToken.getCurrentAccessToken();
            if( accessToken != null && !accessToken.isExpired()){
                return "true";
            }
            return "false";
        }
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(app.TAG,key + "-"+value);
                if(key.equals("Login")) {
                    LoginManager.getInstance().logIn(app, Arrays.asList("public_profile","email"));
                }
                if(key.equals("Logout")) {
                    LoginManager.getInstance().logOut();
                    JSONObject data = new JSONObject();
                    app.FacebookFromNative("Logout", data);
                }
                if(key.equals("GraphAPI")) {
                    try {
                        JSONObject jsonObject = new JSONObject(value);
                        final String path =  jsonObject.getString("pathGraph");
                        JSONObject params =  jsonObject.getJSONObject("params");
                        Bundle paramsBundle = jsonToBundle(params);
                        final String tag =  jsonObject.getString("tag");
                        String method =  jsonObject.getString("method");


                        new GraphRequest(
                                AccessToken.getCurrentAccessToken(),
                                path,
                                paramsBundle,
                                HttpMethod.valueOf(method),
                                new GraphRequest.Callback() {
                                    public void onCompleted(GraphResponse response) {
                                        /* handle the result */
                                        Log.d("TAG",response.getRawResponse());
                                        try {
                                            JSONObject dataReturn = new JSONObject();
                                            dataReturn.put("hasError", false);
                                            dataReturn.put("tag", tag);
                                            dataReturn.put("pathGraph", path);
                                            dataReturn.put("data", response.getJSONObject());

                                            app.FacebookFromNative("GraphAPI",dataReturn);
                                        }
                                        catch (JSONException ex){

                                        }

                                    }

                                }
                        ).executeAsync();
                    }
                    catch (JSONException ex){

                    }

                }
            }});
        return "ok";
    }

    public static Bundle jsonToBundle(JSONObject jsonObject) throws JSONException {
        Bundle bundle = new Bundle();
        Iterator iter = jsonObject.keys();
        while(iter.hasNext()){
            String key = (String)iter.next();
            String value = jsonObject.getString(key);
            bundle.putString(key,value);
        }
        return bundle;
    }

    @Override
    public Cocos2dxGLSurfaceView onCreateView() {
        Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
        // TestCpp should create stencil buffer
        glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
        SDKWrapper.getInstance().setGLSurfaceView(glSurfaceView, this);

        return glSurfaceView;
    }

    @Override
    protected void onResume() {
        super.onResume();
        SDKWrapper.getInstance().onResume();

    }

    @Override
    protected void onPause() {
        super.onPause();
        SDKWrapper.getInstance().onPause();

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        // Workaround in https://stackoverflow.com/questions/16283079/re-launch-of-activity-on-home-button-but-only-the-first-time/16447508
        if (!isTaskRoot()) {
            return;
        }
        accessTokenTracker.stopTracking();
        SDKWrapper.getInstance().onDestroy();

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        callbackManager.onActivityResult(requestCode, resultCode, data);
        super.onActivityResult(requestCode, resultCode, data);
        SDKWrapper.getInstance().onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        SDKWrapper.getInstance().onNewIntent(intent);
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        SDKWrapper.getInstance().onRestart();
    }

    @Override
    protected void onStop() {
        super.onStop();
        SDKWrapper.getInstance().onStop();
    }

    @Override
    public void onBackPressed() {
        SDKWrapper.getInstance().onBackPressed();
        super.onBackPressed();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        SDKWrapper.getInstance().onConfigurationChanged(newConfig);
        super.onConfigurationChanged(newConfig);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        SDKWrapper.getInstance().onRestoreInstanceState(savedInstanceState);
        super.onRestoreInstanceState(savedInstanceState);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        SDKWrapper.getInstance().onSaveInstanceState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onStart() {
        SDKWrapper.getInstance().onStart();
        super.onStart();
    }
}
