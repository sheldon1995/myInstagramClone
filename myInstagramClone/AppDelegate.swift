//
//  AppDelegate.swift
//  myInstagramClone
//
//  Created by Sheldon on 1/31/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        attemmptToRegisterForNotifications(application: application)
        
        return true
    }

    // Request user's permission to send notifications.
    func attemmptToRegisterForNotifications(application: UIApplication){
        
        
        UNUserNotificationCenter.current().delegate = self
        
        // Notification types.
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        // If click allow, print success info.
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (authorized, error) in
            if authorized{
                print("DEBUG: SUCCESSFULLY REGISTERED FOR NOTIFICATION")
            }
        }
        
        application.registerForRemoteNotifications()
        
    }
    
    
    // Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Get the device token to send notifictions to the device.
        // Token : A globally unique token that identifies this device to APNs. Send this token to the server that you use to generate remote notifications.
        print("DEBUG: Registered for notificatios with device token: ",deviceToken)
    }
    
    // Check to see if we have notification token.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
      
        print("DEBUG: Registered with FCM Token: ",fcmToken)
    }
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

