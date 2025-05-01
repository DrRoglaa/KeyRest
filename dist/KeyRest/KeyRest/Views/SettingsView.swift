//
//  SettingsView.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("LockDuration", store: .standard) var lockDuration: Int = 30
    @AppStorage("SoundEnabled", store: .standard) var soundEnabled: Bool = true
    @AppStorage("LaunchAtLogin", store: .standard) var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Lock Duration (seconds):")
                    TextField("Duration", value: $lockDuration, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Enable Sounds", isOn: $soundEnabled)

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        LaunchAtLoginHelper.setLaunchAtLogin(enabled: launchAtLogin)
                    }
            }

            Section {
                Button("🔒 Lock Now") {
                    AppDelegate.shared?.lockKeyboard()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 300)
        .padding()
    }
}
