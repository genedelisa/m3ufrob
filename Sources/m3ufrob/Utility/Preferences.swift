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
import GDTerminalColor
import OSLog
import os.log

/**
 Shared preferences

 They will be stored in `~/Library/Preferences/m3ufrob.plist`

 You can read them from the command line:
 ```
 defaults read m3ufrob
 defaults read m3ufrob foreground-color-name
 ```
 */
class Preferences {
    static let sharedInstance = Preferences()

    static let suiteName = "m3ufrob"

    enum Keys: String, CaseIterable {
        case firstRunDate = "first-run-date"
        case numberOfRuns = "number-of-runs"
        case foregroundColorName = "foreground-color-name"
        case backgroundColorName = "background-color-name"
        case foregroundColorHex = "foreground-color-hex"
        case backgroundColorHex = "background-color-hex"
        case foregroundColorCss = "foreground-color-css"
        case backgroundColorCss = "background-color-css"
        case verbose
        case brief
        case fetchLimit = "fetch-limit"
        case outputDirectory
    }

    let userDefaults: UserDefaults

    init() {
        guard
            let defaults = UserDefaults(suiteName: Self.suiteName)
        else { exit(EXIT_FAILURE) }
        self.userDefaults = defaults

        registerDefaults()

        numberOfRuns = numberOfRuns + 1
    }

    /// The number of times this program has been run.
    var numberOfRuns: Int {
        get {
            userDefaults.integer(forKey: Keys.numberOfRuns.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.numberOfRuns.rawValue)
        }
    }

    var foregroundColorName: String? {
        get {
            userDefaults.string(forKey: Keys.foregroundColorName.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.foregroundColorName.rawValue)
        }
    }

    var backgroundColorName: String? {
        get {
            userDefaults.string(forKey: Keys.backgroundColorName.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.backgroundColorName.rawValue)
        }
    }

    var foregroundColorHex: String? {
        get {
            userDefaults.string(forKey: Keys.foregroundColorHex.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.foregroundColorHex.rawValue)
        }
    }

    var backgroundColorHex: String? {
        get {
            userDefaults.string(forKey: Keys.backgroundColorHex.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.backgroundColorHex.rawValue)
        }
    }

    var foregroundColorCss: String? {
        get {
            userDefaults.string(forKey: Keys.foregroundColorCss.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.foregroundColorCss.rawValue)
        }
    }

    var backgroundColorCss: String? {
        get {
            userDefaults.string(forKey: Keys.backgroundColorCss.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.backgroundColorCss.rawValue)
        }
    }

    var verbose: Bool {
        get {
            userDefaults.bool(forKey: Keys.verbose.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.verbose.rawValue)
        }
    }

    var brief: Bool {
        get {
            userDefaults.bool(forKey: Keys.brief.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.brief.rawValue)
        }
    }

    // @objc dynamic
    var firstRunDate: Date? {
        get {
            userDefaults.object(forKey: Keys.firstRunDate.rawValue) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: Keys.firstRunDate.rawValue)
        }
    }

    func isFirstRun() -> Bool {

        if firstRunDate == nil {
            firstRunDate = Date()
            return true
        }

        return false
    }

    var fetchLimit: Int {
        get {
            userDefaults.integer(forKey: Keys.fetchLimit.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.fetchLimit.rawValue)
        }
    }

    // MARK: Default Values

    func registerDefaults() {

        userDefaults.register(defaults: [
            Keys.foregroundColorName.rawValue: "gold1",
            Keys.backgroundColorName.rawValue: "blue",
            Keys.foregroundColorHex.rawValue: Color24.DEFAULT_FG,
            Keys.backgroundColorHex.rawValue: Color24.DEFAULT_BG,
            Keys.foregroundColorCss.rawValue: "Salmon",
            Keys.backgroundColorCss.rawValue: "MidnightBlue",
            Keys.verbose.rawValue: false,
            Keys.brief.rawValue: true,
            Keys.numberOfRuns.rawValue: 0,
            Keys.firstRunDate.rawValue: 0,
            Keys.fetchLimit.rawValue: 5
        ])
    }

    /// this takes a lot of time. Find a better way.
    func addEncodedPreference(key: String, value: Encodable) {
        let data = try? PropertyListEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    func encodeColorName(key: String, value: XTColorName) {
        let data = try? PropertyListEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    func decodeColorName(data: Data) -> XTColorName? {
        do {
            let value = try PropertyListDecoder().decode(XTColorName.self, from: data)
            return value
        } catch {
            print(error)
            return nil
        }
    }

    /// zsh: typeset -x BGCOLOR=foo
    /// bash: export BGCOLOR=foo
    func envValue(key: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[key] {
            return value
        }
        Logger.ui.error("no env value for key \(key)")
        return nil
    }

    /// display all preference on stdout.
    func printPreferences() {
        // print("\(#function)")

        print("All preferences")
        let dict = userDefaults.dictionaryRepresentation()
        for (k, v) in dict {
            print("\(k) : \(v)")
        }
    }

    func printAllInSuite() {
        // print("\(#function)")

        ColorConsole.enablePrintColors(fg: "gold1", bg: "navyBlue")
        Color256.printBold()
        print("Preferences")
        Color256.printNoBold()
        print("suiteName: \(Self.suiteName)")

        if let dict = userDefaults.persistentDomain(forName: Self.suiteName) {
            for (k, v) in dict {
                print("\(k) : \(v)")
            }
        }
        print("End of Preferences")

        print()

        ColorConsole.disablePrintColors()
    }

    func resetAll() {
        // UserDefaults.standard.removePersistentDomain(forName: bundleID)
        Keys.allCases.forEach { userDefaults.removeObject(forKey: $0.rawValue) }
        userDefaults.synchronize()
    }

    static func resetDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            print("removing defaults for \(bundleID)")
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            return
        }
        if let bundleID = Bundle.module.bundleIdentifier {
            print("removing defauts for \(bundleID)")
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            return
        }
    }
    
    var outputDirectory: String? {
        get {
            userDefaults.string(forKey: Keys.outputDirectory.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.outputDirectory.rawValue)
        }
    }

}
