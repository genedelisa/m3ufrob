// File:    FileHandle+Raw.swift
// Package: GDCliFrobs
//
// Created by Gene De Lisa on 5/27/21
//
// Using Swift 5.0
// Running macOS 11.4
// Github: https://github.com/genedelisa/toolfrobs
// Product: https://rockhoppertech.com/
//
// Copyright © 2021 Rockhopper Technologies, Inc. All rights reserved.
//
// Licensed under the MIT License (the "License");
//
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// https://opensource.org/licenses/MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS O//R
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



import Foundation


extension FileHandle {
    
    public func enableRawMode() -> termios {
        var raw = termios()
        
        if (tcgetattr(self.fileDescriptor, &raw) != 0) {
            perror("tcgetattr() error for initial terminal settings")
        }
        
        let original = raw
        raw.c_lflag &= ~UInt(ECHO | ICANON)
        
        // TCSANOW, the change shall occur immediately.
        // TCSADRAIN, the change shall occur after all output written to fildes
        if (tcsetattr(self.fileDescriptor, TCSANOW, &raw) != 0) {
            perror("tcsetattr() error applying raw settings");
        }
        return original
    }
    
    public func restoreRawMode(originalTerm: termios) {
        var term = originalTerm
        if (tcsetattr(self.fileDescriptor, TCSANOW, &term) != 0) {
            perror("tcsetattr() error restoring terminal");
        }
        
    }
}

public func getch() -> UInt8 {
    let handle = FileHandle.standardInput
    let term = handle.enableRawMode()
    defer { handle.restoreRawMode(originalTerm: term) }
    
    var byte: UInt8 = .zero
    if (read(handle.fileDescriptor, &byte, 1) < 0) {
        perror("read()")
    }
    return byte
}



//func append(_ text: String, to fileURL: URL) {
//    guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else {
//        stderr.write("Cannot open file \(fileURL).")
//    }
//    fileHandle.seekToEndOfFile()
//    fileHandle.write(text.data(using: .utf8)!)
//    fileHandle.closeFile()
//}
