// File: File.swift
// Project:
// Package:
// Product:
// https://github.com/genedelisa/
// ~/Library/Developer/Xcode/UserDataIDETemplateMacros.plist
//
// Created by Gene De Lisa on 2/21/24
//
// Copyright © 2024 Rockhopper Technologies, Inc. All rights reserved.
// Licensed under the MIT License (the "License");
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
// https://opensource.org/licenses/MIT
//
// Follow me on Twitter: @GeneDeLisaDev


import Foundation
import os.log

struct PlaylistParser {
    
    func display(entries: [PlaylistEntry]) {
        let s = createContentString(entries: entries)
        print(s)
    }

    func createContentString(entries: [PlaylistEntry]) -> String {
        
        var s = ""
        for entry in entries {
            for (k,v) in entry.commmands {
                if k == "#EXTINF:" {
//                    s += entry.extInf
                    s += "#EXTINF:\(entry.duration),\(entry.title)\n"
                } else {
                    s += "\(k)"
                    s += "\(v)\n"
//                    s += "#EXTIMG:\(entry.extImgURLString)\n"
                }
            }
            s += "\(entry.urlString)\n\n"
        }
        return s
    }
    
    func parse(_ lines: [String]) -> [PlaylistEntry] {
//    func c -> [PlaylistEntry] {
        Logger.playlist.trace("\(#function)")
        
        enum ParseState {
            case begin, hasExtInf, hasURL
        }
        var parseState: ParseState = .begin
        
        var results = [PlaylistEntry]()
        
        var entry = PlaylistEntry()
        
        for var line in lines {
            line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if line.isEmpty {
                continue
            }
            
            // the "header"
            if line.hasPrefix("#EXTM3U") {
                continue
            }
            
            if parseState == .begin {
                entry = PlaylistEntry()
                //results.append(entry)
            }
            
            if line.hasPrefix("#") {
                Logger.playlist.debug("# \(line, privacy: .public)")
                
                if line.hasPrefix("#EXTIMG") {
                    let tup = try! parseImgCmdLine(line)
                    Logger.playlist.debug("cmd \(tup.cmd, privacy: .public)")
                    Logger.playlist.debug("val \(tup.val, privacy: .public)")
                    
                    entry.commmands[tup.cmd] = tup.val
                    entry.extImgURLString = tup.val
                    entry.originalExtinf = line
                    parseState = .hasExtInf
                    
                }
                //                else if line.hasPrefix("#EXTIMG") {
                //                    Logger.playlist.debug("EXTIMG: \(line, privacy: .public)")
                //
                //                    //                    let imgURLString = line.replacingOccurrences(of: extImgRegexp,
                //                    //                                                                 with: "$2",
                //                    //                                                                 options: .regularExpression,
                //                    //                                                                 range: nil)
                //                    //                    //print("imgURLString: \(imgURLString)")
                //                    entry.extImgURLString = imgURLString
                //
                //
                //                    // keep going
                //                    parseState = .hasExtInf
                //
                //                }
                
                else if line.hasPrefix("#EXTINF") {
                    
                    do {
                        let tup = try parseCmdLine(line)
                        Logger.playlist.debug("cmd: \(tup.cmd, privacy: .public)")
                        Logger.playlist.debug("dur: \(tup.dur, privacy: .public)")
                        Logger.playlist.debug("title: \(tup.title, privacy: .public)")
                        
                        entry.originalExtinf = line
                        entry.title = tup.title
                        entry.duration = tup.dur
                        entry.commmands[tup.cmd] = "\(tup.dur),\(tup.title)"
                        
                        parseState = .hasExtInf
                        
                        
                    } catch PlaylistError.badInput {
                        print("Bad Input Error with #EXTINF line:\n\(line)") //\(PlaylistError.badInput.localizedDescription)")
                        entry.originalExtinf = "#EXTINF:0,Unknown"
                        entry.title = "badInput"
                        entry.duration = 0
                        entry.commmands["#EXTINF:"] = "0,\(entry.urlString)"
                        parseState = .hasExtInf

                    } catch {
                        print("\(error.localizedDescription)")
                    }
                }
                
                //                else if line.hasPrefix("http") {
                //                    Logger.playlist.debug("http line: \(line, privacy: .public)")
                //                    entry.urlString = line
                ////                    results.append(entry)
                //
                //                    // the url is the terminal state.
                //                    // this resets and creates a new entry
                //                    parseState = .begin
                //
                //                }
                
                
                
                else if line.hasPrefix("#EXTGRP") {
                    Logger.playlist.debug("EXTGRP line: \(line, privacy: .public)")
                    parseState = .hasExtInf
                    
                }
                
                
                
            } // has prefix
            
            
            else if line.hasPrefix("http") {
                // doesn't have prefix #EXT i.e. the url
                Logger.playlist.debug("non #EXT line: \(line, privacy: .public)")
                // print("non #EXT line: \(line)")
                
                entry.urlString = line
                if entry.title == "badInput" {
                    let url = URL(string: entry.urlString)!
                    entry.title = "\(url.lastPathComponent)"
                    //x "\(entry.urlString)"
                }

                results.append(entry)
                
                // reset
                parseState = .begin
            }
            
            else {
                // doesn't have prefix #EXT i.e. the url
                Logger.playlist.debug("non #EXT line: \(line, privacy: .public)")
                print("non #EXT line: \(line)")
                // reset
                parseState = .begin
            }
            
        } // for
        
        return results
    } // parse
    
    func parseCmdLine(_ line: String) throws -> (cmd: String, dur:Double, title: String) {
        
        let regexp =
        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,\s*(?<title>.*)/
        
        if line.contains("EXTINF") {
            do {
                
                // if let result = try regexp.wholeMatch(in: line.dropFirst()) {
                if let result = try regexp.wholeMatch(in: line) {
                    //                    print("Cmd: \(result.cmd)")
                    //                    print("Dur: \(result.dur)")
                    //                    print("Title: \(result.title)")
                    if let d = Double(result.dur),
                       let cmd=result.cmd {
                        //print("returning \(cmd) \(d) \(result.title)")
                        return (String(cmd), d, String(result.title) )
                    }
                    throw PlaylistError.badInput(message: "cannot parse:\(line)")
                } else {
                    //print("no regexp match for:")
                    print("\(line)\n")
                    //print("\(regexp)\n")
                }
            } catch {
                print("\(error.localizedDescription)")
                throw error
            }
            throw PlaylistError.badInput(message: "Shouldn't get here")
        }
        throw PlaylistError.badInput(message: "Shouldn't get here")
        
        
        //        if line.contains("EXTIMG") {
        //            print("Why am I getting an image?")
        //            print("\(line)")
        //        }
        
        
        
    }
    
    func parseImgCmdLine(_ line: String) throws -> (cmd: String, val: String) {

        let imgRegexp = /(?<cmd>#EXTIMG:)?\s*(?<title>.*)/
        do {
            if let result = try imgRegexp.wholeMatch(in: line) {
                if let cmd = result.cmd {
                    return (String(cmd), String(result.title) )
                }
            }
            throw PlaylistError.badInput(message: "cannot parse:\(line)")
        } catch {
            print("\(error.localizedDescription)")
            throw error
        }
//
//
//        
//        let regexp = #"(#EXTIMG):\s*(.*)"#
//        
//        let cmd = line.replacingOccurrences(
//            of: regexp,
//            with: "$1",
//            options: .regularExpression,
//            range: nil)
//
//        let value = line.replacingOccurrences(
//            of: regexp,
//            with: "$2",
//            options: .regularExpression,
//            range: nil)
//        Logger.playlist.debug("cmd: \(cmd, privacy: .public)")
//        Logger.playlist.debug("value: \(value, privacy: .public)")
//
//        return(cmd, value)
    }

}
