// File: URL+PosixError.swift
// Project:
// https://github.com/genedelisa/
// ~/Library/Developer/Xcode/UserDataIDETemplateMacros.plist
//
// Created by Gene De Lisa on 9/22/23
//
// Copyright © 2023 Rockhopper Technologies, Inc. All rights reserved.
// Licensed under the MIT License (the "License");
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
// https://opensource.org/licenses/MIT
//
// Follow me on Twitter: @GeneDeLisaDev


import Foundation

extension URL {
    public static func posixError(_ err: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain,
                code: Int(err),
                userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}
