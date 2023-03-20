//
//  ApiError.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

public enum ApiError: LocalizedError {
	case noHttpResponse
	case no200Status(response: HTTPURLResponse, body: Data?)
	case noBody
	case notUnderstandable
	case notSuccess(status: Any?)
	case noRequestPossible

	public var errorDescription: String? {
		switch self {
		case .noHttpResponse:
			return NSLocalizedString("No valid HTTP response.", bundle: .iPtProxyUI, comment: "")

		case .no200Status(let response, let body):
			var content = ""

			if let body = body,
			   let body = String(data: body, encoding: .utf8)
			{
				content = "\n\(body)"
			}

			return "\(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))\(content)"

		case .noBody:
			return NSLocalizedString("Response body missing.", bundle: .iPtProxyUI, comment: "")

		case .notUnderstandable:
			return NSLocalizedString("Couldn't understand server response.", bundle: .iPtProxyUI, comment: "")

		case .notSuccess(let status):
			return String(format: NSLocalizedString(
				"No success, but \"%@\" instead.", bundle: .iPtProxyUI, comment: ""),
						  String(describing: status))

		case .noRequestPossible:
			return NSLocalizedString("Request could not be formed. Please check host and username/password!",
									 bundle: .iPtProxyUI, comment: "")
		}
	}
}
