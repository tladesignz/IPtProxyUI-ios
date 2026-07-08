//
//  URLSession+IPtProxyUI.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

public extension URLSession {

	func apiTask<T: Codable>(with request: URLRequest, _ completion: ((T?, Error?) -> Void)? = nil) -> URLSessionDataTask {
		return dataTask(with: request) { data, response, error in

//			print("[\(String(describing: type(of: self)))]#apiTask data=\(String(describing: String(data: data ?? Data(), encoding: .utf8))), response=\(String(describing: response)), error=\(String(describing: error))")
			
			if let error = error {
				completion?(nil, error)
				return
			}

			guard let response = response as? HTTPURLResponse else {
				completion?(nil, ApiError.noHttpResponse)
				return
			}

			guard response.statusCode == 200 else {
				completion?(nil, ApiError.no200Status(response: response, body: data))
				return
			}

			guard let data = data, !data.isEmpty else {
				completion?(nil, ApiError.noBody)
				return
			}
			
			if let error = (try? MoatApi.decoder.decode(MoatApi.Errors.self, from: data))?.errors.first {
				completion?(nil, error)
				return
			}

			if String(describing: T.self) == "Data" {
				completion?(data as? T, nil)
				return
			}
			
			do {
				completion?(try MoatApi.decoder.decode(T.self, from: data), nil)
			}
			catch {
				completion?(nil, error)
				return
			}
		}
	}

	func apiTask<T: Codable>(with request: URLRequest) async throws -> T {
		return try await withCheckedThrowingContinuation { continuation in
			let task = self.apiTask(with: request) { result, error in
				if let error {
					return continuation.resume(throwing: error)
				}

				continuation.resume(returning: result!)
			}

			task.resume()
		}
	}
}
