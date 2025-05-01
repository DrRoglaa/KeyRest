//
//  KeyRestApp.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import SwiftUI

@main
struct KeyRestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No visible settings window needed
        }
    }
}
