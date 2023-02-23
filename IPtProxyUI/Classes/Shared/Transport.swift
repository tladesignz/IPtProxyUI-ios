//
//  Transport.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
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

	public static let stunServers = "stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.net:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478"

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .custom]

	public static func asArguments(key: String, value: String) -> [String] {
		return ["--\(key)", value]
	}

	public static func asConf(key: String, value: String) -> [String: String] {
		return ["key": key, "value": "\"\(value)\""]
	}

	private static let snowflakeLogFileName = "snowflake.log"


	// MARK: Comparable

	public static func < (lhs: Transport, rhs: Transport) -> Bool {
		order.firstIndex(of: lhs) ?? lhs.rawValue < order.firstIndex(of: rhs) ?? rhs.rawValue
	}


	case none = 0
	case obfs4 = 1
	case snowflake = 2
	case custom = 3
	case snowflakeAmp = 4


	public var description: String {
		switch self {
		case .obfs4:
			return NSLocalizedString("Obfs4 bridges", bundle: .iPtProxyUI, comment: "")

		case .snowflake:
			return NSLocalizedString("Snowflake bridges", bundle: .iPtProxyUI, comment: "")

		case .snowflakeAmp:
			return NSLocalizedString("Snowflake bridges (AMP rendezvous)", bundle: .iPtProxyUI, comment: "")

		case .custom:
			return NSLocalizedString("custom bridges", bundle: .iPtProxyUI, comment: "")

		default:
			return ""
		}
	}

	/**
	 Returns the location of the log file of the transport, if it can provide any.

	 ATTENTION: You will need to have set `Settings.stateLocation` to a writable directory before calling this!
	 Otherwise this will return nonsense.
	 */
	public var logFile: URL? {
		switch self {
		case .obfs4, .custom:
			return Settings.stateLocation.appendingPathComponent(IPtProxyObfs4proxyLogFile())

		case .snowflake, .snowflakeAmp:
			return Settings.stateLocation.appendingPathComponent(Self.snowflakeLogFileName)

		default:
			return nil
		}
	}

	/**
	 Start the transport, if it is startable.

	 - parameter log: OPTIONAL. A file URL to write the log to (for Snowflake) or just anything non-nil to enable Obfs4proxy logging.
	 */
	public func start(log: Bool = false) {
		switch self {
		case .obfs4, .custom:
			IPtProxyStartObfs4Proxy("WARN", log, false, nil)

		case .snowflake:
			IPtProxyStartSnowflake(
				Self.stunServers,
				"https://snowflake-broker.torproject.net.global.prod.fastly.net/",
				"cdn.sstatic.net", nil,
				log ? Self.snowflakeLogFileName : nil, true, false, false, 1)

		case .snowflakeAmp:
			IPtProxyStartSnowflake(
				Self.stunServers,
				"https://snowflake-broker.torproject.net/",
				"www.google.com", "https://cdn.ampproject.org/",
				log ? Self.snowflakeLogFileName : nil, true, false, false, 1)

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

		default:
			break
		}

		return conf
	}
}
