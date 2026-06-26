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
import RegexBuilder

struct PlaylistParser {
    // used in tests
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
        var comments = [String]()
        
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
                    
                    
                    //TODO: handle properties too
                    //#EXTINF:-1 tvg-id="Channel1" tvg-name="Channel 1" tvg-language="English" group-title="News" custom-attribute="hello",Channel 1

                    
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
                
                else {
                    Logger.playlist.debug("Plain comment: \(line, privacy: .public)")
                    comments.append(line)
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
        /(?<cmd>#EXTINF:)?[[:space:]]*(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,+\s*(?<title>.*)/
        
        // tes - is to allow tg-foo names.
        let nameValuePairRegexp = /(?<nv>[[:alnum:]-]*)/
        
        
        //        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,\s*(?<title>.*)/

        // TODO: this is a mess too
        if line.contains("EXTINF") {
            
//            if let pe = parseEXTINFLine(line) {
//                print("\(pe)")
//            }
//            
//            
//            do {
//                if nameValuePairRegexp.contains(captureNamed: "nv") {
//                    print("has nv")
//                }
//                if let result = try nameValuePairRegexp.wholeMatch(in: line) {
//                    print("pair result: \(result)")
//                } else {
//                    print("no pair result: \(line)")
//                }
//            } catch {
//                print("no regexp match for:")
//                print("\(line)\n")
//                print("\(error)\n")
//            }



            
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
    
    
    /// Parses a single #EXTINF line using Swift 5.7 Regex literals (no DSL) to extract duration, title, and optional properties.
    private func parseEXTINFLine(_ line: String) -> PlaylistEntry? {
        let prefix = "#EXTINF:"
        guard line.hasPrefix(prefix) else { return nil }
        let rest = line.dropFirst(prefix.count)

        // Find first comma not inside quotes
        guard let commaIndex = indexOfUnquotedComma(in: rest) else { return nil }

        let leftPart = rest[..<commaIndex].trimmingCharacters(in: .whitespaces)
        let title = rest[rest.index(after: commaIndex)...].trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }

        
        //TODO: fix this regexp mess
        
        // Regex pattern string (no DSL):
        // For entire leftPart: ^(-?\d+(?:\.\d+)?)(?:\s+(.*))?$
        
        // raw Swing string
        //let pattern = #"^(-?\d+(?:\.\d+)?)(?:\s+(.*))?$"#
        let pattern = #"^(-?\d+(\.\d+)?)(\s+(.*))?$"#
        
        let durPattern = #"(?<dur>[+-]?[[:space:]*[:digit:]\.]*)"#
        let nvPattern = #"(?<name>[a-zA-Z0-9-]+)="(?<val>[^"]*)"#

//        let regex:Regex<(Substring, Substring, Substring?, Substring?, Substring?)>
        let regex:Regex<(Substring, dur:Substring)>
//        let regex:Regex<(Substring, Substring?)>
        do {
//            try regex = Regex<(Substring, Substring?)>(pattern)
            try regex = Regex<(Substring,  dur:Substring)>(durPattern)
//            try regex = Regex<(Substring, Substring ,Substring?, Substring?, Substring?)>(durPattern)
//            try regex = Regex<(Substring, Substring ,Substring?, Substring?, Substring?)>(pattern)
        } catch  {
            print("Invalid regex \(pattern)")
            print(" \(error)")
            return nil
        }

//        guard let regex = try? Regex<(Substring, Substring?)>(pattern) else {
//            print("Invalid regex \(pattern)")
//            return nil
//        }
        guard let match = leftPart.wholeMatch(of: durPattern) else {
            print("no match for regex")
            print("\(regex) with \(line)")
            return nil
        }
        
//        guard let match = leftPart.wholeMatch(of: regex) else {
//            print("no match for regex")
//            print("\(regex) with \(line)")
//            return nil
//        }

        // match.output is a tuple containing capture groups (duration, optional properties)
//        let durationStr = String(match.output.0)
//        guard let duration = Double(durationStr) else { return nil }
let duration = Double(0)
//        let propertiesString = match.output.1 ?? ""
//
//        // Parse all key="value" pairs in propertiesString using regex
//        // pattern: ([a-zA-Z0-9-]+)="([^"]*)"
//        let kvRegex = try! Regex<(Substring, Substring)>(#"([a-zA-Z0-9-]+)="([^"]*)""#)

        // (?<name>[a-zA-Z0-9-]+)="(?<val>[^"]*)"

        var properties: [String: String] = [:]
//        for match in propertiesString.matches(of: kvRegex) {
//            let key = String(match.output.0)
//            let value = String(match.output.1)
//            properties[key] = value
//        }

        return PlaylistEntry(title: String(title), duration: duration, properties: properties)
    }



    // Finds first comma not inside double quotes
    private func indexOfUnquotedComma(in substring: Substring) -> Substring.Index? {
        var insideQuotes = false
        for (idx, char) in substring.enumerated() {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                return substring.index(substring.startIndex, offsetBy: idx)
            }
        }
        return nil
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
