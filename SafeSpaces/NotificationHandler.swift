import Foundation
import UserNotifications
import UIKit
import SwiftUI
import AWSSNS

class NotificationHandler: ObservableObject {
    static let shared = NotificationHandler()
    @Published var notifications: [Notification] = []
    
    static func askPermission () {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
            if (granted)
            {
                print("DEBUG: Registering for remote notifications.")
                DispatchQueue.main.async(execute: UIApplication.shared.registerForRemoteNotifications)
            }
            else {
            }
        })
    }
    
    static func sendNotification(title: String, body: String) {
        print("DEBUG: sendNotification Called")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        DispatchQueue.main.async {
            let notification = Notification(title: title, body: body, timestamp: Date())
            NotificationHandler.shared.notifications.append(notification)
        }
        
        UNUserNotificationCenter.current().add(request) { error in
                                                             if let error = error {
                                                                 print("Error adding notification: \(error)")
                                                             } else {
                                                                 print("Notification scheduled: \(title)")
                                                             }
                                                        }
    }
    
    static func sendRemoteNotification(guardian: Person, title: String, body: String) {
        Task {
                        
            if guardian.deviceName == "" {
                guardian.deviceName = await getDeviceIdentifier(phoneNumber: guardian.phone)
            }
            
            let sns = AWSSNS.default()
            print("DEBUG: SNS configuration \(sns.configuration)")
            let request = AWSSNSPublishInput()
            
            request?.messageStructure = "json"
            
            // The payload
            let dict = ["default": "\(body)", "APNS_SANDBOX": "{\"aps\":{\"alert\": {\"title\":\"\(title)\",\"body\":\"\(body)\"},\"sound\":\"default\",\"badge\":1} }"]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
                request?.message = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String
                request?.targetArn = guardian.deviceName
                
                print("DEBUG: Sending remote notification \(request!)")
                let response = try await sns.publish(request!)
                print("DEBUG: Remote notification response: \(response)")
            } catch {
                print(error)
            }
        }
    }

    // Get the deviceArn for the given phone number
    static func getDeviceIdentifier(phoneNumber: String) async -> String {
        print("Entered getDeviceIdentifier(\(phoneNumber))")
        if phoneNumber == "" {
            return ""
        }
        
        let SNSPlatformApplicationArn = "arn:aws:sns:us-east-2:116981808496:app/APNS_SANDBOX/SafeSpaces"
        let sns = AWSSNS.default()
        let request = AWSSNSListEndpointsByPlatformApplicationInput()
        request!.platformApplicationArn = SNSPlatformApplicationArn
        print("DEBUG: Get platform endpoints \(request!)")
        do {
            let response = try await sns.listEndpoints(byPlatformApplication: request!)
            print("DEBUG: List of endpoints: \(response)")
            if let endpoints = response.endpoints {
                for endpoint in endpoints {
                    if endpoint.attributes?["Enabled"] ?? "false" == "false" {
                        continue
                    }
                    if let phone = endpoint.attributes?["CustomUserData"] {
                        if phone == phoneNumber {
                            return endpoint.endpointArn ?? ""
                        }
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }
        return ""
    }
}
