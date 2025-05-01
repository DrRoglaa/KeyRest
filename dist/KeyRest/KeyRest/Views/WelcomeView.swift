//
//  WelcomeView.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var dismissed = false

    var body: some View {
        VStack(spacing: 20) {
            Text("👋 Welcome to KeyRest")
                .font(.largeTitle)
                .bold()

            Text("""
            KeyRest lets you safely clean your keyboard by locking all keys temporarily.

            Use the Menu Bar or press Cmd + Option + L to lock anytime.

            Don't forget to grant Accessibility permissions when asked!
            """)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                dismissed = true
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)

        }
        .padding()
        .frame(width: 400, height: 350)
        .opacity(dismissed ? 0 : 1)
        .animation(.easeInOut, value: dismissed)
    }
}
