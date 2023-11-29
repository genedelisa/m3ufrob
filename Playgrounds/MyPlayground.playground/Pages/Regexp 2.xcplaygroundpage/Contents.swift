//: [Previous](@previous)

import Foundation

//let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.*)"#

//let extRegexp = #"([\s\S])*?(?=EXTINF)"#
// [\s\S]*?(?=abc)

let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.+?(?=#EXTINF))"#

//let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.*(?=abc))"#

//let line = "#EXTINF: 21.096,All Things Considered-"
let line = "#EXTINF: 21.096,All Things Considered- #EXTINF"

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

print(cmd)
print(dur)
print(value)

//: [Next](@next)
