// File: FileServiceTests.swift
// Project: 
// Package: 
// Product:  
// https://github.com/genedelisa/
// ~/Library/Developer/Xcode/UserDataIDETemplateMacros.plist
//
// Created by Gene De Lisa on 2/2/24
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
@testable import m3ufrob

final class FileServiceTests: XCTestCase {

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func testMetaFrob() async throws {
        let sut = FileService.shared
        
        //let expect = expectation(description: "Play")

        let expect = expectation(forNotification: .NSMetadataQueryDidFinishGathering, 
                                 object: nil, handler: nil)
        sut.metaFrob()
        await fulfillment(of: [expect])
//        await waitForExpectations(timeout: 10, handler: nil)


    }
    
    func testMetaFrob2() throws {
        let sut = FileService.shared

        let expect = expectation(forNotification: .NSMetadataQueryDidFinishGathering,
                                 object: nil, handler: nil)
        sut.metaFrob()

        waitForExpectations(timeout: 10, handler: nil)


    }


}
