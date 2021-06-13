//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 16/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

protocol Unwrappable {
    associatedtype Wrapped
    func unwrap(errorIfNil: Error?) throws -> Wrapped
}

extension Optional: Unwrappable {
    func unwrap(errorIfNil error: Error? = nil) throws -> Wrapped {
        switch self {
        case .some(let unwrapped):
            return unwrapped
        case .none:
            throw error ?? ResultError.nilValue
        }
    }
}

extension Result: Unwrappable {
    func unwrap(errorIfNil: Error? = nil) throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw errorIfNil ?? error
        }
    }
}
