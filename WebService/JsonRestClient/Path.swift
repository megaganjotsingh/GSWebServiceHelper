//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

public struct Path {
    private var components: [String]
    
    var absolutePath: String {
        return "/" + components.joined(separator: "/")
    }
    
    init(_ path: String) {
        components = path.components(separatedBy: "/").filter({ !$0.isEmpty })
    }
    
    mutating func append(path: Path) {
        components += path.components
    }
    
    func appending(path: Path) -> Path {
        var copy = self
        copy.append(path: path)
        return copy
    }
}
