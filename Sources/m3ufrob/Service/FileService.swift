// File:    FileService.swift
// Project: PlaylistFrob
//
// Created by Gene De Lisa on 11/9/21
//
// Using Swift 5.0
// Running macOS 12.0
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


import Foundation
import Combine

#if os(Linux)
    // TODO: os.log on linux
    // find a shim for os.log
#else
    import Cocoa
    import os.log
#endif


protocol FileServiceProtocol {
    var fileEntries: [FileEntry] {get}

    var selectedFileEntries: Set<FileEntry> {get set}

    func add(fileEntry: FileEntry)

    func delete(at index: Int)
    func delete(thing: FileEntry)

    func frobnosticate()
}

class FileService: FileServiceProtocol, ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FileService")

    static let shared = FileService()
    
    @Published var fileEntries = [FileEntry]()
    
    @Published var fileEntriesSet = Set<FileEntry>()

    // the view model keeps track of selections and sets this.
    // then in frobnosticate these selections are used.
    public var selectedFileEntries: Set<FileEntry> = [] {
        didSet {
            logger.debug("\(String(describing: type(of: self))) : selectedFileEntries set to: \(self.selectedFileEntries)")
        }
    }

    var userSelectedFolderURL: URL? {
        didSet {
            logger.debug("set: \(self.userSelectedFolderURL!)")
            self.fileEntries = self.directoryContents(justPlaylistFiles: false)
        }
    }

    var userSelectedFileURL: URL? {
        didSet {
            logger.debug("set: \(self.userSelectedFileURL!)")
            load(fileURL: userSelectedFileURL!)
        }
    }



    func add(fileEntry: FileEntry) {
        logger.trace("\(#function)")

        fileEntries.append(fileEntry)
        fileEntriesSet.insert(fileEntry)
    }

    func delete(at index: Int) {
        logger.trace("\(#function)")
        fileEntries.remove(at: index)

    }

    func delete(thing: FileEntry) {
        fileEntriesSet.remove(thing)

        if let index = fileEntries.firstIndex(of: thing) {
            delete(at: index)
        }

        // if you want to compare fields
//        if let index = fileEntries.firstIndex(where: {$0.id == thing.id}) {
//        }

    }


    func frobnosticate() {
        logger.trace("\(#function)")

        for t in fileEntriesSet {
            logger.debug("entry: \(t.justName())")
        }

        for t in fileEntries {
            logger.debug("entry: \(t.justName())")
        }

        for t in selectedFileEntries {
            logger.debug("entry: \(t.justName())")
        }
    }

    func load(fileURL: URL) {
        let playlist = Playlist(fileURL: fileURL)

        Task {
            await playlist.load()
        }

//        let fe = FileEntry(fileURL: fileURL)
//        print("FileEntry: \(fe)")

//        if let userSelectedFileURL {
//        }


    }

    func directoryContents(justPlaylistFiles: Bool = true) -> [FileEntry] {
        guard let url = userSelectedFolderURL else {
            logger.error("userSelectedFolderURL: nothing is selected")
            return []
        }

        let keys: [URLResourceKey] = [
            .isReadableKey,
        ]

        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsHiddenFiles,
        ]

        do {
            let files = try FileManager.default.contentsOfDirectory(at: url,
                                                                    includingPropertiesForKeys: keys,
                                                                    options: options)
            print("All files \(files)")

            if justPlaylistFiles {
                let playlistFiles = files.filter {
                    ["m3u", "m3u8"].contains($0.pathExtension.lowercased())
                }
                let entries = playlistFiles.map { FileEntry(fileURL: $0) }
                return entries
            } else {
                let entries = files.map { FileEntry(fileURL: $0) }
                return entries
            }
        } catch {
            logger.error("Error: \(error.localizedDescription)")
        }
        return []
    }

    func playlistFilesInDirectory(selectedFolderURL: URL) -> [FileEntry] {

        let keys: [URLResourceKey] = [
            .isReadableKey
        ]

        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsHiddenFiles
        ]

        do {
            let files = try FileManager.default.contentsOfDirectory(at: selectedFolderURL,
                                                                    includingPropertiesForKeys: keys,
                                                                    options: options)
            let playlistFiles = files.filter {
                ["m3u", "m3u8"]
                    .contains($0.pathExtension.lowercased())
            }
            let entries = playlistFiles.map { FileEntry(fileURL: $0) }
            return entries

        } catch {
            logger.error("Error: \(error.localizedDescription)")
        }
        return []
    }



    func read(url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FileServiceError.fileRead("Could not read data for \(url.absoluteString)")
        }
    }

    func write(string: String, to url: URL) {
        do {
            try string.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            Logger.service.error("\(error.localizedDescription)")
        }
    }

    func readAsString(url: URL, encodedAs encoding: String.Encoding = .utf8) throws -> String {
        guard let string = try String(data: read(url: url), encoding: encoding) else {
            throw FileServiceError.fileRead("Could not decode string for \(url.absoluteString)")
        }

        return string
    }

    func listFilesHere(path: String) {
        let path = FileManager.default.currentDirectoryPath
        listFilesFrob(path: path)
    }

    func listFilesFrob(path: String) {
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: path)
            for fileName in fileNames {
                print("\(fileName)")
            }
        } catch {
            Logger.service.error("\(error.localizedDescription)")
        }
    }

        func append(string: String, to url: URL) {

        //        let formatter = DateFormatter()
        //        formatter.dateFormat = "HH:mm:ss"
        //        let timestamp = formatter.string(from: Date())

        guard let data = string.data(using: String.Encoding.utf8) else {
            return
        }

        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: url, options: .atomicWrite)
        }
    }

    func writeFrob() {

        //let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let str = "Test Message"
        let url = currentDirectory.appendingPathComponent("textfile.txt")

        do {
            try str.write(to: url, atomically: true, encoding: .utf8)

            // just to check
            let contents = try String(contentsOf: url)
            print("\(contents)")
        } catch {
            Logger.general.warning("\(error.localizedDescription)")
        }

    }

    func readFrob() -> Data? {
        let home: URL = FileManager.default.homeDirectoryForCurrentUser

        let fileUrl =
            home
            .appendingPathComponent("Documents")
            .appendingPathComponent("someFile")
            .appendingPathExtension("txt")

        guard FileManager.default.fileExists(atPath: fileUrl.path(percentEncoded: false)) else {
            Logger.error.debug("file expected at \(fileUrl.absoluteString) is missing")
            preconditionFailure("file expected at \(fileUrl.absoluteString) is missing")
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            return data
        } catch {
            //throw FileServiceError.fileRead(name: name, error)
        }
        return nil
    }

    func decodeFrob() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        let fileUrl =
            home
            .appendingPathComponent("Documents")
            .appendingPathComponent("someFile")
            .appendingPathExtension("json")

        guard FileManager.default.fileExists(atPath: fileUrl.path(percentEncoded: false)) else {
            preconditionFailure("file expected at \(fileUrl.absoluteString) is missing")
        }

        //        do {
        //            let data = try Data(contentsOf: fileUrl)
        //            let decoder = JSONDecoder()
        //            //return try decoder.decode(Content.self, from: data)
        //        } catch {
        //            //throw Error.fileDecodingFailed(name: name, error)
        //        }

    }


}
