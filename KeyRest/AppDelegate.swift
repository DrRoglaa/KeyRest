//
//  AppDelegate.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import Cocoa
import SwiftUI
import ApplicationServices
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {

    static var shared: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    var statusItem: NSStatusItem!
    var eventTap: CFMachPort?
    var unlockTimer: Timer?
    var countdownTimer: Timer?
    var permissionCheckTimer: Timer?
    var settingsWindow: NSWindow?
    var permissionStatusItem: NSMenuItem?
    
    var remainingSeconds: Int = 0

    @AppStorage("LockDuration") var lockDuration: Int = 30
    @AppStorage("SoundEnabled") var soundEnabled: Bool = true
    @AppStorage("LaunchAtLogin") var launchAtLogin: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            showWelcomeScreen()
        }
        
        requestAccessibilityPermissionsIfNeeded()
        setupMenu()
        setupHotkeyListener()
        startPermissionMonitoring()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🔓 KeyRest"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Lock Keyboard", action: #selector(lockKeyboard), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Unlock Keyboard", action: #selector(unlockKeyboard), keyEquivalent: "u"))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        permissionStatusItem = NSMenuItem(title: "Accessibility: Checking...", action: nil, keyEquivalent: "")
        menu.addItem(permissionStatusItem!)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func lockKeyboard() {
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            showAccessibilityAlert()
            return
        }

        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: CGEventMask(eventMask),
                                     callback: { _, _, _, _ in nil },
                                     userInfo: nil)

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }

        remainingSeconds = lockDuration
        unlockTimer?.invalidate()
        unlockTimer = Timer.scheduledTimer(timeInterval: TimeInterval(lockDuration),
                                           target: self,
                                           selector: #selector(unlockKeyboard),
                                           userInfo: nil,
                                           repeats: false)

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                              target: self,
                                              selector: #selector(updateCountdown),
                                              userInfo: nil,
                                              repeats: true)

        if soundEnabled {
            NSSound(named: "Submarine")?.play()
        }
        NotificationHelper.show(title: "Keyboard Locked", body: "KeyRest is active for \(lockDuration) seconds.")
        updateMenuBarIcon(locked: true)
    }

    @objc func unlockKeyboard() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }

        unlockTimer?.invalidate()
        countdownTimer?.invalidate()

        if soundEnabled {
            NSSound(named: "Glass")?.play()
        }
        NotificationHelper.show(title: "Keyboard Unlocked", body: "KeyRest is now disabled.")
        updateMenuBarIcon(locked: false)
    }

    @objc func updateCountdown() {
        remainingSeconds -= 1
        if remainingSeconds > 0 {
            if let button = statusItem.button {
                button.title = "🔒 \(remainingSeconds)s"
            }
        }
    }

    func updateMenuBarIcon(locked: Bool) {
        DispatchQueue.main.async {
            guard let button = self.statusItem.button else { return }
            
            let systemName = locked ? "lock.fill" : "lock.open.fill"
            let toolTipText = locked ? "KeyRest — Keyboard Locked" : "KeyRest — Keyboard Unlocked"
            
            if let newImage = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) {
                newImage.isTemplate = true
                
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    button.animator().alphaValue = 0.0
                } completionHandler: {
                    button.image = newImage
                    button.imagePosition = .imageOnly
                    button.toolTip = toolTipText // 👈 Set the tooltip here
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.2
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        button.animator().alphaValue = 1.0
                    }
                }
            }
        }
    }
    func startPermissionMonitoring() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let accessEnabled = AXIsProcessTrusted()
            self.updatePermissionStatusInMenu()

            if !accessEnabled {
                self.showAccessibilityAlert()
            }
        }
    }

    func updatePermissionStatusInMenu() {
        let accessEnabled = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.permissionStatusItem?.title = accessEnabled ? "Accessibility: ✅" : "Accessibility: ❌"
        }
    }

    func requestAccessibilityPermissionsIfNeeded() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            showAccessibilityAlert()
        }
    }

    func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Needed"
            alert.informativeText = "Please enable KeyRest in System Settings → Privacy & Security → Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    @objc func openPreferences() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
                                      styleMask: [.titled, .closable],
                                      backing: .buffered,
                                      defer: false)
            settingsWindow?.center()
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.title = "KeyRest Preferences"
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showWelcomeScreen() {
        let welcomeView = WelcomeView()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.center()
        window.contentView = NSHostingView(rootView: welcomeView)
        window.title = "Welcome to KeyRest"
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupHotkeyListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .option]),
                  event.charactersIgnoringModifiers?.lowercased() == "l" else { return }
            self?.lockKeyboard()
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
