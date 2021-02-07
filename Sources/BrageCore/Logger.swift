/**
*  Brage
*  Copyright (c) Michael Enger 2021
*  MIT license, see LICENSE file for details
*/

// Thanks to https://stackoverflow.com/a/30454802
enum ANSIColors: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case reset = "\u{001B}[0;0m"
}

// END

/// Contains helpers for outputting coloured text.
struct Logger {
    public static func debug(_ text: String) {
        print("\(ANSIColors.cyan.rawValue)\(text)\(ANSIColors.reset.rawValue)")
    }
    
    public static func error(_ text: String) {
        print("\(ANSIColors.red.rawValue)\(text)\(ANSIColors.reset.rawValue)")
    }
    
    public static func log(_ text: String) {
        print(text)
    }
    
    public static func success(_ text: String) {
        print("\(ANSIColors.green.rawValue)\(text)\(ANSIColors.reset.rawValue)")
    }
    
    public static func warning(_ text: String) {
        print("\(ANSIColors.yellow.rawValue)\(text)\(ANSIColors.reset.rawValue)")
    }
}
