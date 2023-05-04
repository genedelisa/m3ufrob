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



import Foundation
import os.log

enum CommandError: Swift.Error {
    case helpFileNotFound
}

extension CommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .helpFileNotFound:
            return NSLocalizedString("Could not find the help file",
                                     comment: "")
        }
    }

    public var failureReason: String? {
        switch self {
        case .helpFileNotFound:
            return NSLocalizedString("The help file could not be read.",
                                     comment: "")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .helpFileNotFound:
            return NSLocalizedString("Does the help file exist? Is it in the Resources folder?",
                                     comment: "")
        }
    }
}

extension CommandError: Equatable {
    public static func == (lhs: CommandError, rhs: CommandError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
