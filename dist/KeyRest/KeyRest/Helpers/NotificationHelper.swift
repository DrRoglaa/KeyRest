//
//  NotificationHelper.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import Foundation
import UserNotifications

enum NotificationHelper {
    static func show(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
