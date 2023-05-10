//
// File:         Sources
// Project:    m3ufrob
// Package: m3ufrob
// Product:  
//
// Created by Gene De Lisa on 5/4/23
//
// Using Swift 5.0
// Running macOS 13.3
// Github: https://github.com/genedelisa/m3ufrob
// Product: https://rockhoppertech.com/
//
// Follow me on Twitter: @GeneDeLisaDev
//
// Licensed under the MIT License (the "License");
//
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// https://opensource.org/licenses/MIT

import os.log
import OSLog

import AppKit
import SwiftUI


@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    var windowDelegate = WindowDelegate()
    
    var info: InfoClass

    init(info: InfoClass) {
        self.info = info
    }
    
//    var windowCommandLogic:  WindowCommandLogic
//    init(windowCommandLogic: WindowCommandLogic) {
//        self.windowCommandLogic = windowCommandLogic
//    }
    

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Menu setup

        // Only one item!
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit",
                                            action: #selector(NSApplication.terminate(_:)),
                                            keyEquivalent: "q"))

        let mainMenu = NSMenu(title: "Playlists")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu
        
       
        

        // Window setup
        let size = CGSize(width: 480, height: 270)
        window.setContentSize(size)
        window.styleMask = [.closable, .miniaturizable, .resizable, .titled, .fullSizeContentView]
        window.delegate = windowDelegate
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backingType = .buffered
        window.titlebarAppearsTransparent = true
        window.title = "Playlists"
        
        
        //        window.backgroundColor = NSColor(calibratedHue: 0,
        //                                            saturation: 1.0,
        //                                            brightness: 0,
        //                                            alpha: 0.7)

        // Now add the SwiftUI View
//        let view = NSHostingView(rootView: DirView(windowCommandLogic: windowCommandLogic))
        
//        var group = WindowGroup() {
//            Text("hey")
//            Text("You")
//            DirView(info: info)
//        }
//        let view = NSHostingView(rootView: group)
        
        let view = NSHostingView(rootView: DirView(info: info))
        view.frame = CGRect(origin: .zero, size: size)
        view.autoresizingMask = [.height, .width]
        
        window.contentView!.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(window)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
       // window.close()
    }
}

// func showWindow(dInfo: InfoClass) {
//     let app = NSApplication.shared
//     let delegate = AppDelegate(info: dInfo)
//     app.delegate = delegate
//     app.run()
// }
