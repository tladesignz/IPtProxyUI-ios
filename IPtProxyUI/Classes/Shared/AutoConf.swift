//
//  AutoConf.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 30.05.22.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy

open class AutoConf {

	private weak var delegate: BridgesConfDelegate?

	private let tunnel = MoatTunnel.torProject

	public init(_ delegate: BridgesConfDelegate?) {
		self.delegate = delegate
	}

	/**
	 Tries to automatically configure Pluggable Transports, if the MOAT service decides, that in your country one is needed.

	 - parameter countryCode: An ISO 3166-1 Alpha 2 country code to force a specific country.
	 If not provided, the MOAT service will deduct a country from your IP address (preferred!)
	 - parameter cannotConnectWithoutPt: Set to `true`, if you are sure, that a PT configuration *is needed*,
	 even though the MOAT service says, that in your country none is. In that case, a default configuration will be used.
	 */
	open func `do`(countryCode: String? = nil, cannotConnectWithoutPt: Bool = false) async throws {
		let session = try start()

		// First update built-ins.
		if let updateFile = BuiltInBridges.updateFile,
		   BuiltInBridges.outdated,
		   var request = MoatApi.buildRequest(tunnel.baseUrl, .builtin)
		{
			delegate?.auth(request: &request)

			do {
				let response: Data = try await session.apiTask(with: request)

				// The return might be an empty JSON object. Only use, if there is substantial content.
				if response.count > 7 {
					try? response.write(to: updateFile, options: .atomic)

					BuiltInBridges.reload()
				}
			}
			catch {
				// Ignored.
			}
		}

		var lastError: Error?
		var cannotConnectWithoutPt = cannotConnectWithoutPt
		var response: MoatApi.SettingsResponse?

		do {
			response = try await loadSettings(from: tunnel, with: session, countryCode)

			// Force fetch of defaults.
			if response == nil {
				cannotConnectWithoutPt = true
			}
		}
		catch {
			lastError = error
		}

		var response2: MoatApi.SettingsResponse?

		// Guardian Project's Moat is behind DNSTT. There is no source IP address available
		// behind a DNSTT tunnel. So, only execute, when the user gave us a country.
		if let countryCode {
			let tunnel2 = MoatTunnel.guardianProject
			let session2 = try start(tunnel2)

			do {
				response2 = try await loadSettings(from: tunnel2, with: session2, countryCode)
			}
			catch {
				// Ignored, GP's MOAT service is still experimental.
			}

			tunnel2.transport.stop()
		}

		// If there are no settings, that means that the MOAT services consider the
		// country we're in to be safe for use without any transport.
		// But only consider this, if the user isn't sure, that they cannot connect without PT.
		if (response?.settings?.isEmpty ?? true) && (response2?.settings?.isEmpty ?? true) && !cannotConnectWithoutPt {
			stop()

			if let lastError {
				throw lastError
			}

			delegate?.transport = .none

			return
		}

		let conf1 = extract(from: response?.settings)
		let conf2 = extract(from: response2?.settings)
		let transport = conf2?.transport ?? conf1?.transport // Prefer Guardian Project MOAT's transport setting.
		let customBridges = (conf1?.customBridges ?? []) + (conf2?.customBridges ?? []) // Use all custom bridges.

		// Otherwise, use the first advertised setting which is usable with IPtProxy.
		if let transport {
			delegate?.transport = transport

			if !customBridges.isEmpty {
				delegate?.customBridges = customBridges
			}

			return stop()
		}

		// If we couldn't understand these answers or they were empty, try the default settings.

		guard var request = MoatApi.buildRequest(tunnel.baseUrl, .defaults) else {
			throw stop(ApiError.noRequestPossible)
		}

		delegate?.auth(request: &request)

		do {
			response = try await session.apiTask(with: request)
		}
		catch {
			throw stop(error)
		}

		stop()

		if let conf = self.extract(from: response?.settings) {
			self.delegate?.transport = conf.transport

			if !conf.customBridges.isEmpty {
				self.delegate?.customBridges = conf.customBridges
			}

			return
		}

		throw ApiError.notUnderstandable
	}

	/**
	 Fetches the current knowledge of the circumvention mechanisms that works for each location.
	 */
	open func fetchMap() async throws -> [String: MoatApi.SettingsResponse] {
		guard var request = MoatApi.buildRequest(tunnel.baseUrl, .map) else {
			throw ApiError.noRequestPossible
		}

		delegate?.auth(request: &request)

		let session = try start()

		do {
			let response: [String: MoatApi.SettingsResponse] = try await session.apiTask(with: request)

			return stop(response)
		}
		catch {
			throw stop(error)
		}
	}

	/**
	 Provides the full list of builtin bridges currently in use. Builtin bridges are public bridges often included in the client.
	 */
	open func fetchBuiltin() async throws -> [String: [String]] {
		guard var request = MoatApi.buildRequest(tunnel.baseUrl, .builtin) else {
			throw ApiError.noRequestPossible
		}

		delegate?.auth(request: &request)

		let session = try start()

		do {
			let response: [String: [String]] = try await session.apiTask(with: request)

			return stop(response)
		}
		catch {
			throw stop(error)
		}
	}

	/**
	 Provides the list of country codes for which we know circumvention is needed to connect to Tor.
	 */
	open func fetchCountries() async throws -> [String] {
		guard var request = MoatApi.buildRequest(tunnel.baseUrl, .countries) else {
			throw ApiError.noRequestPossible
		}

		delegate?.auth(request: &request)

		let session = try start()

		do {
			let response: [String] = try await session.apiTask(with: request)

			return stop(response)
		}
		catch {
			throw stop(error)
		}
	}


	// MARK: Private Methods

	private func start(_ tunnel: MoatTunnel? = nil) throws -> URLSession {
		try (tunnel ?? self.tunnel).transport.start()

		let conf = URLSessionConfiguration.default
		conf.connectionProxyDictionary = (tunnel ?? self.tunnel).proxyConf

		return URLSession(configuration: conf)
	}

	private func stop<T>(_ value: T) -> T {
		tunnel.transport.stop()

		return value
	}

	private func stop() {
		tunnel.transport.stop()
	}

	/**
	 Extract the correct PT settings from the given settings from the server.

	 *NOTE*: The priority is given by the server's list sorting. We honor that and always use the first one which works with `IPtProxy`!

	 We try to grab everything we can here:
	 - If there are Snowflake bridge lines given, we update the built-in list of Snowflake bridges.
	 - If there are Obfs4 built-in bridge lines given, we update the built-in list of Obfs4 bridges.
	 - If there are custom Obfs4 bridge lines given, we return these too, regardless of the actually selected transport,
       so the user can later try these out, too, if the selected transport doesn't work.
	 - If there are Webtunnel built-in bridge lines given, we update the built-in list of Webtunnel bridges.
	 - If there are custom Webtunnel bridge lines given, we return these too, regardless of the actually selected transport.
	 - If there are DNSTT built-in bridge lines given, we update the built-in list of DNSTT bridges.
	 - If there are custom DNSTT bridge lines given, we return these too, regardless of the actually selected transport.

	 - parameter settings: The settings from the MOAT server.
	 */
	private func extract(from settings: [MoatApi.Setting]?) -> (transport: Transport, customBridges: [String])? {
		var transport: Transport?
		var customBridges = [String]()

		for setting in settings ?? [] {
			if setting.bridge.type == IPtProxySnowflake {
				// If there are Snowflake bridge line updates, update our built-in ones!
				// Note: We ignore the source ("bridgedb" or "builtin") here on purpose.
				if let bridges = setting.bridge.bridges, !bridges.isEmpty {
					BuiltInBridges.shared?.snowflake = bridges.map({ Bridge($0) })
				}

				if transport == nil {
					transport = .snowflake
				}
			}
			else if setting.bridge.type == IPtProxyObfs4 {
				if setting.bridge.source == "builtin" {
					// If there are Obfs4 bridge line updates, update our built-in ones!
					if let bridges = setting.bridge.bridges, !bridges.isEmpty {
						BuiltInBridges.shared?.obfs4 = bridges.map({ Bridge($0) })
					}

					if transport == nil {
						transport = .obfs4
					}
				}
				else if let bridges = setting.bridge.bridges, !bridges.isEmpty {
					customBridges.append(contentsOf: bridges)

					if transport == nil {
						transport = .custom
					}
				}
			}
			else if setting.bridge.type == IPtProxyWebtunnel {
				if setting.bridge.source == "builtin" {
					// If there are Webtunnel bridge line updates, update our built-in ones!
					if let bridges = setting.bridge.bridges, !bridges.isEmpty {
						BuiltInBridges.shared?.webtunnel = bridges.map({ Bridge($0) })
						customBridges.append(contentsOf: bridges)
					}

					if transport == nil {
						transport = .custom
					}
				}
				else if let bridges = setting.bridge.bridges, !bridges.isEmpty {
					customBridges.append(contentsOf: bridges)

					if transport == nil {
						transport = .custom
					}
				}
			}
			else if setting.bridge.type == IPtProxyDnstt {
				if setting.bridge.source == "builtin" {
					// If there are DNSTT bridge line updates, update our built-in ones!
					if let bridges = setting.bridge.bridges, !bridges.isEmpty {
						BuiltInBridges.shared?.dnstt = bridges.map({ Bridge($0) })
						customBridges.append(contentsOf: bridges)
					}

					if transport == nil {
						transport = .custom
					}
				}
				else if let bridges = setting.bridge.bridges, !bridges.isEmpty {
					customBridges.append(contentsOf: bridges)

					if transport == nil {
						transport = .custom
					}
				}
			}
		}

		if let transport = transport {
			return (transport, customBridges)
		}

		return nil
	}

	private func loadSettings(from tunnel: MoatTunnel, with session: URLSession, _ countryCode: String?)
	async throws -> MoatApi.SettingsResponse?
	{
		guard var request = MoatApi.buildRequest(tunnel.baseUrl, .settings(countryCode: countryCode))
		else {
			throw ApiError.noRequestPossible
		}

		delegate?.auth(request: &request)

		do {
			return try await session.apiTask(with: request)
		}
		catch {
			if let error = error as? MoatApi.MoatError,
			   error.code == 404 /* Needs transport, but not the available ones */
				|| error.code == 406 /* no country from IP address */
			{
				// Force fetch of defaults.
				return nil
			}
			else {
				throw error
			}
		}
	}
}
