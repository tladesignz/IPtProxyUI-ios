//
//  MoatTunnel.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 22.01.26.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

extension String {

	var middle: String.Index {
		index(startIndex, offsetBy: count / 2)
	}

	var firstHalf: String {
		String(self[..<middle])
	}

	var secondHalf: String {
		String(self[middle...])
	}
}

public enum MoatTunnel: String {
	case meek
	case dnstt

	static let meekConf = "url=https://1723079976.rsc.cdn77.org;front=www.phpmyadmin.net"
	private static let dnsttConf = ""

	var transport: Transport {
		switch self {
		case .meek:
			return .meek

		case .dnstt:
			return .dnstt
		}
	}

	var baseUrl: URL? {
		switch self {
		case .meek:
			return URL(string: "https://bridges.torproject.org")

		case .dnstt:
			return URL(string: "")
		}
	}

	var proxyConf: [AnyHashable: Any] {
		let user: String
		let password: String

		switch self {
		case .meek:
			user = Self.meekConf.firstHalf
			password = Self.meekConf.secondHalf

		case .dnstt:
			user = Self.dnsttConf.firstHalf
			password = Self.dnsttConf.secondHalf
		}

		return [
			kCFProxyTypeKey as AnyHashable: kCFProxyTypeSOCKS,
			kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5,
			kCFStreamPropertySOCKSProxyHost: "127.0.0.1",
			kCFStreamPropertySOCKSProxyPort: transport.port,
			kCFStreamPropertySOCKSUser: user,
			kCFStreamPropertySOCKSPassword: password,
		]
	}
}
