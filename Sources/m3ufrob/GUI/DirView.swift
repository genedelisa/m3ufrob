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


import os.log
import OSLog
import SwiftUI

@available(macOS 10.15, *)
struct DirView: View {
    
    @StateObject var model = DirViewModel()
    @State var url: URL = URL(fileURLWithPath: ".")
    @State private var isImporting: Bool = false
    @State var playlists: [Playlist] = []
    //    @Published var playlists: [Playlist] = []
    
    @State var selectedPlaylist: Playlist? = nil
    @State private var selection: Set<UUID> = []
    
    @State private var isPerformingTask = false
    
    let imageTask = Task { () -> NSImage? in
        let imageURL = URL(string: "https://source.unsplash.com/random")!

        // Check for cancellation before the network request.
        try Task.checkCancellation()
        print("Starting network request...")
        let (imageData, _) = try await URLSession.shared.data(from: imageURL)

        // Check for cancellation after the network request
        // to prevent starting our heavy image operations.
        try Task.checkCancellation()

        let image = NSImage(data: imageData)

        // Perform image operations since the task is not cancelled.
        return image
    }
    
    let readPlaylistsTask = Task { () -> Void in
        
        try Task.checkCancellation()
        
        //self.isPerformingTask = true
        //await model.read(url)
        //self.isPerformingTask = false
    }

    
    
    
    
    //    var windowCommandLogic:  WindowCommandLogic
    //    init(windowCommandLogic: WindowCommandLogic) {
    //        self.windowCommandLogic = windowCommandLogic
    //    }
    
    var info: InfoClass
    init(info: InfoClass) {
        self.info = info
        //self.url = URL(fileURLWithPath: ".")
    }
    
    var body: some View {
        
        VStack(spacing: 25) {
            
            Spacer()
            
            Text("Directory", comment: "Header label for directory in DirView")
                .font(.headline)
            
            Text("Your playlists", comment: "Subheadline in Dirview")
                .font(.subheadline)
            
            //            if let u = self.url {
            //                Text("\(u.absoluteString)", comment: "file name. not to be translated")
            //                    .font(.title)
            //            }
            Text("\(self.url.lastPathComponent)", comment: "file name. not to be translated")
                .font(.title)
            
            List(selection: $selection) {
                ForEach(model.playlists, id: \.id) { list in
                    if let fileURL = list.fileURL {
                        Text("\(fileURL.lastPathComponent)")
                            .tag(list)
                    }
                   
                }
            }
            .frame(minWidth: 100, minHeight: 100)
            .refreshable {
                //if let url {
                await model.read(url)
                //}
            }
            //.listStyle(.inset)
            .padding()
            .listRowBackground(Color.yellow)
            
            // List(viewModel.filteredComposers.sorted(), id: \.self, selection: $appModel.selectedComposer ) { composer in
            
            //            List(model.playlists, id: \.id, selection: $model.selectedPlaylist) { list in
            //            //List(model.playlists, id: \.id, selection: $selectedPlaylist) { list in
            //                Text("\(list.fileURL.lastPathComponent)")
            //            }
            //            .frame(minWidth: 100, minHeight: 100)
            //            .padding()
            
            // need to use foreach and put onMove on it to dnd to rearrange the list.
            //            List {
            //                ForEach($book.chapters, id: \.id) { $chapter in
            //                    TextField("", text: $chapter.title)
            //                }
            //                .onMove { indices, destination in
            //                    book.chapters.move(fromOffsets: indices,
            //                        toOffset: destination)
            //                }
            //            }
            
            
            Divider()
            
            Button {
                // showChooseFileDialog(title: "Choose Directory")
                isImporting = true
            } label: {
                Label(String(localized: "Choose", comment:"Prompt to choose a folder"),
                      systemImage: "folder")
                
                if isPerformingTask {
                    ProgressView()
                }
            }
            
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            .controlSize(.large)
            .padding()
            .disabled(isPerformingTask)
            
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.directory],
                          allowsMultipleSelection: false) { result in
                
                switch result {
                case .success(let url):
                    self.url = url[0]
                    
                    self.refresh()
                    
                case .failure(_):
                    self.isPerformingTask = false
                    break
                }
                
                //                Task {
                //                    if let url {
                //                        await model.read(url)
                //                    }
                //                    //await model.readPlaylists(result)
                //                }
                
            } // .fileImporter
            
            
            
            
            
            //                          .fileExporter(isPresented: $isPublishing,
            //                                        document: book,
            //                                        contentType: .epub,
            //                                        defaultFilename: book.title) { result in
            //
            //                              switch result {
            //                              case .success(let url):
            //                                  book.publishEPUB(location: url)
            //                              case .failure(let error):
            //                                  print(error)
            //                              }
            //                          }
            
            
            
            Spacer()
            
            
            
            
        }
        .onChange(of: self.url) { newUrl in
            print("on change \(newUrl)")
            self.refresh()
        }
        
    }
    
    @MainActor
    func refresh() {
        print("refresh")
        
        Task {
            print("inside task")
            
            self.isPerformingTask = true
            await model.read(url)
            self.isPerformingTask = false
        }
    }
    
    
    
    func showChooseFileDialog(title: String) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.title = title
        
        openPanel.begin { (result) -> Void in
            //            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
            if result == .OK {
                if let u = openPanel.url {
                    self.url = u
                    self.info.url = u
                    
                    Task {
                        await self.info.show(merge: false, filename: "thing" )
                    }
                    
                    
                    //                    self.windowCommandLogic.url = u
                    
                    if let keyWindow = NSApplication.shared.keyWindow {
                        print("closing key window \(keyWindow)")
                        keyWindow.close()
                    }
                    // this is usually the one that is set
                    if let first = NSApp.windows.first {
                        print("closing first window \(first)")
                        first.close()
                    }
                }
            }
        }
    }
    
    
}
