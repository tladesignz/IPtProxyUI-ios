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

	private static let logFileName = "ipt.log"

	// Seems more reliable in certain countries than the currently advertised one.
	private static let addFronts = ["github.githubassets.com"]

	private static let ampBroker = "https://snowflake-broker.torproject.net/"
	private static let ampFronts = ["www.google.com"]

	private static let iPtProxy: IPtProxyIPtProxy? = {
		let p = IPtProxyIPtProxy(stateLocation.path)
		p?.logLevel = "WARN"
		p?.init_()

		return p
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
			return Settings.stateLocation.appendingPathComponent(Self.logFileName)

		default:
			return nil
		}
	}

	public var port: Int {
		let method: String?

		switch self {
		case .none:
			method = nil

		case .obfs4, .custom, .onDemand:
			method = "obfs4"

		case .snowflake, .snowflakeAmp:
			method = "snowflake"

		case .meekAzure:
			method = "meek_lite"
		}

		return Self.iPtProxy?.getPort(method) ?? 0
	}

	/**
	 Start the transport, if it is startable.

	 - parameter log: OPTIONAL. A file URL to write the log to (for Snowflake) or just anything non-nil to enable Obfs4proxy logging.
	 */
	public func start(log: Bool = false) {
		Self.iPtProxy?.enableLogging = log

		switch self {
		case .obfs4, .custom, .onDemand:
			Self.iPtProxy?.start("obfs4", proxy: nil)

		case .meekAzure:
			Self.iPtProxy?.start("meek_lite", proxy: nil)

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

			Self.iPtProxy?.snowflakeIceServers = snowflake?.ice ?? ""
			Self.iPtProxy?.snowflakeBrokerUrl = snowflake?.url?.absoluteString ?? ""
			Self.iPtProxy?.snowflakeFrontDomains = fronts.joined(separator: ",")
			Self.iPtProxy?.snowflakeAmpCacheUrl = ""

			Self.iPtProxy?.start("snowflake", proxy: nil)

		case .snowflakeAmp:
			Self.iPtProxy?.snowflakeIceServers = BuiltInBridges.shared?.snowflake?.first?.ice ?? ""
			Self.iPtProxy?.snowflakeBrokerUrl = Self.ampBroker
			Self.iPtProxy?.snowflakeFrontDomains = Self.ampFronts.joined(separator: ",")
			Self.iPtProxy?.snowflakeAmpCacheUrl = "https://cdn.ampproject.org/"

			Self.iPtProxy?.start("snowflake", proxy: nil)

		default:
			break
		}
	}

	public func stop() {
		switch self {
		case .obfs4, .custom, .onDemand:
			Self.iPtProxy?.stop("obfs4")

		case .meekAzure:
			Self.iPtProxy?.stop("meek_lite")

		case .snowflake, .snowflakeAmp:
			Self.iPtProxy?.stop("snowflake")

		default:
			break
		}
	}

    public func torConf<T>(_ cv: (String, String) -> T, onDemandBridges: [String]? = nil, customBridges: [String]? = nil) -> [T] {
		var conf = [T]()

		switch self {
		case .obfs4, .custom, .onDemand:
			if self == .onDemand,
               let onDemandBridges = onDemandBridges ?? Settings.onDemandBridges,
			   !onDemandBridges.isEmpty
			{
				conf.append(ctp("obfs4", port, cv))
				conf += onDemandBridges.map({ cv("Bridge", $0) })
			}
			else if self == .custom,
					let customBridges = customBridges ?? Settings.customBridges,
					!customBridges.isEmpty
			{
				let transports = Set(customBridges.compactMap({ Bridge($0).transport }))

				// Try supporting other bridges than Obfs4 with custom bridges.
				for transport in transports {
					switch transport {
					case "meek_lite":
						conf.append(ctp("meek_lite", port, cv))

					case "webtunnel":
						conf.append(ctp("webtunnel", Self.iPtProxy?.getPort("webtunnel") ?? 0, cv))

					default:
						conf.append(ctp("obfs4", port, cv))
					}
				}

				conf += customBridges.map({ cv("Bridge", $0) })
			}
			else {
				conf.append(ctp("obfs4", port, cv))
				conf += BuiltInBridges.shared?.obfs4?.map({ cv("Bridge", $0.raw) }) ?? []
			}

		case .snowflake:
			conf.append(ctp("snowflake", port, cv))
			conf += BuiltInBridges.shared?.snowflake?
				.compactMap({
					let builder = Bridge.Builder(from: $0)

					builder?.fronts.formUnion(Self.addFronts)

					return builder?.build().raw
				})
				.map({ cv("Bridge", $0) }) ?? []

		case .snowflakeAmp:
			conf.append(ctp("snowflake", port, cv))
			conf += BuiltInBridges.shared?.snowflake?
				.compactMap({
					let builder = Bridge.Builder(from: $0)

					builder?.url = URL(string: Self.ampBroker)
					builder?.fronts = Set(Self.ampFronts)

					return builder?.build().raw
				})
				.map({ cv("Bridge", $0) }) ?? []

		case .meekAzure:
			conf.append(ctp("meek_lite", port, cv))
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
