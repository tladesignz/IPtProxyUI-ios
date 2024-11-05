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

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .meekAzure, .custom, .onDemand]

	public static func asArguments(key: String, value: String) -> [String] {
		return ["--\(key)", value]
	}

	public static func asConf(key: String, value: String) -> [String: String] {
		return ["key": key, "value": "\"\(value)\""]
	}

	public static var stateLocation = URL(fileURLWithPath: "")

	/**
	 Your custom bridges, in case these cannot be found in `Settings.customBridges`.
	 */
	public static var customBridges: [String]?


	private static var customTransports: [String] {
		(customBridges ?? Settings.customBridges)?.compactMap({ Bridge($0).transport }) ?? []
	}

	// Seems more reliable in certain countries than the currently advertised one.
	private static let addFronts = ["github.githubassets.com"]

	private static let ampBroker = "https://snowflake-broker.torproject.net/"
	private static let ampFronts = ["www.google.com"]

	private static let controller: IPtProxyController? = {
		return IPtProxyController(stateLocation.path, enableLogging: true, unsafeLogging: false, logLevel: "DEBUG")
	}()


	// MARK: Comparable

	public static func < (lhs: Transport, rhs: Transport) -> Bool {
		order.firstIndex(of: lhs) ?? lhs.rawValue < order.firstIndex(of: rhs) ?? rhs.rawValue
	}


	case none = 0
	case obfs4 = 1
	case snowflake = 2
	case custom = 3
	case snowflakeAmp = 4
	case onDemand = 5
	case meekAzure = 6


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

		case .onDemand:
			return NSLocalizedString("On-demand bridges", bundle: .iPtProxyUI, comment: "")

		case .meekAzure:
			return NSLocalizedString("Meek azure bridge", bundle: .iPtProxyUI, comment: "")

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
		case .obfs4, .custom, .onDemand, .meekAzure, .snowflake, .snowflakeAmp:
			return Settings.stateLocation.appendingPathComponent(IPtProxyLogFileName)

		default:
			return nil
		}
	}

	public var port: Int {
		let method: String?

		switch self {
		case .none:
			method = nil

		case .obfs4, .onDemand:
			method = IPtProxyObfs4

		case .custom:
			method = Self.customTransports.first

		case .snowflake, .snowflakeAmp:
			method = IPtProxySnowflake

		case .meekAzure:
			method = IPtProxyMeekLite
		}

		return Self.controller?.port(method) ?? 0
	}

	/**
	 Start the transport, if it is startable.
	 */
	public func start() throws {
		switch self {
		case .obfs4, .onDemand:
			try Self.controller?.start(IPtProxyObfs4, proxy: nil)

		case .custom:
			for transport in Self.customTransports {
				try Self.controller?.start(transport, proxy: nil)
			}

		case .meekAzure:
			try Self.controller?.start(IPtProxyMeekLite, proxy: nil)

		case .snowflake:
			let snowflake = BuiltInBridges.shared?.snowflake?.first

			// Seems more reliable in certain countries than the currently advertised one.
			var fronts = Set(Self.addFronts)
			if let f = snowflake?.front {
				fronts.insert(f)
			}
			if let f = snowflake?.fronts {
				fronts.formUnion(f)
			}

			Self.controller?.snowflakeIceServers = snowflake?.ice ?? ""
			Self.controller?.snowflakeBrokerUrl = snowflake?.url?.absoluteString ?? ""
			Self.controller?.snowflakeFrontDomains = fronts.joined(separator: ",")
			Self.controller?.snowflakeAmpCacheUrl = ""

			try Self.controller?.start(IPtProxySnowflake, proxy: nil)

		case .snowflakeAmp:
			Self.controller?.snowflakeIceServers = BuiltInBridges.shared?.snowflake?.first?.ice ?? ""
			Self.controller?.snowflakeBrokerUrl = Self.ampBroker
			Self.controller?.snowflakeFrontDomains = Self.ampFronts.joined(separator: ",")
			Self.controller?.snowflakeAmpCacheUrl = "https://cdn.ampproject.org/"

			try Self.controller?.start(IPtProxySnowflake, proxy: nil)

		default:
			break
		}
	}

	public func stop() {
		switch self {
		case .obfs4, .onDemand:
			Self.controller?.stop(IPtProxyObfs4)

		case .custom:
			for transport in Self.customTransports {
				Self.controller?.stop(transport)
			}

		case .meekAzure:
			Self.controller?.stop(IPtProxyMeekLite)

		case .snowflake, .snowflakeAmp:
			Self.controller?.stop(IPtProxySnowflake)

		default:
			break
		}
	}

	public func torConf<T>(_ cv: (String, String) -> T, onDemandBridges: [String]? = nil) -> [T] {
		var conf = [T]()

		switch self {
		case .obfs4, .custom, .onDemand:
			if self == .onDemand,
			   let onDemandBridges = onDemandBridges ?? Settings.onDemandBridges,
			   !onDemandBridges.isEmpty
			{
				conf.append(ctp(IPtProxyObfs4, port, cv))
				conf += onDemandBridges.map({ cv("Bridge", $0) })
			}
			else if self == .custom,
					let customBridges = Self.customBridges ?? Settings.customBridges,
					!customBridges.isEmpty
			{
				// Try supporting other bridges than Obfs4 with custom bridges.
				for transport in Self.customTransports {
					conf.append(ctp(transport, Self.controller?.port(transport) ?? 0, cv))
				}

				conf += customBridges.map({ cv("Bridge", $0) })
			}
			else {
				conf.append(ctp(IPtProxyObfs4, port, cv))
				conf += BuiltInBridges.shared?.obfs4?.map({ cv("Bridge", $0.raw) }) ?? []
			}

		case .snowflake:
			conf.append(ctp(IPtProxySnowflake, port, cv))
			conf += BuiltInBridges.shared?.snowflake?
				.compactMap({
					let builder = Bridge.Builder(from: $0)

					builder?.fronts.formUnion(Self.addFronts)

					return builder?.build().raw
				})
				.map({ cv("Bridge", $0) }) ?? []

		case .snowflakeAmp:
			conf.append(ctp(IPtProxySnowflake, port, cv))
			conf += BuiltInBridges.shared?.snowflake?
				.compactMap({
					let builder = Bridge.Builder(from: $0)

					builder?.url = URL(string: Self.ampBroker)
					builder?.fronts = Set(Self.ampFronts)

					return builder?.build().raw
				})
				.map({ cv("Bridge", $0) }) ?? []

		case .meekAzure:
			conf.append(ctp(IPtProxyMeekLite, port, cv))
			conf += BuiltInBridges.shared?.meekAzure?.map({ cv("Bridge", $0.raw) }) ?? []

		default:
			break
		}

		return conf
	}

	private func ctp<T>(_ transport: String, _ port: Int, _ cv: (String, String) -> T) -> T {
		return cv("ClientTransportPlugin", "\(transport) socks5 127.0.0.1:\(port)")
	}
}
