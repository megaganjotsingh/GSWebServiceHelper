//
//  Result+Extension.swift
//  Task Manager
//
//  Created by Gagan Mac on 16/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation


enum ResultError: Error {
    case nilValue
}

extension Result {
    func mapThrow<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Error> {
        do {
            return .success(try transform(try get()))
        } catch {
            return .failure(error)
        }
    }
    
    @discardableResult
    func success(_ successHandler: (Success) -> Void) -> Result<Success, Failure> {
        if case .success(let value) = self {
            successHandler(value)
        }
        
        return self
    }
    
    @discardableResult
    func `catch`(_ failureHandler: (Failure) -> Void) -> Result<Success, Failure> {
        if case .failure(let error) = self {
            failureHandler(error)
        }
        
        return self
    }
}
