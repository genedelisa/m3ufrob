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
struct InfoView: View {
    var info: InfoClass
    var voiceName = "Serena"

    var body: some View {

        VStack(spacing: 25) {

            Spacer()

            Text("\(info.header())")
              .font(.headline)

            Text("\(info.info())")
              .font(.subheadline)

            Spacer()

            Button {
                info.calculateInfo()
                info.say(blather: info.info())

            } label: {
                Label("Speak", systemImage: "speaker")
            }
            .padding()
            //.buttonStyle(GDButtonStyle())

        }

    }


}
