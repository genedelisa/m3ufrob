// File:    PlaylistEntry.swift
// Project: 
//
// Created by Gene De Lisa on 10/25/21
//
// Using Swift 5.0
// Running macOS 11.6
// Github: https://github.com/genedelisa/PlaylistFrob
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



import SwiftUI
import Combine
import os.log
import UniformTypeIdentifiers

public class PlaylistEntry: NSObject, ObservableObject, Identifiable {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PlaylistEntry")
    
    public var id: UUID = UUID()
    public var title: String = ""
    public var duration: Double = 0.0
    public var urlString: String = ""
    public var originalExtinf: String = ""
    
    public init(title: String, duration: Double, urlString: String) {
        self.title = title
        self.duration = duration
        self.urlString = urlString
        super.init()
    }
    public override init() {
        super.init()
    }
    
    required public init(from: Decoder) {
        super.init()
    }
    
    // NSObject declares the protocols Equatable, CustomStringConvertible, and Hashable
    public static func == (lhs: PlaylistEntry, rhs: PlaylistEntry) -> Bool {
        lhs.urlString == rhs.urlString &&
        lhs.title == rhs.title
    }
    
    public override var description: String {
        var s = "\(type(of: self))\n"
        s += "title: \(title)\n"
        s += "duration: \(duration)\n"
        s += "urlString: \(urlString)\n"
        s += "originalExtinf: \(originalExtinf)\n"
        return s
    }
    

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.title)
        hasher.combine(self.urlString)
        return hasher.finalize()
//        return Int(self.id.uuidString)!
    }
    
//        public override func hash(into hasher: inout Hasher) {
//            hasher.combine(self.title)
//            hasher.combine(self.urlString)
//        }


    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? PlaylistEntry {
            //print("isEqual \(urlString)")
            return self.urlString == other.urlString
        } else {
            return false
        }
    }

}

extension PlaylistEntry: Codable {
    
    enum CodingKeys: String, CodingKey {
        case title
        case duration
        case urlString = "url_string"
    }
    
}

//extension PlaylistEntry: Equatable {
//    public static func == (lhs: PlaylistEntry, rhs: PlaylistEntry) -> Bool {
//        lhs.urlString == rhs.urlString &&
//        lhs.title == rhs.title
//    }
//}

extension PlaylistEntry: Comparable {
    public static func < (lhs: PlaylistEntry, rhs: PlaylistEntry) -> Bool {
        print("comparable")
        return lhs.urlString < rhs.urlString
    }
}
//
//extension PlaylistEntry: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.title)
//        hasher.combine(self.urlString)
//    }
//}
//extension PlaylistEntry: CustomStringConvertible {
//
//    public override var description: String {
//        var s = "\(type(of: self))\n"
//
//        s += "title: \(title)\n"
//        s += "duration: \(duration)\n"
//        s += "urlString: \(urlString)\n"
//
//        return s
//    }
//}

extension PlaylistEntry {
    
    static func getMock() -> PlaylistEntry {
        let JSON = """
            {
            "title": "The video",
            "duration": "12.34",
            "url_string": "http://foo.com/video.mp4"
            }
        """
        let data = JSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        var decoded: PlaylistEntry
        decoded = try! decoder.decode(PlaylistEntry.self, from: data)
        return decoded
    }
}

extension PlaylistEntry  {
    
    func toJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self)
            if let s = String(data: data, encoding: .utf8) {
                print(" \(s)")
                return s
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    // or
    static func toJSON(object: PlaylistEntry) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(object)
            if let s = String(data: data, encoding: .utf8) {
                print(" \(s)")
                return s
            }
        } catch {
            print(error)
        }
        return nil
    }
}

extension PlaylistEntry {
    
    func itemProvider() -> NSItemProvider {
        
        if let fileURL = URL(string: self.urlString) {
            return NSItemProvider(item: fileURL as NSSecureCoding, typeIdentifier: UTType.fileURL.identifier)
        }
        return NSItemProvider(item: self.title as NSSecureCoding, typeIdentifier: UTType.text.identifier)
    }
    
}

#if false
extension PlaylistEntry: NSItemProviderWriting {
    
    static let typeIdentifier = "com.rockhoppertech.PlaylistFrob.PlaylistEntry"
    
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        [typeIdentifier]
    }
    
    
    func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler:
        @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            completionHandler(try encoder.encode(self), nil)
        } catch {
            
            completionHandler(nil, error)
        }
        
        
        return nil
    }
}
#endif
