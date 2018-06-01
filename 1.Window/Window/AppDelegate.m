//
//  AppDelegate.m
//  Window
//
//  Created by Vaibhav Zodge on 01/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MyView.h"

@implementation AppDelegate

        {
            UIWindow *mainWindow;
            ViewController *mainViewController;
            MyView *myView;
            
        }
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect screenBounds=[[UIScreen mainScreen]bounds];
    
    mainWindow=[[UIWindow alloc]initWithFrame:screenBounds];
    mainViewController=[[ViewController alloc]init];
    [mainWindow setRootViewController:mainViewController];
    myView=[[MyView alloc]initWithFrame:screenBounds];
    [mainViewController setView:myView];
    [myView release];
    [mainWindow makeKeyAndVisible];
    return (YES);
}
-(void)applicationWillResignActive:(UIApplication *)application
{
    
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    
}

-(void)dealloc
{
    [myView release];
    [mainViewController release];
    [mainWindow release];
    [super dealloc];
}

@end
