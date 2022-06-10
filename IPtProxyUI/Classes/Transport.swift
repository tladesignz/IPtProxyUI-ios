//
//  Transport.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy

public enum Transport: Int, CaseIterable, Comparable {


	public static var builtInObfs4BridgesFile: URL? {
		return Bundle.iPtProxyUI.url(forResource: "obfs4-bridges", withExtension: "plist")
	}

	public static var builtInObfs4Bridges: [String] = {
		guard let file = builtInObfs4BridgesFile else {
			return []
		}

		return NSArray(contentsOf: file) as? [String] ?? []
	}()

	public static let stunServers = "stun:stun.l.google.com:19302,stun:stun.voip.blackberry.com:3478,stun:stun.altar.com.pl:3478,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.sonetel.net:3478,stun:stun.stunprotocol.org:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478"

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .custom]

	public static func asArguments(key: String, value: String) -> [String] {
		return ["--\(key)", value]
	}

	public static func asConf(key: String, value: String) -> [String: String] {
		return ["key": key, "value": "\"\(value)\""]
	}


	// MARK: Comparable

	public static func < (lhs: Transport, rhs: Transport) -> Bool {
		order.firstIndex(of: lhs) ?? lhs.rawValue < order.firstIndex(of: rhs) ?? rhs.rawValue
	}


	case none = 0
	case obfs4 = 1
	case snowflake = 2
	case custom = 3
	case snowflakeAmp = 4
    case dnstt = 5


	public var description: String {
		switch self {
		case .obfs4:
			return NSLocalizedString("via Obfs4 bridges", bundle: Bundle.iPtProxyUI, comment: "")

		case .snowflake:
			return NSLocalizedString("via Snowflake bridges", bundle: Bundle.iPtProxyUI, comment: "")

		case .snowflakeAmp:
			return NSLocalizedString("via Snowflake bridges (AMP rendezvous)", bundle: Bundle.iPtProxyUI, comment: "")

        case .dnstt:
            return NSLocalizedString("via a dnstt bridge (experimental)", comment: "")

		case .custom:
			return NSLocalizedString("via custom bridges", bundle: Bundle.iPtProxyUI, comment: "")

		default:
			return ""
		}
	}


	public func start() {
		switch self {
		case .obfs4, .custom:
			IPtProxyStartObfs4Proxy("DEBUG", false, true, nil)

		case .snowflake:
			IPtProxyStartSnowflake(
				Self.stunServers,
				"https://snowflake-broker.torproject.net.global.prod.fastly.net/",
				"cdn.sstatic.net", nil, nil, true, false, false, 1)

		case .snowflakeAmp:
			IPtProxyStartSnowflake(
				Self.stunServers,
				"https://snowflake-broker.torproject.net/",
				"www.google.com", "https://cdn.ampproject.org/", nil, true, false, false, 1)

        case .dnstt:
            IPtProxyStartDnstt("https://cloudflare-dns.com/dns-query", nil)

		default:
			break
		}
	}

	public func stop() {
		switch self {
		case .obfs4, .custom:
			IPtProxyStopObfs4Proxy()

		case .snowflake, .snowflakeAmp:
			IPtProxyStopSnowflake()

        case .dnstt:
            IPtProxyStopDnstt()

		default:
			break
		}
	}

	public func torConf<T>(_ cv: (String, String) -> T) -> [T] {
		var conf = [T]()

		switch self {
		case .obfs4, .custom:
			conf.append(cv("ClientTransportPlugin", "obfs4 socks5 127.0.0.1:\(IPtProxyObfs4Port())"))

			if self == .obfs4 {
				conf += Self.builtInObfs4Bridges.map({ cv("Bridge", $0) })
			}
			else if let customBridges = Settings.customBridges {
				conf += customBridges.map({ cv("Bridge", $0) })
			}

		case .snowflake, .snowflakeAmp:
			conf.append(cv("ClientTransportPlugin", "snowflake socks5 127.0.0.1:\(IPtProxySnowflakePort())"))
			conf.append(cv("Bridge", "snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72"))

        case .dnstt:
			conf.append(cv("ClientTransportPlugin", "dnstt socks5 127.0.0.1:\(IPtProxyDnsttPort())"))
			conf.append(cv("Bridge", "dnstt 192.0.2.4:1 E5C9F39FE0AD6D7596859BAEC762CFBCDD928229 pubkey=00458e603fd162507a1fda7ab0df486691d0646bfa10405b3c1225cbaf78ff38 domain=d.openinternetproject.org"))

		default:
			break
		}

		return conf
	}
}
