//
// File:         File.swift
// Project:    
// Package: 
// Product:  
//
// Created by Gene De Lisa on 5/14/23
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

@MainActor
class DirViewModel: ObservableObject {
    
    @Published var playlists: [Playlist] = []
    @Published var selectedURL: URL?
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var selectedPlaylist: Playlist?
    
    func isSandboxingEnabled() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }


    func read(_ selectedURL: URL) async {
        print("Selected \(selectedURL.absoluteString)")
        
        if isSandboxingEnabled() {
            print("In sandbox")
        } else {
            print("No sandbox")
        }
        
        // https://developer.apple.com/documentation/foundation/nsurl/1417051-startaccessingsecurityscopedreso
        if selectedURL.startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource")
            
            // Task {
            print("starting task")
            
            self.playlists = await Playlist.readPlaylistDirectory(selectedURL)
            print("\(playlists)")
            
            //await self.info.show(merge: false, filename: "thing" )
            //self.isImporting = false
            
            selectedURL.stopAccessingSecurityScopedResource()
            print("stopAccessingSecurityScopedResource")
            // }
            
        }
    }
    
    func readPlaylists(_ result: Result<[URL], Error>) async {
        
        switch result {
        case .success(let url):
            
            do {
                selectedURL = url[0]
                
                
                
                //let foo = try result.get()
                
                //                        guard let selectedURL: URL = try result.get().first else {
                //                            return
                //                        }
                
                if let selectedURL {
                    
                    print("Selected \(selectedURL.absoluteString)")
                    
                    if selectedURL.startAccessingSecurityScopedResource() {
                        print("startAccessingSecurityScopedResource")
                        
                        //self.url = selectedURL
                        //self.info.url = selectedURL
                        
                       // Task {
                            print("starting task")
                            
                            self.playlists = await Playlist.readPlaylistDirectory(selectedURL)
                            print("\(playlists)")
                            
                            //await self.info.show(merge: false, filename: "thing" )
                            //self.isImporting = false
                            
                            selectedURL.stopAccessingSecurityScopedResource()
                            print("stopAccessingSecurityScopedResource")
                       // }
                        
                        
                    }
                    
                }
            } catch {
                print("\(error.localizedDescription)")
                self.hasError = true
                self.errorMessage = error.localizedDescription
            }
            
        case .failure(let error):
            print(error)
            
        }// switch
        
    }
    
}
