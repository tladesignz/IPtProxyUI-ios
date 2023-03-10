//
//  BuiltInBridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2023-03-10.
//  Copyright © 2019-2023 Guardian Project. All rights reserved.
//

import Foundation

open class BuiltInBridges: Codable {

	public static var file: URL? {
		return Bundle.iPtProxyUI.url(forResource: "builtin-bridges", withExtension: "json")
	}

	private static var _shared: BuiltInBridges?
	public static var shared: BuiltInBridges? {
		if _shared == nil,
		   let file = file,
		   let data = try? Data(contentsOf: file)
		{
			do {
				_shared = try MoatApi.decoder.decode(Self.self, from: data)
			}
			catch {
				print(error)
			}
		}

		return _shared
	}


	open var meekAzure: [Bridge]?
	open var obfs4: [Bridge]?
	open var snowflake: [Bridge]?


	// MARK: Codable

	enum CodingKeys: String, CodingKey {
		case meekAzure = "meek-azure"
		case obfs4
		case snowflake
	}
}

open class Bridge: Codable, CustomStringConvertible {

	open var raw: String

	open var rawPieces: [Substring] {
		raw.split(separator: " ")
	}

	open var transport: String? {
		if let transport = rawPieces.first {
			return String(transport)
		}

		return nil
	}

	open var address: String? {
		let rawPieces = rawPieces

		return rawPieces.count > 1 ? String(rawPieces[1]) : nil
	}

	open var ip: String? {
		if let ip = address?.split(separator: ":").first {
			return String(ip)
		}

		return nil
	}

	open var port: Int? {
		if let port = address?.split(separator: ":").last {
			return Int(port)
		}

		return nil
	}

	open var fingerprint: String? {
		let rawPieces = rawPieces

		return rawPieces.count > 2 ? String(rawPieces[2]) : nil
	}

	open var url: URL? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("url=") }),
			let url = piece.split(separator: "=").last
		{
			return URL(string: String(url))
		}

		return nil
	}

	open var front: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("front=") }),
			let front = piece.split(separator: "=").last
		{
			return String(front)
		}

		return nil
	}

	open var cert: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("cert=") }),
			let cert = piece.split(separator: "=").last
		{
			return String(cert)
		}

		return nil
	}

	open var iatMode: Int? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("iat-mode=") }),
			let iatMode = piece.split(separator: "=").last
		{
			return Int(iatMode)
		}

		return nil
	}

	open var ice: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("ice=") }),
			let ice = piece.split(separator: "=").last
		{
			return String(ice)
		}

		return nil
	}

	open var utlsImitate: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("utls-imitate=") }),
			let utlsImitate = piece.split(separator: "=").last
		{
			return String(utlsImitate)
		}

		return nil
	}


	// MARK: Decodable

	required public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		raw = try container.decode(String.self)
	}


	// MARK: Encodable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		try container.encode(raw)
	}


	// MARK: CustomStringConvertible

	public var description: String {
		"[\(String(describing: type(of: self)))] raw=\(raw), transport=\(transport ?? "(nil)"), "
		+ "ip=\(ip ?? "(nil)"), port=\(port ?? -1), fingerprint=\(fingerprint ?? "(nil)"), "
		+ "url=\(url?.absoluteString ?? "(nil)"), front=\(front ?? "(nil)"), cert=\(cert ?? "(nil)"), "
		+ "iatMode=\(iatMode ?? -1), ice=\(ice ?? "(nil)"), utlsImitate=\(utlsImitate ?? "(nil)")"
	}

}
