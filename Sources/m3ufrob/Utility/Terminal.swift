//
// File:         Terminal.swift
// Project:    
//
// Created by Gene De Lisa on 5/5/23
//
// Using Swift 5.0
// Running macOS 13.3
// Github: https://github.com/genedelisa/
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


import Foundation
import GDTerminalColor

struct Terminal {
    static let shared = Terminal()
    
    var infFg: XTColorNameString = .cornsilk1
    var infBg: XTColorNameString = .maroon
    var urlFg: XTColorNameString = .darkMagenta
    var urlBg: XTColorNameString = .seaGreen1
    
    func display(playlist: Playlist, path: String = "", comments: Bool = false) {
        if playlist.sortedEntries.count > 0 {
            display(entries: playlist.sortedEntries, path: path)
        } else {
            display(entries: playlist.playlistEntries, path:path)
        }
    }
    
    func display(entries: [PlaylistEntry], path: String = "", comments: Bool = false) {
        
        var s = "#EXTM3U\n"
        
        if comments {
            s += "# Source: \(path)\n"
            //s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(entries.count)\n\n"
        }
        
        for f in entries {
//            s += "\(f.originalExtinf)"
//                .fg256(infFg).bg256(infBg)
//            s += "\n"
            
            for (k,v) in f.commmands {
                s += "#\(k): "
                    .fg256(.yellow).bg256(.darkViolet)
                s += "\(v)\n"
                    .fg256(.red).bg256(.darkBlue )
            }
            
            s += "\(f.urlString)"
                .fg256(urlFg).bg256(urlBg)
            
            s += "\n\n"
        }
        print(s)
    }
    
}
