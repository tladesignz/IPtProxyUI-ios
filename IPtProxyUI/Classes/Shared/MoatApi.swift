//
//  MoatApi.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 30.05.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

/**
 Implements the MOAT service API.

 See https://gitlab.torproject.org/meskio/rdsys/-/blob/doc_moat_api/doc/moat.md
 */
open class MoatApi {

	public enum Endpoint {

		@available(*, deprecated, message: "CAPTCHA use is now deprecated by Tor Project and can be replaced by using the obfs4/bridgedb piece of a `.defaults` response.")
		case fetch

		@available(*, deprecated, message: "CAPTCHA use is now deprecated by Tor Project and can be replaced by using the obfs4/bridgedb piece of a `.defaults` response.")
		case check(challenge: String, solution: String)

		case settings(country: String? = nil)

		case defaults

		case map

		case builtin

		case countries

		var path: String {
			switch self {
			case .fetch:
				return "fetch"

			case .check:
				return "check"

			case .settings:
				return "circumvention/settings"

			case .defaults:
				return "circumvention/defaults"

			case .map:
				return "circumvention/map"

			case .builtin:
				return "circumvention/builtin"

			case .countries:
				return "circumvention/countries"
			}
		}

		var body: Body? {
			switch self {
			case .fetch:
				return Wrapper(FetchRequest())

			case .check(let challenge, let solution):
				return Wrapper(CheckRequest(challenge, solution))

			case .settings(let country):
				return SettingsRequest(country: country)

			case .defaults:
				return SettingsRequest()

			default:
				return nil
			}

		}
	}

	public static let moatBaseUrl = URL(string: "https://bridges.torproject.org/moat")

	public static var encoder = JSONEncoder()

	public static var decoder = JSONDecoder()


	open class func buildRequest(_ endpoint: Endpoint) -> URLRequest? {
		guard let url = moatBaseUrl?.appendingPathComponent(endpoint.path) else {
			return nil
		}

		var request = URLRequest(url: url)

		if let body = endpoint.body,
		   let body = try? encoder.encode(body)
        {
			request.httpMethod = "POST"
			request.httpBody = body
			request.addValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
			request.addValue(String(body.count), forHTTPHeaderField: "Content-Length")
		}

//		print("[\(String(describing: self))] request=\(request), body=\(String(data: (request.httpBody ?? "(nil)".data(using: .utf8)) ?? Data(), encoding: .utf8) ?? "(nil)")")

		return request
	}

	open class Body: Codable {
	}


	open class Errors: Codable {

		public let errors: [MoatError]
	}

	open class MoatError: LocalizedError, Codable {

		public let id: String?

		public let type: String?

		public let version: String?

		public let code: Int?

		public let status: String?

		public let detail: String?

		public var errorDescription: String? {
			if let detail = detail, !detail.isEmpty {
				return detail
			}

			var msg = [String]()

			if let code = code {
				msg.append(String(code))
			}

			if let status = status {
				msg.append(status)
			}

			return msg.joined(separator: " ")
		}
	}

	open class Wrapper<T: Codable>: Body, CustomStringConvertible {

		public enum CodingKeys: String, CodingKey {
			case data
		}

		public let data: [T]

		public var description: String {
			return "[\(String(describing: type(of: self))) data=\(data)]"
		}

		public init(_ item: T) {
			data = [item]

			super.init()
		}

		required public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			data = try container.decode([T].self, forKey: .data)

			try super.init(from: decoder)
		}

		open override func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			try container.encode(data, forKey: .data)

			try super.encode(to: encoder)
		}
	}

	open class FetchRequest: Codable, CustomStringConvertible {

		public let type: String

		public let version: String

		public let supported: [String]

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) type=\(type), version=\(version), supported=\(supported)]"
		}

		public init() {
			type = "client-transports"
			version = "0.1.0"
			supported = ["obfs4"]
		}
	}

	@available(*, deprecated, message: "CAPTCHA use is now deprecated by Tor Project and can be replaced by using the obfs4/bridgedb piece of a `.defaults` response.")
	open class FetchResponse: Codable {

		public let id: String?

		public let type: String?

		public let version: String?

		public let transport: String?

		public let image: String?

		public let challenge: String?

		public var captcha: Data? {
			guard let image = image else {
				return nil
			}

			return Data(base64Encoded: image, options: .ignoreUnknownCharacters)
		}
	}

	open class CheckRequest: Codable, CustomStringConvertible {

		public let type: String

		public let id: String

		public let version: String

		public let transport: String

		public let challenge: String

		public let qrcode: String

		public let solution: String

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) type=\(type), id=\(id), version=\(version), transport=\(transport), challenge=\(challenge), qrcode=\(qrcode), solution=\(solution)]"
		}

		public init(_ challenge: String, _ solution: String) {
			type = "moat-solution"
			id = "2"
			version = "0.1.0"
			transport = "obfs4"
			self.challenge = challenge
			qrcode = "false"
			self.solution = solution
		}
	}

	@available(*, deprecated, message: "CAPTCHA use is now deprecated by Tor Project and can be replaced by using the obfs4/bridgedb piece of a `.defaults` response.")
	open class CheckResponse: Codable {

		public let id: String

		public let type: String

		public let version: String

		public let bridges: [String]

		public let qrcode: String?
	}

	open class SettingsRequest: Body, CustomStringConvertible {

		public enum CodingKeys: String, CodingKey {
			case country
			case transports
		}

		public let country: String?

		public let transports: [String]?

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) country=\(country ?? "(nil)"), transports=\(transports?.description ?? "(nil)")]"
		}

		public init(country: String? = nil) {
			self.country = country
			transports = ["obfs4", "snowflake"]

			super.init()
		}


		required public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			country = try container.decode(String.self, forKey: .country)
			transports = try container.decode([String].self, forKey: .transports)

			try super.init(from: decoder)
		}

		open override func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			try container.encode(country, forKey: .country)
			try container.encode(transports, forKey: .transports)

			try super.encode(to: encoder)
		}
	}

	open class SettingsResponse: Codable, CustomStringConvertible {

		public let settings: [Setting]?

		public let country: String?

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) settings=\(settings?.description ?? "(nil)"), country=\(country ?? "(nil)")]"
		}
	}

	open class Setting: Codable, CustomStringConvertible {

		public enum CodingKeys: String, CodingKey {
			case bridge = "bridges"
		}

		public let bridge: Bridge

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) bridge=\(bridge)]"
		}
	}

	open class Bridge: Codable, CustomStringConvertible {

		public enum CodingKeys: String, CodingKey {
			case type
			case source
			case bridges = "bridge_strings"
		}

		public let type: String

		public let source: String

		public let bridges: [String]?

		public var description: String {
			return "[\(String(describing: Swift.type(of: self))) type=\(type), source=\(source), bridges=\(bridges?.description ?? "(nil)")]"
		}
	}
}
