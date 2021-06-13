//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

public struct Resource<A, CustomError> {
    let path: Path
    let method: RequestMethod
    var headers: HTTPHeaders
    var params: JSON
    let parse: (Data) -> A?
    let parseError: (Data) -> CustomError?
    
    init(path: String,
         method: RequestMethod = .post,
         params: JSON = [:],
         headers: HTTPHeaders = [:],
         parse: @escaping (Data) -> A?,
         parseError: @escaping (Data) -> CustomError?) {
        
        self.path = Path(path)
        self.method = method
        self.params = params
        self.headers = headers
        self.parse = parse
        self.parseError = parseError
    }
    
}

extension Resource where A: Decodable, CustomError: Decodable {
    init(jsonDecoder: JSONDecoder = JSONDecoder(),
         path: String,
         method: RequestMethod = .get,
         params: JSON = [:],
         headers: HTTPHeaders = [:], defaultHeadersIncluded: Bool = true) {
        
        var newHeaders = headers
        if defaultHeadersIncluded {
            newHeaders["Accept"] = "application/json"
            newHeaders["Content-Type"] = "application/json"
        }
             
        self.path = Path(path)
        self.method = method
        self.params = params
        self.headers = newHeaders
        self.parse = {
            try? jsonDecoder.decode(A.self, from: $0)
        }
        self.parseError = {
            try? jsonDecoder.decode(CustomError.self, from: $0)
        }
    }
}
