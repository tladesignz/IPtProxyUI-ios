//
//  BuiltInBridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2023-03-10.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation
import OSLog

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

	public static let dnsCountries = ["ae", "af", "bd", "cn", "co", "id", "ir", "kw", "pk", "qa", "ru", "sy", "tr", "ug", "uz"]

	/**
	 * https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/trac/-/issues/40001#note_2811603
	 *
	 * "Use 192.0.2.4:1 for the placeholder bridge IP address. 192.0.2.3:1 is used for Snowflake, and
	 *  tor does not handle well the case of different bridges having the same address, even if the
	 *  address is not really used. We have been incrementing the last octet of placeholder addresses for
	 *  each new transport that uses placeholder addresses: .1 = flashproxy, .2 = meek, .3 = snowflake,
	 *  .4 = dnstt. If there are multiple dnstt bridges in the same torrc, increment the port number"
	 */
	public static let dnsttBridges = [
		Bridge("dnstt 192.0.2.4:1 A998F319ADB60EE344540EC4B21524CC484F96BE doh=https://dns.google/dns-query pubkey=241169008830694749fe96bb070c4855c5bb5b9c47b3833ed7d88521ba30a43f domain=t.ruhnama.net"),
		Bridge("dnstt 192.0.2.4:2 80EEFA4F4875ED2B7B5A86DF2D7588AD32E29F15 doh=https://dns.google/dns-query pubkey=a2fb71077eeaa54a02cda7a90be306af5d299ab21822a8b277d4eacbc9168631 domain=t2.bypasscensorship.org"),
	]

	/**
	 Tor will max at 32 simultaneous SOCKS connections to PTs.

	 Leave a buffer, though, for other connections. Seems Tor wants that.
	 */
	public static let maxDnsttBridgesCount = 32 - 2


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


	open var meek: [Bridge]? {
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

	open var dnstt: [Bridge]? {
		didSet {
			store()
		}
	}


	// MARK: Codable

	enum CodingKeys: String, CodingKey {
		case meek
		case obfs4
		case snowflake
		case webtunnel
		case dnstt
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
			Logger(subsystem: "IPtProxyUI", category: String(describing: type(of: self)))
				.error("\(error)")
		}

		return nil
	}


	open func store() {
		guard let file = Self.updateFile else {
			Logger(subsystem: "IPtProxyUI", category: String(describing: type(of: self)))
				.error("No caching directory available to store to!")

			return
		}

		do {
			let data = try MoatApi.encoder.encode(self)

			try data.write(to: file, options: .atomic)
		}
		catch {
			Logger(subsystem: "IPtProxyUI", category: String(describing: type(of: self)))
				.error("\(error)")
		}
	}

	/**
	 Creates a list of DNSTT bridge lines using UDP DNS servers which are known to work in the given country.

	 Since Tor only creates up to ``BuiltInBridges.maxDnsttBridgesCount`` connections simultaneously, if the list
	 of DNS servers times number of DNSTT servers we know is larger than that, a random sample of that size of the actual result is returned.

	 Note: There is a `global` list of UDP DNS servers, which you can theoretically fetch, but since UDP is not encrypted, it's typically a better
	 idea to use DoH or DoT servers instead. (Like our base ``BuiltInBridges.dnsttBridges`` list does.)

	 The UDP servers only make sense to use in a heavily censored environment, where public DoH and DoT DNS servers are blocked.

	 That's what these UDP lists are for. Insofar the `global` list is only there for the sake of completeness, not so much because it makes
	 sense to use it.

	 Here's a list of publicly available DoH servers, in case you're unhappy with our choice:
	 https://github.com/curl/curl/wiki/DNS-over-HTTPS#publicly-available-servers

	 - parameter countryCode: The country code for a country as listed in ``BuiltInBridges.dnsCountries`` or `global`.
	 - returns: A list of DNSTT bridge lines using UDP DNS servers which are known to work in the given country.
	 */
	class func getUdpDnstt(for countryCode: String?) -> [Bridge]? {
		guard let countryCode,
			  countryCode == "global" || Self.dnsCountries.contains(countryCode),
			  let url = Bundle.iPtProxyUI.url(forResource: "dns-\(countryCode)", withExtension: "json"),
			  let data = try? Data(contentsOf: url),
			  let dnsInfo = try? MoatApi.decoder.decode(DnsInfo.self, from: data)
		else {
			return nil
		}

		var i = Self.dnsttBridges.count

		var bridges = [Bridge]()

		for server in dnsInfo.servers {
			let addr = URLComponents(string: "scheme://\(server.ip)")

			for bridge in Self.dnsttBridges {
				if let builder = bridge.buildUpon() {
					builder.port = i

					// Don't set a fingerprint, otherwise only the first bridge lines with unique fingerprints will be used.
					builder.fingerprint1 = nil

					builder.doh = nil
					builder.dot = nil
					builder.udp = "\(addr?.host ?? server.ip):\(addr?.port ?? 53)"

					i += 1

					bridges.append(builder.build())
				}
			}
		}

		if bridges.count <= maxDnsttBridgesCount {
			return bridges
		}

		var selection = Set<Bridge>()

		while selection.count < maxDnsttBridgesCount {
			if let bridge = bridges.randomElement() {
				selection.insert(bridge)
			}
		}

		return Array(selection)
	}
}

open class Bridge: Codable, CustomStringConvertible, Hashable {

	// MARK: Equatable

	public static func == (lhs: Bridge, rhs: Bridge) -> Bool {
		lhs.transport == rhs.transport && lhs.ip == rhs.ip && lhs.port == rhs.port
	}


	// MARK: Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(transport)
		hasher.combine(ip)
		hasher.combine(port)
	}


	open class Builder {

		open var transport: String?
		open var ip: String
		open var port: Int
		open var fingerprint1: String? = nil
		open var fingerprint2: String? = nil
		open var url: URL? = nil
		open var front: String? = nil
		open var fronts = Set<String>()
		open var cert: String? = nil
		open var iatMode: Int? = nil
		open var ice: String? = nil
		open var utls: String? = nil
		open var utlsImitate: String? = nil
		open var ver: String? = nil

		// DNSTT
		open var udp: String? = nil
		open var doh: String? = nil
		open var dot: String? = nil
		open var pubkey: String? = nil
		open var domain: String? = nil

		public init(transport: String? = nil, ip: String, port: Int, fingerprint1: String? = nil) {
			self.transport = transport
			self.ip = ip
			self.port = port
			self.fingerprint1 = fingerprint1
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

			front = bridge.front
			fronts = Set(bridge.fronts ?? [])

			cert = bridge.cert
			iatMode = bridge.iatMode
			ice = bridge.ice
			utls = bridge.utls
			utlsImitate = bridge.utlsImitate
			ver = bridge.ver
			udp = bridge.udp
			doh = bridge.doh
			dot = bridge.dot
			pubkey = bridge.pubkey
			domain = bridge.domain
		}

		open func build() -> Bridge {
			var params = [String]()

			if let transport = transport, !transport.isEmpty {
				params.append(transport)
			}

			params.append("\(ip):\(port)")

			if let fingerprint1, !fingerprint1.isEmpty {
				params.append(fingerprint1)
			}

			append(fingerprint2, to: &params, with: "fingerprint")
			append(url?.absoluteString, to: &params, with: "url")
			append(front, to: &params, with: "front")

			let fronts = fronts.filter { !$0.isEmpty }
			append(fronts.joined(separator: ","), to: &params, with: "fronts")

			append(cert, to: &params, with: "cert")

			if let iatMode {
				params.append("iat-mode=\(iatMode)")
			}

			append(ice, to: &params, with: "ice")
			append(utls, to: &params, with: "utls")
			append(utlsImitate, to: &params, with: "utls-imitate")
			append(ver, to: &params, with: "ver")
			append(udp, to: &params, with: "udp")
			append(doh, to: &params, with: "doh")
			append(dot, to: &params, with: "dot")
			append(pubkey, to: &params, with: "pubkey")
			append(domain, to: &params, with: "domain")

			return Bridge(params.joined(separator: " "))
		}

		private func append(_ value: String?, to array: inout [String], with name: String) {
			if let value, !value.isEmpty {
				array.append("\(name)=\(value)")
			}
		}
	}

	public static let fingerprintRegex = try? NSRegularExpression(pattern: "^[a-f0-9]{40}$", options: .caseInsensitive)

	open var raw: String

	open var rawPieces: [Substring] {
		var pieces = raw.split(separator: " ")

		// "Vanilla" bridges (conventional relays without obfuscation) don't have a transport.
		// Add an empty one, so parsing works.
		if pieces.count < 3 {
			pieces.insert("", at: 0)

			return pieces
		}

		return pieces
	}

	open var transport: String? {
		if let transport = rawPieces.first, !transport.isEmpty {
			return String(transport)
		}

		return nil
	}

	open var address: String? {
		let rawPieces = rawPieces

		return rawPieces.count > 1 ? String(rawPieces[1]) : nil
	}

	open var ip: String? {
		guard var pieces = address?.split(separator: ":"),
			  !pieces.isEmpty
		else {
			return nil
		}

		// Remove port.
		pieces = pieces.dropLast()

		// Join IPv6 again.
		return pieces.joined(separator: ":")
	}

	open var port: Int? {
		if let port = address?.split(separator: ":").last {
			return Int(port)
		}

		return nil
	}

	open var fingerprint1: String? {
		let rawPieces = rawPieces

		guard rawPieces.count > 2 else {
			return nil
		}

		let piece = String(rawPieces[2])
		let range = NSRange(piece.startIndex ..< piece.endIndex, in: piece)

		guard let match = Self.fingerprintRegex?.firstMatch(in: piece, range: range),
			  match.range == range
		else {
			return nil
		}

		return piece
	}

	open var fingerprint2: String? {
		getPiece("fingerprint")
	}

	open var url: URL? {
		guard let url = getPiece("url") else {
			return nil
		}

		return URL(string: url)
	}

	open var front: String? {
		getPiece("front")
	}

	open var fronts: [String]? {
		getPiece("fronts")?.split(separator: ",")
			.filter({ !$0.isEmpty })
			.map({ String($0) })
	}

	open var cert: String? {
		getPiece("cert")
	}

	open var iatMode: Int? {
		guard let iatMode = getPiece("iat-mode") else {
			return nil
		}

		return Int(iatMode)
	}

	open var ice: String? {
		getPiece("ice")
	}

	open var utls: String? {
		getPiece("utls")
	}

	open var utlsImitate: String? {
		getPiece("utls-imitate")
	}

	open var ver: String? {
		getPiece("ver")
	}

	open var udp: String? {
		getPiece("udp")
	}

	open var doh: String? {
		getPiece("dot")
	}

	open var dot: String? {
		getPiece("dot")
	}

	open var pubkey: String? {
		getPiece("pubkey")
	}

	open var domain: String? {
		getPiece("domain")
	}

	public init(_ raw: String) {
		self.raw = raw
	}

	public func buildUpon() -> Bridge.Builder? {
		.init(from: self)
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
		+ "front=\(front ?? "(nil)"), fronts=\(fronts ?? []), cert=\(cert ?? "(nil)"), "
		+ "iatMode=\(iatMode ?? -1), ice=\(ice ?? "(nil)"), utls=\(utls ?? "(nil)"), "
		+ "utlsImitate=\(utlsImitate ?? "(nil)"), ver=\(ver ?? "(nil)"), "
		+ "udp=\(udp ?? "(nil)"), doh=\(doh ?? "(nil)"), dot=\(dot ?? "(nil)"), "
		+ "pubkey=\(pubkey ?? "(nil)"), domain=\(domain ?? "(nil)")"
	}


	// MARK: Private Methods

	private func getPiece(_ name: String) -> String? {
		if let piece = rawPieces.first(where: { $0.hasPrefix("\(name)=") }),
		   let value = piece.split(separator: "=").last
		{
			return String(value)
		}

		return nil
	}
}

class DnsInfo: Codable {

	let country: String
	let countryCode: String
	let description: String
	let lastUpdated: String
	let servers: [DnsServer]
}

class DnsServer: Codable {

	let name: String
	let ip: String
}
