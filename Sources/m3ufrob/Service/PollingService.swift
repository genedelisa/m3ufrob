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
import Combine
import os.log
import OSLog

class PollingService: Decodable {
    
    var subscription: AnyCancellable?
    
    var interval: TimeInterval = 1.0
    
    //let dateFormatter = ISO8601DateFormatter()
    let dateFormatter: DateFormatter = {
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .medium
        dateFormat.timeStyle = .medium
        dateFormat.timeZone = TimeZone.current
        return dateFormat
    }()
    
    enum CodingKeys: String, CodingKey {
        case interval
    }
    
    init() {
        Logger.service.info("\(#function)")
        self.interval = 1.0
    }
    
    init(interval: TimeInterval = 1.0) {
        Logger.service.info("\(#function)")
        self.interval = interval
    }
    
    required convenience public init(from decoder: Decoder) throws {
        Logger.service.info("\(#function)")
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.interval = try container.decode(TimeInterval.self, forKey: .interval)
    }
    
    func poll()  {
        Logger.service.info("\(#function)")
        print("Polling")
        
        subscription = Timer
            .publish(every: self.interval, on: .current, in: .default)
            .autoconnect()
            .sink { date in
                self.doTheThing(date: date)
            }
        
        withExtendedLifetime(subscription) {
            RunLoop.current.run()
        }
    }
    
    func doTheThing(date: Date) {
        Logger.service.info("\(#function)")
        
        let ts = dateFormatter.string(from: date)
        print("Now: \(ts)\n")
    }
    
}


