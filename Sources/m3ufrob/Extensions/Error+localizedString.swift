//
// File:         File.swift
// Project:    
// Package: 
// Product:  
//
// Created by Gene De Lisa on 5/11/23
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

extension Swift.Error {
    
    func localizedString(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
        let template = NSLocalizedString(key, bundle: Bundle.module, comment: comment)
        return String(format: template, arguments: arguments)
    }
    
}
