/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  MIT license, see LICENSE file for details
*/

import Foundation

public struct HumansFile {

    public let entries: [HumansFileEntry]
    
    public init(entries: [HumansFileEntry]) {
        self.entries = entries
    }

}

public extension HumansFile {
    
    func render() -> String {
        entries
            .compactMap { $0.render() }
            .joined(separator: "\n\n")
    }
    
}

public extension HumansFile {
    
    struct HumansFileEntry {
        
        public let header: String
        public let map: [String: Any]
        
        public init(header: String, map: [String: Any]) {
            self.header = header
            self.map = map
        }
    }
    
}

public extension HumansFile.HumansFileEntry {
    
    func render() -> String {
        "/* \(header) */\n" + map
            .map { "    \($0.key): \(convert($0.value))" }
            .joined(separator: "\n")
    }
    
    private static let format: DateFormatter = {
        let form = DateFormatter()
        form.dateFormat = "yyyy-MM-dd"
        return form
    }()
    
    private func convert(_ value: Any) -> String {
        if let date = value as? Date {
            return Self.dateFormatted(date)
        }
        return "\(value)"
    }
    
    private static func dateFormatted(_ date: Date) -> String {
        return Self.format.string(from: date)
    }
    
}
