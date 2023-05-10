//
// File:         WindowCommandLogic.swift
// Project:    
//
// Created by Gene De Lisa on 5/8/23
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

class WindowCommandLogic: ObservableObject, Codable {
    
    @Published var url: URL
    
//    @Published var url: URL = URL(fileURLWithPath: ".")
    
    init(url: URL) {
        self.url = url
        print("wcl url is \(url)")
    }
    
    enum CodingKeys: String, CodingKey {
        case url
    }
    
    required convenience public init(from decoder: Decoder) throws {
        self.init(url: URL(fileURLWithPath: "."))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.url, forKey: .url)
    }
    
//    init() {
//
//    }
    
}


