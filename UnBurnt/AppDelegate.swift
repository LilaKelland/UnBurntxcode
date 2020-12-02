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
                     didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        // changed to UserNotifications
        registerForPushNotifications()
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

    
    func registerForPushNotifications() {
//            let userNotificationCenter = UNUserNotificationCenter.current()
//            userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
//                print("Permission granted: \(granted)")
//            }
//    }
    UNUserNotificationCenter.current()
      .requestAuthorization(
        options: [.alert, .sound, .badge]) { [weak self] granted, _ in
        print("Permission granted: \(granted)")
        guard granted else { return }
        // 1 define actions and category
        let yesFireAction = UNNotificationAction(identifier: "FIRE", title: "It was actually on fire", options:UNNotificationActionOptions(rawValue: 0))
        let noFireAction = UNNotificationAction(identifier: "NO_FIRE", title: "No fire", options: UNNotificationActionOptions(rawValue: 0))
        let wasThereFireCategory = UNNotificationCategory(identifier: "WAS_THERE_FIRE", actions: [yesFireAction, noFireAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)

        // 3 register categories
        UNUserNotificationCenter.current().setNotificationCategories([wasThereFireCategory])

        self?.getNotificationSettings() // user can go into settings at any point and change settings
      }
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
   
  

    // get any changes in settings
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications() // will need this in the main thread - to kick off registration of APNS
        }
      }
    }
    
//    // this is called whenever register for remotenotifications() succeeds
//    func application(_ application: UIApplication,
//        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//    ) {
//      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
//      let token = tokenParts.joined()
//      print("Device Token: \(token)")
//    }
//
//    // this is called if registerForRemoteNotifications() fails (prints error)
//    func application(_ application: UIApplication,
//      didFailToRegisterForRemoteNotificationsWithError error: Error
//    ) {
//      print("Failed to register: \(error)")
//    }
//
    // handles situation where a[[ is running when push notification is recieved
    func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler:
      @escaping (UIBackgroundFetchResult) -> Void
    ) {
      guard let aps = userInfo["aps"] as? [String: AnyObject] else {
        completionHandler(.failed)
        return
      }
//      NewsItem.makeNewsItem(aps)
    }

    
    
    
    // ------------------------------------------------------------
    
    
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
