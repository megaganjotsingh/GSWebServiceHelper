//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import Foundation

public enum WebError<CustomError>: Error {
    case noInternetConnection
    case custom(CustomError)
    case unauthorized
    case other

}
