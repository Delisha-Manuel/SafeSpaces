import SwiftUI
import AWSSNS
import UserNotifications
import Foundation
import UIKit

@main
struct SafeSpacesApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {

    // The SNS Platform application ARN
    let SNSPlatformApplicationArn = "arn:aws:sns:us-east-2:116981808496:app/APNS_SANDBOX/SafeSpaces"
    let CognitoIdentityPoolID = "us-east-2:5f52431d-05d0-43a7-9051-606675c29fcf"

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("DEBUG: Inside didFinishLaunchingWithOptions")
        
        // Setup AWS Cognito credentials
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AWSRegionType.USEast2, identityPoolId: CognitoIdentityPoolID)

        let defaultServiceConfiguration = AWSServiceConfiguration(
            region: AWSRegionType.USEast2, credentialsProvider: credentialsProvider)

        AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration

        registerForPushNotifications(application: application)
        
        return true
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("INFO: Inside didRegisterForRemoteNotificationsWithDeviceToken")
        
        if AppData.data.me.deviceName != "" || AppData.data.me.phone == "" {
            return
        }
        
        Task {
            // Attach the device token to the user defaults
            var token = ""
            for i in 0..<deviceToken.count {
                token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
            }
            
            print("Device token: \(token)")
            
            // Create a platform endpoint. In this case,  the endpoint is a device endpoint ARN
            let sns = AWSSNS.default()
            let request = AWSSNSCreatePlatformEndpointInput()
            request?.token = token
            request?.platformApplicationArn = SNSPlatformApplicationArn
            request?.customUserData = AppData.data.me.phone
            sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
                if task.error != nil {
                    print("Error createPlatformEndpoint: \(String(describing: task.error))")
                } else {
                    let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                    
                    if let endpointArnForSNS = createEndpointResponse.endpointArn {
                        print("endpointArn: \(endpointArnForSNS)")
                        AppData.data.me.deviceName = endpointArnForSNS
                    }
                }
                return nil
            })
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("ERROR: didFailToRegisterForRemoteNotificationsWithError")
        print(error.localizedDescription)
    }

    func registerForPushNotifications(application: UIApplication) {
        // The notifications settings
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }

    // Called when a notification is delivered to a foreground app.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("DEBUG: willPresent notification: User Info = ",notification.request.content.userInfo)
        completionHandler([.list, .banner, .badge, .sound])
    }

    // Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("DEBUG: AppDelegate.didReceive \(response)")
        print("DEBUG: Action selected by user. User Info = ",response.notification.request.content.userInfo)

        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("DEBUG: Received SNS notification: \(userInfo)")
        // Parse the userInfo dictionary to extract data from the SNS payload
        if let customData = userInfo["customData"] as? String {
            // Process custom data based on your application logic
            print("Received SNS notification: \(customData)")
            completionHandler(UIBackgroundFetchResult.noData)
        }
    }

}

