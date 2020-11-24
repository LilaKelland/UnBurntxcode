//
//  AppDelegate.swift
//  tryAlamoFirePost
//
//  Created by Lila Kelland on 2020-07-09.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//

import UIKit
import UserNotifications
import Alamofire
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    let cookingParameters = CookingParameters()
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        UserNotifications.UNUserNotificationCenter.current().delegate = self
        // changed to UserNotifications
        // Define the custom actions.
        let fireAction = UNNotificationAction(identifier: "FIRE",
              title: "Actually on fire?",
              options: UNNotificationActionOptions(rawValue: 0))
        let noFireAction = UNNotificationAction(identifier: "NO_FIRE",
              title: "Was not on fire.",
              options: UNNotificationActionOptions(rawValue: 0))
       
        // Define the notification type
        let wasThereFireCategory =
              UNNotificationCategory(identifier: "WAS_THERE_FIRE",
              actions: [fireAction, noFireAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current() // is this in the wrong place?
        notificationCenter.setNotificationCategories([wasThereFireCategory])
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        // this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // Handle remote notification registration - device tokens.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       // self.sendDeviceTokenToServer(data:deviceToken)
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()
        print(deviceTokenString)

        // Forward the token to your provider, using a custom method.
        self.forwardTokenToServer(tokenString: deviceTokenString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }

    func forwardTokenToServer(tokenString: String) {
        print("Token: \(tokenString)")
        let parameters = [
                "tokenString": tokenString,
                ]
        AF.request("\(Environment.url_string)/setToken", method: .get, parameters: parameters)
                .validate()
               .responseString
                { response in
                switch response.result {
                case .success( _):
                    print(tokenString)
                case .failure(let error):
                    print(error)
                }
            }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
         print("Push notification received in foreground.")
         completionHandler([.alert, .sound, .badge])
        
        // Define the custom actions.
        let fireAction = UNNotificationAction(identifier: "FIRE",
              title: "Actually on fire?",
              options: UNNotificationActionOptions(rawValue: 0))
        let noFireAction = UNNotificationAction(identifier: "NO_FIRE",
              title: "Was not on fire.",
              options: UNNotificationActionOptions(rawValue: 0))
       
        // Define the notification type
        let wasThereFireCategory =
              UNNotificationCategory(identifier: "WAS_THERE_FIRE",
              actions: [fireAction, noFireAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current() // is this in the wrong place?
        notificationCenter.setNotificationCategories([wasThereFireCategory])
        
    }
 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
           didReceive response: UNNotificationResponse,
           withCompletionHandler completionHandler:
             @escaping () -> Void) {
       
//       // Get (and assign) ID from the original notification. - when ready to handle data
            
       // Perform the task associated with the action.
       switch response.actionIdentifier {
       case "FIRE":
          print("it was on fire")
        // gather time, and parameters when was on fire
          break
            
       case "NO_FIRE":
         print ("false alarm")
        //gather time and parameters when false alarm
          break
            
       // Handle other actions…
     
       default:
          break
       }
        
       // Always call the completion handler when done.
       completionHandler()
    }

}
