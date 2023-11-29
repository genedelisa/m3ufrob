//: [Previous](@previous)
import Cocoa


let message = "the cat sat on the mat"
print(message.ranges(of: "at"))
print(message.replacing("cat", with: "dog"))
print(message.trimmingPrefix("the "))

// new regexp

print(message.ranges(of: /[a-z]at/))
print(message.replacing(/[a-m]at/, with: "dog"))
print(message.trimmingPrefix(/The/.ignoresCase()))

let search1 = /My name is (.+?) and I'm (\d+) years old./
let greeting1 = "My name is Taylor and I'm 26 years old."

if let result = try? search1.wholeMatch(in: greeting1) {
    print("Name: \(result.1)")
    print("Age: \(result.2)")
}

// named matches

let search2 = /My name is (?<name>.+?) and I'm (?<age>\d+) years old./
let greeting2 = "My name is Taylor and I'm 26 years old."

if let result = try? search2.wholeMatch(in: greeting2) {
    print("Name: \(result.name)")
    print("Age: \(result.age)")
}


// DSL
import RegexBuilder

let search3 = Regex {
    "My name is "

    Capture {
        OneOrMore(.word)
    }

    " and I'm "

    Capture {
        OneOrMore(.digit)
    }

    " years old."
}

let search4 = Regex {
    "My name is "

    Capture {
        OneOrMore(.word)
    }

    " and I'm "

    TryCapture {
        OneOrMore(.digit)
    } transform: { match in
        Int(match)
    }

    " years old."
}


// And you can even bring together named matches using variables with specific types like this:

let nameRef = Reference(Substring.self)
let ageRef = Reference(Int.self)

let search5 = Regex {
    "My name is "

    Capture(as: nameRef) {
        OneOrMore(.word)
    }

    " and I'm "

    TryCapture(as: ageRef) {
        OneOrMore(.digit)
    } transform: { match in
        Int(match)
    }

    " years old."
}

if let result = greeting1.firstMatch(of: search5) {
    print("Name: \(result[nameRef])")
    print("Age: \(result[ageRef])")
}


let extImgRegexp = #"#(EXTIMG:)\s*(.*)"#

//let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.*)"#
let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.+?(?=#EXTINF))"#

    

let line = "#EXTINF: 21.096,All Things Considered-"

let cmd = line.replacingOccurrences(
    of: extRegexp,
    with: "$1",
    options: .regularExpression,
    range: nil)
let dur = line.replacingOccurrences(
    of: extRegexp,
    with: "$2",
    options: .regularExpression,
    range: nil)
let value = line.replacingOccurrences(
    of: extRegexp,
    with: "$3",
    options: .regularExpression,
    range: nil)

// ?<name> is how you name a capture result
let searchRegexp = /(?<command>#EXTINF):\s*(?<dur>-?\d*\.?\d+),(?<value>.*)/

if let result = try? searchRegexp.wholeMatch(in: line) {
    print("Command: \(result.command)")
    print("Dur: \(result.dur)")
    print("Value: \(result.value)")
}

//if let i = line.firstIndex(of: "") {
//}


// positive lookahead
let searchRegexp2 = /(?<command>#EXTINF):\s*(?<dur>-?\d*\.?\d+),(?<value>.+?(?=#EXTINF))/

// /(#EXTINF):\s*(-?\d*\.?\d+),(.+?(?=#EXTINF))/

do {
    let bad = "#EXTINF:193.0,A girl : #EXTINF:193,A girl tries"
    if let result = try searchRegexp2.wholeMatch(in: bad) {
        print("Command: \(result.command)")
        print("Dur: \(result.dur)")
        print("Value: \(result.value)")
    }
} catch {
    print("\(error)")
}
//: [Next](@next)
