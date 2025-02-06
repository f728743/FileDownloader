//
//  NetworkError.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case httpError(statusCode: Int, description: String?)

    var errorDescription: String? {
        switch self {
        case let .httpError(status, description):
            description ?? "HTTP Error Status Code: \(status)"
        }
    }
}
