//
//  AppDelegate.swift
//  macOS Utilities: Hypervisor
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let sharedOverlayLogger = XLOverlayLog.shared

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        XLSharedFacility.addLogger(sharedOverlayLogger)
        XLSharedFacility.minLogLevel = .logLevel_Verbose
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    @IBAction func toggleLog(_ sender: NSMenuItem) {
        if !sharedOverlayLogger.isHidden {
            sharedOverlayLogger.hide()
            sender.title = "Show Log Overlay"
        } else {
            sharedOverlayLogger.show()
            sender.title = "Hide Log Overlay"
        }
    }

}
