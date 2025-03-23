//
//  Misc.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

func calculateTotalSize(for urls: [URL]) async throws -> [URL: Int64] {
    var result: [URL: Int64] = [:]
    try await withThrowingTaskGroup(of: (URL, Int64).self) { group in
        for url in urls {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            group.addTask {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let networkError = response.networkError {
                    throw networkError
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.nonHttpResponse
                }
                return (url, httpResponse.expectedContentLength)
            }
        }

        for try await(url, size) in group {
            result[url] = size
        }
    }
    return result
}
