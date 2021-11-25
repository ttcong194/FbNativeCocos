/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2016 Chukong Technologies Inc.
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

#import "AppController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "SDKWrapper.h"
#import "platform/ios/CCEAGLView-ios.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#include "cocos/scripting/js-bindings/jswrapper/SeApi.h"

using namespace cocos2d;

@implementation AppController

Application* app = nullptr;
static RootViewController* rootViewController = nullptr;
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle
+(NSString *)FacebookFromJs:(NSString *)key value:(NSString *)value{
    if([key isEqual:@"Login"]){
        FBSDKLoginManager * loginManager = [[FBSDKLoginManager alloc] init];
        
        [loginManager logInWithPermissions:@[@"email",@"public_profile"] fromViewController:rootViewController handler:^(FBSDKLoginManagerLoginResult * _Nullable result, NSError * _Nullable error) {
            if(result != NULL){
                NSLog(@"TOKEN: %@",result.token.tokenString);
                NSLog(@"USER_ID: %@",result.token.userID);
                NSDictionary * data = @{@"token":result.token.tokenString,
                                        @"userID":result.token.userID};
                [self sendBackToFacebookJs:@"Login" withValue:data];
            }
        }];
    }
    if([key isEqual:@"CheckLogin"]){
        FBSDKAccessToken *accessToken = [FBSDKAccessToken currentAccessToken];
        if(accessToken != nil && !accessToken.isExpired){
            return @"true";
        }
        return @"false";
    }
    
    if([key isEqual:@"Logout"]){
        FBSDKLoginManager * loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logOut];
        NSDictionary * data = @{};
        [self sendBackToFacebookJs:@"Logout" withValue:data];
    }
    if([key isEqual:@"GraphAPI"]){
        NSData *jsonData = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        NSString* path =[jsonDic objectForKey:@"pathGraph"];
        NSDictionary* params =[jsonDic objectForKey:@"params"];
        NSString* tag =[jsonDic objectForKey:@"tag"];
        NSString* method =[jsonDic objectForKey:@"method"];
    
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                          initWithGraphPath:path
                                          parameters:params
                                          HTTPMethod:method];
        [request startWithCompletion:^(id<FBSDKGraphRequestConnecting>  _Nullable connection, id  _Nullable result, NSError * _Nullable error) {
            if (!error){
               NSLog(@"result: %@",result);
                NSDictionary * data = @{@"hasError":@false,
                                        @"tag":tag,
                                        @"pathGraph":path,
                                        @"data":result};
                [self sendBackToFacebookJs:@"GraphAPI" withValue:data];
            }
            else {
               NSLog(@"result: %@",[error description]);
                NSDictionary * data = @{@"hasError":@true,
                                        @"tag":tag,
                                        @"pathGraph":path,
                                        @"data":@""};
                [self sendBackToFacebookJs:@"GraphAPI" withValue:data];
             }
        }];
    }
    return @"ok";
}

+(void) sendBackToFacebookJs:(NSString*) key withValue:(NSDictionary*) value{
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(jsonString != NULL){
        NSString *execStr = [NSString stringWithFormat:@"window.facebookManager.nativeCallBack('%@','%@')",key,jsonString];
        se::ScriptEngine::getInstance()->evalString([execStr UTF8String]);
    }
}

-(void) sendBackToFacebookJs:(NSString*) key withValue:(NSString*) value{
    if(value != NULL){
        NSString *execStr = [NSString stringWithFormat:@"window.facebookManager.nativeCallBack('%@','%@')",key,value];
        se::ScriptEngine::getInstance()->evalString([execStr UTF8String]);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[SDKWrapper getInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    // Add the view controller's view to the window and display.
    float scale = [[UIScreen mainScreen] scale];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    window = [[UIWindow alloc] initWithFrame: bounds];
    
    // cocos2d application instance
    app = new AppDelegate(bounds.size.width * scale, bounds.size.height * scale);
    app->setMultitouch(true);
    
    // Use RootViewController to manage CCEAGLView
    _viewController = [[RootViewController alloc]init];
    rootViewController = _viewController;
#ifdef NSFoundationVersionNumber_iOS_7_0
    _viewController.automaticallyAdjustsScrollViewInsets = NO;
    _viewController.extendedLayoutIncludesOpaqueBars = NO;
    _viewController.edgesForExtendedLayout = UIRectEdgeAll;
#else
    _viewController.wantsFullScreenLayout = YES;
#endif
    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: _viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:_viewController];
    }
    
    [window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    //run the cocos2d-x game scene
    app->start();
    
    // Override point for customization after application launch.
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    //[FBSDKSettings setAdvertiserTrackingEnabled:NO];
    
    [FBSDKSettings enableLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
    
    [FBSDKSettings setAutoLogAppEventsEnabled:YES];
    [FBSDKSettings setAdvertiserIDCollectionEnabled:YES];
    [FBSDKSettings setAdvertiserTrackingEnabled:YES];
    
    [self requestIDFA];
    [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(receiveNotification:)
            name:FBSDKAccessTokenDidChangeNotification
            object:nil];
    return YES;
}
- (void) receiveNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.

    if ([[notification name] isEqualToString:FBSDKAccessTokenDidChangeNotification])
    {
        NSLog(@"FBSDKAccessTokenDidChangeNotification");
        if(notification.userInfo != NULL){
            BOOL hasChange = notification.userInfo[FBSDKAccessTokenDidChangeUserIDKey];
            if(hasChange){
                FBSDKAccessToken * accessToken = notification.userInfo[FBSDKAccessTokenChangeNewKey];
                if(accessToken != NULL){
                    NSLog(@"Refresh: %@",accessToken.userID);
                    NSLog(@"Refresh: %@",accessToken.tokenString);
                    [self sendBackToFacebookJs:@"Refresh" withValue:accessToken.tokenString];
                }

            }
        }
    }
}
- (void)requestIDFA {
  [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
    // Tracking authorization completed. Start loading ads here.
      if(status == ATTrackingManagerAuthorizationStatusAuthorized){
          [FBSDKSettings setAdvertiserTrackingEnabled:YES];
          //[FBSDKSettings setAdvertiserIDCollectionEnabled:YES];
          //[FBSDKSettings setAutoLogAppEventsEnabled:YES];
      }
      else{
          [FBSDKSettings setAdvertiserTrackingEnabled:NO];
      }
  }];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

  BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
    openURL:url
    sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
    annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
  ];
    return handled;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    app->onPause();
    [[SDKWrapper getInstance] applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    app->onResume();
    [[SDKWrapper getInstance] applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    [[SDKWrapper getInstance] applicationDidEnterBackground:application]; 
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    [[SDKWrapper getInstance] applicationWillEnterForeground:application]; 
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[SDKWrapper getInstance] applicationWillTerminate:application];
    delete app;
    app = nil;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

@end
