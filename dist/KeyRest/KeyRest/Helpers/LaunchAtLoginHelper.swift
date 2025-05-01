//
//  LaunchAtLoginHelper.swift
//  KeyRest
//
//  Created by David Rok Roglic on 1. 5. 25.
//

import ServiceManagement

enum LaunchAtLoginHelper {
    static func setLaunchAtLogin(enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
