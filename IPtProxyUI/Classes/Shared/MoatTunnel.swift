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

public enum MoatTunnel: String, CaseIterable {
	case torProject
	case guardianProject

	private static let torProjectConf = "url=https://1723079976.rsc.cdn77.org;front=www.phpmyadmin.net"
	private static let guardianProjectConf = "doh=https://dns.google/dns-query;pubkey=c07ae9dd7b86ded6121c3db173de048bfd4f41de38dd430e3dfaf83ec8f36a06;domain=t1.bypasscensorship.org"

	var transport: Transport {
		switch self {
		case .torProject:
			return .meek

		case .guardianProject:
			return .dnstt
		}
	}

	var baseUrl: URL? {
		switch self {
		case .torProject:
			return URL(string: "https://bridges.torproject.org")

		case .guardianProject:
			return URL(string: "https://tns1.bypasscensorship.org")
		}
	}

	var proxyConf: [AnyHashable: Any] {
		let user: String
		let password: String

		switch self {
		case .torProject:
			user = Self.torProjectConf.firstHalf
			password = Self.torProjectConf.secondHalf

		case .guardianProject:
			user = Self.guardianProjectConf.firstHalf
			password = Self.guardianProjectConf.secondHalf
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
