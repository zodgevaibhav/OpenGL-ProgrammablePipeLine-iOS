//
//  AppDelegate.m
//  2.OpenGLBlankBlueWindow
//
//  Created by Vaibhav Zodge on 03/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import "MyView.h"

@interface AppDelegate ()
    {
        @private
        UIWindow *mainWindow;
        ViewController *mainViewController;
        MyView *myView;
    }
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // get screen bounds for fullscreen
    CGRect screenBounds=[[UIScreen mainScreen]bounds];
    
    // initialize window variable corresponding to screen bounds
    mainWindow=[[UIWindow alloc]initWithFrame:screenBounds];
    
    mainViewController=[[ViewController alloc]init];
    
    [mainWindow setRootViewController:mainViewController];
    
    // initialize view variable corresponding to screen bounds
    myView=[[MyView alloc]initWithFrame:screenBounds];
    
    [mainViewController setView:myView];
    
    [myView release];
    
    // add the ViewController's view as subview to the window
    [mainWindow addSubview:[mainViewController view]];
    
    // make window key window and visible
    [mainWindow makeKeyAndVisible];
    
    [myView startAnimation];
    
    return(YES);

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // code
    [myView stopAnimation]; //if program went in background
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // code
    [myView startAnimation];// f program come from background and become active
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // code
    [myView stopAnimation];
}

- (void)dealloc
{
    // code
    [myView release];
    
    [mainViewController release];
    
    [mainWindow release];
    
    [super dealloc];
}

@end
