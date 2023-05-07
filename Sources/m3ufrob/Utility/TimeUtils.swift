//
// File:         File.swift
// Project:    
// Package: 
// Product:  
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

struct TimeUtils {
    
    //full = "2 hours, 46 minutes, 49 seconds"
    //positional = "2:46:40"
    //abbreviated = "2h 46m 40s"
    //spellOut = "two hours, forty-six minutes, forty seconds”
    //short = "2hr,46 min,40 sec"
    //brief = "2hr 46min 40sec"
    static func secondsToHMS(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        let formattedString = formatter.string(from: TimeInterval(seconds))!
        return formattedString
    }
}
