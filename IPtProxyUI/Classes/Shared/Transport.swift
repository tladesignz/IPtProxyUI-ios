//
//  Transport.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy

public extension Notification.Name {

	/**
	 Emiited, when transports were *started* (not necessarily *connected*). Contained object is the list of started ``Transport``s.

	 Typically that is only one, but could be X + ``Transport.custom``, if a custom transport is configured containing obfs4 or meek transport types,
	 or when the transport is of type Snowflake.
	 */
	static let iPtProxyTransportStarted = Notification.Name("iptproxy-transport-started")

	/**
	 Emiited, when transports were *connected* . Contained object is the list of connected ``Transport``s.

	 Typically that is only one, but could be X + ``Transport.custom``, if a custom transport is configured containing obfs4 or meek transport types,
	 or when the transport is of type Snowflake.
	 */
	static let iPtProxyTransportConnected = Notification.Name("iptproxy-transport-connected")

	/**
	 Emiited, when transports have errors during  connecting . Contained object should be ``[Transport.snowflake, Transport.snowflakeAmp]``.

	 This currently only happens with transports of type Snowflake, since all others will not finish ``Transport.start()`` on any error,
	 while with Snowflake, errors can happen while trying to find a valid proxy.
	 */
	static let iPtProxyTransportErrored = Notification.Name("iptproxy-transport-errored")

	/**
	 Emiited, when transports were *stopped*. Contained object is the list of stopped ``Transport``s.

	 Typically that is only one, but could be X + ``Transport.custom``, if a custom transport is configured containing obfs4 or meek transport types,
	 or when the transport is of type Snowflake.
	 */
	static let iPtProxyTransportStopped = Notification.Name("iptproxy-transport-stopped")
}

public enum Transport: Int, CaseIterable, Comparable {

	private class StatusCollector: NSObject, IPtProxyOnTransportEventsProtocol {

		var started = [String: Bool]()
		var connected = [String: Bool]()
		var errors = [String: Error]()

		func stopped(_ name: String?, error: (any Error)?) {
			guard let name = name else {
				return
			}

			DispatchQueue.global(qos: .userInitiated).sync {
				started[name] = false
				connected[name] = false
				errors[name] = error
			}

			NotificationCenter.default.post(name: .iPtProxyTransportStopped, object: getTransports(from: name))
		}

		func started(name: String) {
			DispatchQueue.global(qos: .userInitiated).sync {
				started[name] = true
				errors[name] = nil
			}

			NotificationCenter.default.post(name: .iPtProxyTransportStarted, object: getTransports(from: name))
		}

		func connected(_ name: String?) {
			guard let name else {
				return
			}

			DispatchQueue.global(qos: .userInitiated).sync {
				connected[name] = true
			}

			NotificationCenter.default.post(name: .iPtProxyTransportConnected, object: getTransports(from: name))
		}

		func error(_ name: String?, error: (any Error)?) {
			guard let name else {
				return
			}

			DispatchQueue.global(qos: .userInitiated).sync {
				errors[name] = error
			}

			NotificationCenter.default.post(name: .iPtProxyTransportErrored, object: getTransports(from: name))
		}


		private func getTransports(from name: String) -> [Transport] {
			switch name {
			case IPtProxyObfs4:
				return [.obfs4] + (customTransports.contains(name) ? [.custom] : [])

			case IPtProxySnowflake:
				return [.snowflake, .snowflakeAmp]

			case IPtProxyWebtunnel:
				return [.custom]

			case IPtProxyMeekLite:
				return [.meek] + (customTransports.contains(name) ? [.custom] : [])

			case IPtProxyDnstt:
				return [.dnstt] + (customTransports.contains(name) ? [.custom] : [])

			default:
				assertionFailure("Transport \(name) unknown or unused.")
				return []
			}
		}
	}

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .meek, .dnstt, .custom, .onDemand]

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

	/**
	 Your proxy, in case it cannot be found in `Settings.proxy`.
	 */
	public static var proxy: URL?


	private static var customTransports: Set<String> {
		Set((customBridges ?? Settings.customBridges)?.compactMap({ Bridge($0).transport }) ?? [])
	}

	// Seems more reliable in certain countries than the currently advertised one.
	private static let addFronts = ["github.githubassets.com"]

	private static let ampBroker = "https://snowflake-broker.torproject.net/"
	private static let ampFronts = ["www.google.com"]

	private static let dnsttBridges = [String]()

	private static let controller: IPtProxyController? = {
		return IPtProxyController(
			stateLocation.path, enableLogging: true, unsafeLogging: false,
			logLevel: "INFO", transportEvents: collector)
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
	case dnstt = 7


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

		case .dnstt:
			return NSLocalizedString("DNSTT bridge", bundle: .iPtProxyUI, comment: "")

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
		case .obfs4, .custom, .onDemand, .meek, .snowflake, .snowflakeAmp, .dnstt:
			return Settings.stateLocation.appendingPathComponent(IPtProxyLogFileName)

		default:
			return nil
		}
	}

	/**
	 The first underlying transport's port which is actually up.
	 */
	public var port: Int {
		for name in transportNames {
			if let port = Self.controller?.port(name), port > 0 {
				return port
			}
		}

		return 0
	}

	/**
	 If all underlying transports are actually started and connected.
	 */
	public var connected: Bool {
		transportNames.reduce(true) { partialResult, name in
			partialResult && (Self.collector.started[name] ?? false) && (Self.collector.connected[name] ?? false)
		}
	}

	/**
	 The first error found on any used underlying transport. (But, the *last* one happening on that specific transport.)
	 */
	public var error: Error? {
		transportNames.compactMap({ Self.collector.errors[$0] }).first
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

		case .dnstt:
			return [IPtProxyDnstt]
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

		let proxy = (Self.proxy ?? Settings.proxy)?.absoluteString

		for name in transportNames {
			do {
				try Self.controller?.start(name, proxy: [IPtProxySnowflake, IPtProxyDnstt].contains(proxy) ? nil : proxy)
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

		case .dnstt:
			conf.append(ctp(IPtProxyDnstt, port, cv))
			conf += Self.dnsttBridges.map({ cv("Bridge", $0) })

		case .none:
			if let proxy = Self.proxy ?? Settings.proxy,
			   let hostPort = proxy.hostPort
			{
				switch proxy.scheme {
				case "https":
					conf.append(cv("HTTPSProxy", hostPort))

					if let username = proxy.user, !username.isEmpty {
						conf.append(cv("HTTPSProxyAuthenticator", "\(username):\(proxy.password ?? "")"))
					}

				case "socks4":
					conf.append(cv("Socks4Proxy", hostPort))

				case "socks5":
					conf.append(cv("Socks5Proxy", hostPort))

					if let username = proxy.user, !username.isEmpty {
						conf.append(cv("Socks5ProxyUsername", username))

						var password = proxy.password ?? " "
						if password.isEmpty {
							password = " "
						}

						conf.append(cv("Socks5ProxyPassword", password))
					}

				default:
					break
				}
			}
		}

		return conf
	}


	// MARK: Private Methods

	private func ctp<T>(_ transport: String, _ port: Int, _ cv: (String, String) -> T) -> T {
		return cv("ClientTransportPlugin", "\(transport) socks5 127.0.0.1:\(port)")
	}
}
