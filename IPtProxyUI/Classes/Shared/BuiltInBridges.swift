//
//  BuiltInBridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2023-03-10.
//  Copyright © 2019-2023 Guardian Project. All rights reserved.
//

import Foundation

open class BuiltInBridges: Codable {

	public class var file: URL? {
		Bundle.iPtProxyUI.url(forResource: "builtin-bridges", withExtension: "json")
	}

	public class var updateFile: URL? {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("updated-bridges.json")
	}

	public class var outdated: Bool {
		let modified = (try? updateFile?.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
		?? Date(timeIntervalSince1970: 0)

		return Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 2 > 1
	}

	private static var _shared: BuiltInBridges?
	public class var shared: BuiltInBridges? {
		if _shared == nil {
			_shared = read(updateFile)
		}

		if _shared == nil {
			_shared = read(file)
		}

		return _shared
	}


	open var meekAzure: [Bridge]? {
		didSet {
			store()
		}
	}

	open var obfs4: [Bridge]? {
		didSet {
			store()
		}
	}

	open var snowflake: [Bridge]? {
		didSet {
			store()
		}
	}

	open var webtunnel: [Bridge]? {
		didSet {
			store()
		}
	}


	// MARK: Codable

	enum CodingKeys: String, CodingKey {
		case meekAzure = "meek-azure"
		case obfs4
		case snowflake
		case webtunnel
	}


	open class func reload() {
		_shared = nil
		_ = shared
	}


	open class func read(_ file: URL?) -> BuiltInBridges? {
		guard let file = file,
			  let data = try? Data(contentsOf: file)
		else {
			return nil
		}

		do {
			return try MoatApi.decoder.decode(Self.self, from: data)
		}
		catch {
			print("[\(String(describing: type(of: self)))] \(error)")
		}

		return nil
	}


	open func store() {
		guard let file = Self.updateFile else {
			print("[\(String(describing: type(of: self)))] No caching directory available to store to!")

			return
		}

		do {
			let data = try MoatApi.encoder.encode(self)

			try data.write(to: file, options: .atomic)
		}
		catch {
			print("[\(String(describing: type(of: self)))] \(error)")
		}
	}
}

open class Bridge: Codable, CustomStringConvertible {

	open class Builder {

		public private(set) var pieces: [String]
		open var fingerprint2: String? = nil
		open var url: URL? = nil
		open var fronts = Set<String>()
		open var cert: String? = nil
		open var iatMode: Int? = nil
		open var ice: String? = nil
		open var utlsImitate: String? = nil
		open var ver: String? = nil

		public init(transport: String, ip: String, port: Int, fingerprint1: String) {
			pieces = [transport, "\(ip):\(port)", fingerprint1]
		}

		convenience init?(from bridge: Bridge) {
			guard let transport = bridge.transport,
				  let ip = bridge.ip,
				  let port = bridge.port,
				  let fingerprint1 = bridge.fingerprint1
			else {
				return nil
			}

			self.init(transport: transport, ip: ip, port: port, fingerprint1: fingerprint1)

			fingerprint2 = bridge.fingerprint2

			url = bridge.url

			if let front = bridge.front, !front.isEmpty {
				fronts.insert(front)
			}

			if let oldFronts = bridge.fronts, !oldFronts.isEmpty {
				fronts.formUnion(oldFronts)
			}

			cert = bridge.cert
			iatMode = bridge.iatMode
			ice = bridge.ice
			utlsImitate = bridge.utlsImitate
			ver = bridge.ver
		}

		open func build() -> Bridge {
			var params = [String]()

			if let fingerprint2 = fingerprint2, !fingerprint2.isEmpty {
				params.append("fingerprint=\(fingerprint2)")
			}

			if let url = url, !url.absoluteString.isEmpty {
				params.append("url=\(url.absoluteString)")
			}

			let fronts = fronts.filter { !$0.isEmpty }

			if !fronts.isEmpty {
				params.append("fronts=\(fronts.joined(separator: ","))")
			}

			if let cert = cert, !cert.isEmpty {
				params.append("cert=\(cert)")
			}

			if let iatMode = iatMode {
				params.append("iat-mode=\(iatMode)")
			}

			if let ice = ice, !ice.isEmpty {
				params.append("ice=\(ice)")
			}

			if let utlsImitate = utlsImitate, !utlsImitate.isEmpty {
				params.append("utls-imitate=\(utlsImitate)")
			}

			if let ver = ver, !ver.isEmpty {
				params.append("ver=\(ver)")
			}

			params.insert(contentsOf: pieces, at: 0)

			return Bridge(params.joined(separator: " "))
		}
	}

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

	open var fingerprint1: String? {
		let rawPieces = rawPieces

		return rawPieces.count > 2 ? String(rawPieces[2]) : nil
	}

	open var fingerprint2: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("fingerprint=") }),
		   let fingerprint2 = piece.split(separator: "=").last
		{
			return String(fingerprint2)
		}

		return nil
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

	open var fronts: [String]? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("fronts=") }),
		   let fronts = piece.split(separator: "=").last
		{
			return fronts.split(separator: ",")
				.filter({ !$0.isEmpty })
				.map({ String($0) })
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

	open var ver: String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("ver=") }),
		   let ver = piece.split(separator: "=").last
		{
			return String(ver)
		}

		return nil
	}


	public init(_ raw: String) {
		self.raw = raw
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
		+ "ip=\(ip ?? "(nil)"), port=\(port ?? -1), fingerprint1=\(fingerprint1 ?? "(nil)"), "
		+ "fingerprint2=\(fingerprint2 ?? "(nil)"), url=\(url?.absoluteString ?? "(nil)"), "
		+ "front=\(front ?? "(nil)"), cert=\(cert ?? "(nil)"), iatMode=\(iatMode ?? -1), "
		+ "ice=\(ice ?? "(nil)"), utlsImitate=\(utlsImitate ?? "(nil)"), ver=\(ver ?? "(nil)")"
	}
}
