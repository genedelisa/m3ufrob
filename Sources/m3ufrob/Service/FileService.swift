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

import Foundation
import Combine
import os.log

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

    
}
