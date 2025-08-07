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

	private class StatusCollector: NSObject, IPtProxyOnTransportStoppedProtocol {

		var started = [String: Bool]()
		var errors = [String: Error]()

		func stopped(_ name: String?, error: (any Error)?) {
            guard let name = name else {
                return
            }

            DispatchQueue.global(qos: .userInitiated).sync {
                started[name] = false
                errors[name] = error
            }
		}

		func started(name: String) {
            DispatchQueue.global(qos: .userInitiated).sync {
                started[name] = true
                errors[name] = nil
            }
		}
	}

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .meek, .custom, .onDemand]

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


	private static var customTransports: Set<String> {
		Set((customBridges ?? Settings.customBridges)?.compactMap({ Bridge($0).transport }) ?? [])
	}

	// Seems more reliable in certain countries than the currently advertised one.
	private static let addFronts = ["github.githubassets.com"]

	private static let ampBroker = "https://snowflake-broker.torproject.net/"
	private static let ampFronts = ["www.google.com"]

	private static let controller: IPtProxyController? = {
		return IPtProxyController(
            stateLocation.path, enableLogging: true, unsafeLogging: false,
            logLevel: "INFO", transportStopped: collector)
	}()

	private static let collector = StatusCollector()


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
	case meek = 6


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

		case .meek:
			return NSLocalizedString("Meek bridge", bundle: .iPtProxyUI, comment: "")

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
		case .obfs4, .custom, .onDemand, .meek, .snowflake, .snowflakeAmp:
			return Settings.stateLocation.appendingPathComponent(IPtProxyLogFileName)

		default:
			return nil
		}
	}

	public var port: Int {
		guard let name = transportNames.first else {
			return 0
		}

		return Self.controller?.port(name) ?? 0
	}

	public var connected: Bool {
		guard let name = transportNames.first else {
			return false
		}

		return Self.collector.started[name] ?? false
	}

	public var error: Error? {
		guard let name = transportNames.first else {
			return nil
		}

		return Self.collector.errors[name]
	}


	private var transportNames: Set<String> {
		switch self {
		case .none:
			return []

		case .obfs4, .onDemand:
			return [IPtProxyObfs4]

		case .snowflake, .snowflakeAmp:
			return [IPtProxySnowflake]

		case .custom:
			return Self.customTransports

		case .meek:
			return [IPtProxyMeekLite]
		}
	}

	/**
	 Start the transport, if it is startable.
	 */
	public func start() throws {
		switch self {
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

		case .snowflakeAmp:
			Self.controller?.snowflakeIceServers = BuiltInBridges.shared?.snowflake?.first?.ice ?? ""
			Self.controller?.snowflakeBrokerUrl = Self.ampBroker
			Self.controller?.snowflakeFrontDomains = Self.ampFronts.joined(separator: ",")
			Self.controller?.snowflakeAmpCacheUrl = "https://cdn.ampproject.org/"

		default:
			break
		}

		for name in transportNames {
			do {
				try Self.controller?.start(name, proxy: nil)
				Self.collector.started(name: name)
			}
			catch {
				Self.collector.stopped(name, error: error)
				throw error
			}
		}
	}

	public func stop() {
		for name in transportNames {
			Self.controller?.stop(name)
		}
	}

	public func stopAllOthers() {
		var transportNames = Set(Self.allCases.flatMap({ $0.transportNames }))
		transportNames.subtract(self.transportNames)

		for name in transportNames {
			Self.controller?.stop(name)
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
			var idx = 0

			conf.append(ctp(IPtProxySnowflake, port, cv))
			conf += BuiltInBridges.shared?.snowflake?
				.compactMap({
					let builder = Bridge.Builder(from: $0)
					builder?.ip = "192.0.2.\(5 + idx)"
					builder?.url = URL(string: Self.ampBroker)
					builder?.fronts = Set(Self.ampFronts)

					idx += 1

					return builder?.build().raw
				})
				.map({ cv("Bridge", $0) }) ?? []

		case .meek:
			conf.append(ctp(IPtProxyMeekLite, port, cv))
			conf += BuiltInBridges.shared?.meek?.map({ cv("Bridge", $0.raw) }) ?? []

		default:
			break
		}

		return conf
	}


	// MARK: Private Methods

	private func ctp<T>(_ transport: String, _ port: Int, _ cv: (String, String) -> T) -> T {
		return cv("ClientTransportPlugin", "\(transport) socks5 127.0.0.1:\(port)")
	}
}
