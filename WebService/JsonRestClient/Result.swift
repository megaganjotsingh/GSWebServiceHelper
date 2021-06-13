//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

public enum Response<A, CustomError> {
    case success(A)
    case failure(WebError<CustomError>)
}

extension Response {
    init(value: A?, or error: WebError<CustomError>) {
        guard let value = value else {
            self = .failure(error)
            return
        }
        
        self = .success(value)
    }
    
    var value: A? {
        guard case let .success(value) = self else { return nil }
        return value
    }
    
    var error: WebError<CustomError>? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}
