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
import SwiftUI

@available(macOS 10.15, *)
struct DirView: View {
    
    @State var url: URL?

//    var windowCommandLogic:  WindowCommandLogic
//    init(windowCommandLogic: WindowCommandLogic) {
//        self.windowCommandLogic = windowCommandLogic
//    }
    
    var info: InfoClass
    init(info: InfoClass) {
        self.info = info
    }

    var body: some View {
        
        VStack(spacing: 25) {
            
            Spacer()
            
            Text("Directory", comment: "Header label for directory in DirView")
                .font(.headline)
            
            Text("Your playlists", comment: "Subheadline in Dirview")
                .font(.subheadline)
            
            if let u = self.url {
                Text("\(u.absoluteString)", comment: "file name. not to be translated")
                    .font(.title)
            }
            
            Divider()
            
            Button {
                showChooseFileDialog(title: "Choose Directory")
            } label: {
                Label(String(localized: "Choose", comment:"Prompt to choose a folder"),
                      systemImage: "folder")
            }
            .padding()
            
            Spacer()
            
            
        }
    }
    
    
    
    func showChooseFileDialog(title: String) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.title = title
        
        openPanel.begin { (result) -> Void in
            //            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
            if result == .OK {
                if let u = openPanel.url {
                    self.url = u
                    self.info.url = u

                    Task {
                        await self.info.show(merge: false, filename: "thing" )
                    }

                    
//                    self.windowCommandLogic.url = u

                    if let keyWindow = NSApplication.shared.keyWindow {
                        print("closing key window \(keyWindow)")
                        keyWindow.close()
                    }
                    // this is usually the one that is set
                    if let first = NSApp.windows.first {
                        print("closing first window \(first)")
                        first.close()
                    }
                }
            }
        }
    }
    
    
}
