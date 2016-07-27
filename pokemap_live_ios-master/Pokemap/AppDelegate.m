//
//  AppDelegate.m
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "AppDelegate.h"
#import "RFLocationManager.h"
#import <GoogleMaps/GoogleMaps.h>
#import "RFConstants.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "RFMapObjectsManager.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Firebase.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];

    [[UICKeyChainStore keyChainStore] setString:nil forKey:@"api_url"];
    
    [RFLocationManager instance];
    
    [GMSServices provideAPIKey:RFGoogleApiKey];
    
    // Use Firebase library to configure APIs
    [FIRApp configure];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"Entered background");
   
    
        UIApplication *app = [UIApplication sharedApplication];
        UIBackgroundTaskIdentifier bgTask;
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
             [[RFMapObjectsManager instance] pauseUpdateTimer];
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            if (localNotification == nil)
            {
                return;
            }
            else
            {
                localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                localNotification.alertAction = nil;
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                localNotification.alertBody = @"Reopen app to continue scanning";
                localNotification.alertAction = NSLocalizedString(@"Stopped Scanning", nil);
                localNotification.applicationIconBadgeNumber=1;
                localNotification.repeatInterval=0;
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
        }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    
    NSLog(@"Entered foreground");
    [[RFMapObjectsManager instance] resumeUpdateTimer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[RFMapObjectsManager instance] cleanExpiredPokemons];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
