// File: PlaylistParserTests.swift
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


import XCTest
import class Foundation.Bundle
@testable import m3ufrob

final class PlaylistParserTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        let m3u8 = """
#EXTM3U

#EXTINF:1.0,the title
https://www.foo.com/videos/311422/thing.foo

#EXTINF:1.0,another
https://www.foo.com/videos/536102/thing.foo

#EXTIMG: https://foo.com/a//549/949/v2/526x298.213.webp
#EXTINF:1.0,image info
https://foo.com/wp-content/uploads/2018/09/Thing.foo
"""
        
        let parser = PlaylistParser()
        let lines  = m3u8.components(separatedBy: .newlines)
        let entries = parser.parse(lines)
        print("\(entries.count) entries\n")
        XCTAssertEqual(entries.count, 3, "there are the proper number of entries")

        var e = entries[0]
        XCTAssertEqual(e.title, "the title", "the title is correct")
        XCTAssertEqual(e.duration, 1.0, accuracy: 0.1, "the duration is correct")
        XCTAssertEqual(e.urlString, "https://www.foo.com/videos/311422/thing.foo", "the url is correct")

        e = entries[1]
        XCTAssertEqual(e.title, "another", "the title is correct")
        XCTAssertEqual(e.duration, 1.0, accuracy: 0.1, "the duration is correct")
        XCTAssertEqual(e.urlString, "https://www.foo.com/videos/536102/thing.foo", "the url is correct")

        e = entries[2]
        XCTAssertEqual(e.title, "image info", "image info")
        XCTAssertEqual(e.duration, 1.0, accuracy: 0.1, "the duration is correct")
        XCTAssertEqual(e.urlString, "https://foo.com/wp-content/uploads/2018/09/Thing.foo", "the url is correct")
        XCTAssertEqual(e.extImgURLString, "https://foo.com/a//549/949/v2/526x298.213.webp", "the img url is correct")



        for entry in entries {
            print("\(entry)\n")
        }
        
        print("here they are")
        parser.display(entries: entries)

        
        
    }
    
    
}
