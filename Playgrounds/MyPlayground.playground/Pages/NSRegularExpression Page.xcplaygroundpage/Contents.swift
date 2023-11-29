import Foundation

func lineWithDupeRemoved(_ line: String) -> String? {

    do {
        let multiPattern = #"#EXTINF:"#
        
        let multiRegex = try NSRegularExpression(
            pattern: multiPattern,
            options: []
        )
        
        let lineRange = NSRange(
            line.startIndex..<line.endIndex,
            in: line
        )
        
        let multiMatches = multiRegex.matches(
            in: line,
            options: [],
            range: lineRange
        )
        //print("There are \(multiMatches.count) multi matches in\n\(line)")
        
        if multiMatches.count > 1 {
            let ranges = line.ranges(of: "#EXTINF:")// {
            if ranges.count > 1 {
                let r = line.startIndex..<ranges[1].lowerBound
                let sub = String(line[r])
                //print("sub: |\(sub)|")
                return sub
            }
        } else {
            return nil
        }
    } catch {
        print("\(error)")
        return nil
    }
    return nil
}


func parseExtInf(_ line: String) throws -> (cmd: String, dur: String, title: String)  {
    
    var line = line

    var title = ""
    
    
    if let s = lineWithDupeRemoved(line) {
        print("proper line |\(s)|")
        line = s
    }
    
    let lineRange = NSRange(
        line.startIndex..<line.endIndex,
        in: line
    )
    
    let capturePattern =
    #"(?<cmd>(#EXTINF)):\s*"# +
    #"(?<dur>(-?\d*\.?\d+)),\s*"# +
    #"(?<title>(.*?(?:#EXTINF:|$)))"#

    // title uses a non greedy positive lookahead
//    #"(?<title>(.*?(?=#EXTINF)))"#
//    #"(?<title>(.*))"#
    // (?<=start).*?(?=(?:end|$))
    

    let extInfRegex = try! NSRegularExpression(
        pattern: capturePattern,
        options: []
    )
    
    let matches = extInfRegex.matches(
        in: line,
        options: [],
        range: lineRange
    )
    //print("There are \(matches.count) matches ")
    
    guard let match = matches.first else {
        throw NSError(domain: "No matches", code: 0, userInfo: nil)
    }
    var captures: [String: String] = [:]
    
    
    // For each matched range, extract the named capture group
    for name in ["cmd", "dur", "title"] {
        let matchRange = match.range(withName: name)
        //print("\(matchRange.lowerBound) \(matchRange.upperBound)")
        // Extract the substring matching the named capture group
        if let substringRange = Range(matchRange, in: line) {
            let capture = String(line[substringRange])
            captures[name] = capture
        }
    }
    
    guard let cmd = captures["cmd"]  else { 
        throw M3U8Error.badCommand
//        throw NSError(domain: "cmd", code: 0, userInfo: nil)
    }
    //print("cmd:\(cmd)")
    
    guard let dur = captures["dur"] else { 
        throw M3U8Error.badDuration
//        throw NSError(domain: "dur", code: 0, userInfo: nil)
    }
    //print("dur:\(dur)")
    
    guard let title = captures["title"]  else {
        throw M3U8Error.badTitle
//        throw NSError(domain: "title", code: 0, userInfo: nil)
    }
    //print("title:\(title)")
    
    return (cmd, dur, title)
}

enum M3U8Error: Error {
    case badTitle
    case badDuration
    case badCommand
}

print("\n\n\nRunning")
do {
    let (cmd,dur,title) = try parseExtInf("#EXTINF:21.096,All Things Considered")
    print("cmd:\(cmd)")
    print("dur:\(dur)")
    print("title:\(title)")
} catch {
    print(error)
}

print()

// fix this: removes foo bar but #EXTINF remains
do {
    let (cmd,dur,title) = try parseExtInf("#EXTINF: 21.096, No Things Considered #EXTINF: foo bar")
    print("cmd:\(cmd)")
    print("dur:\(dur)")
    print("title:\(title)")
} catch {
    print(error)
}






//let birthday = "01/02/2003"
//
//let birthdayRange = NSRange(
//    birthday.startIndex..<birthday.endIndex,
//    in: birthday
//)
//
//// Create A NSRegularExpression
//let capturePattern =
//#"(?<month>\d{1,2})\/"# +
//#"(?<day>\d{1,2})\/"# +
//#"(?<year>\d{1,4})"#
//
//let birthdayRegex = try! NSRegularExpression(
//    pattern: capturePattern,
//    options: []
//)
//
//// Find the matching capture groups
//let matches = birthdayRegex.matches(
//    in: birthday,
//    options: [],
//    range: birthdayRange
//)
//
//guard let match = matches.first else {
//    // Handle exception
//    throw NSError(domain: "", code: 0, userInfo: nil)
//}
//var captures: [String: String] = [:]
//
//// For each matched range, extract the named capture group
//for name in ["month", "day", "year"] {
//    let matchRange = match.range(withName: name)
//
//    // Extract the substring matching the named capture group
//    if let substringRange = Range(matchRange, in: birthday) {
//        let capture = String(birthday[substringRange])
//        captures[name] = capture
//    }
//}
//
//captures["month"] // 01
//captures["day"] // 02
//captures["year"] // 2003



//    if try doesLineHaveDupe(line) {
//        print("Has dupe")
//        print("\(line)")
//        if let s = try lineWithDupeRemoved(line) {
//            print("proper line |\(s)|")
//            line = s
//        }
//    }

//func doesLineHaveDupe(_ line: String) throws -> Bool {
//
//    do {
//        let multiPattern = #"#EXTINF:"#
//
//        let multiRegex = try NSRegularExpression(
//            pattern: multiPattern,
//            options: []
//        )
//
//        let lineRange = NSRange(
//            line.startIndex..<line.endIndex,
//            in: line
//        )
//
//        let multiMatches = multiRegex.matches(
//            in: line,
//            options: [],
//            range: lineRange
//        )
//       // print("There are \(multiMatches.count) multi matches in\n\(line)")
//
//        if multiMatches.count > 1 {
//            let ranges = line.ranges(of: "#EXTINF:")// {
//            if ranges.count > 1 {
//                let r = line.startIndex..<ranges[1].lowerBound
//                let sub = line[r]
//                //print("sub: |\(sub)|")
//            }
//
//            return true
//
//        } else {
//            return false
//        }
//
//    } catch {
//        print("\(error)")
//        return false
//    }
//}
