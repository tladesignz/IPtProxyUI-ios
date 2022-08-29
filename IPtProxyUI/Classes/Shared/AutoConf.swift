//
//  AutoConf.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 30.05.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

open class AutoConf {

	private weak var delegate: BridgesConfDelegate?

	public init(_ delegate: BridgesConfDelegate) {
		self.delegate = delegate
	}

	/**
	 Tries to automatically configure Pluggable Transports, if the MOAT service decides, that in your country one is needed.

	 - parameter country: An ISO 3166-1 Alpha 2 country code to force a specific country.
	 If not provided, the MOAT service will deduct a country from your IP address (preferred!)
	 - parameter cannotConnectWithoutPt: Set to `true`, if you are sure, that a PT configuration *is needed*,
	 even though the MOAT service says, that in your country none is. In that case, a default configuration will be used.
	 - parameter completion: A completion callback. If no `error` is returned, everything should no be configured correctly.
	 */
	open func `do`(country: String? = nil, cannotConnectWithoutPt: Bool = false, _ completion: @escaping (_ error: Error?) -> Void) {
		guard var request = MoatApi.buildRequest(.settings(country: country))
		else {
			return completion(ApiError.notUnderstandable)
		}

		delegate?.auth(request: &request)

		delegate?.startMeek()

		let task = URLSession.shared.apiTask(with: request) { (response: MoatApi.SettingsResponse?, error) in
			let completion = { (error: Error?) in
				self.delegate?.stopMeek()

				completion(error)
			}

			var cannotConnectWithoutPt = cannotConnectWithoutPt

			if let error = error {
				if let error = error as? MoatApi.MoatError,
				   error.code == 404 /* Needs transport, but not the available ones */
					|| error.code == 406 /* no country from IP address */
				{
					// Force fetch of defaults.
					cannotConnectWithoutPt = true
				}
				else {
					return completion(error)
				}
			}

			// If there are no settings, that means that the MOAT service considers the
			// country we're in to be safe for use without any transport.
			// But only consider this, if the user isn't sure, that they cannot connect without PT.
			if (response?.settings?.isEmpty ?? true) && !cannotConnectWithoutPt {
				self.delegate?.transport = .none

				return completion(nil)
			}

			// Otherwise, use the first advertised setting which is useable with IPtProxy.
			if let conf = self.extract(from: response?.settings) {
				self.delegate?.transport = conf.transport

				if let customBridges = conf.customBridges {
					self.delegate?.customBridges = customBridges
				}

				return completion(nil)
			}

			// If we couldn't understand that answer or it was empty, try the default settings.

			guard var request = MoatApi.buildRequest(.defaults) else {
				return completion(ApiError.notUnderstandable)
			}

			self.delegate?.auth(request: &request)

			let task = URLSession.shared.apiTask(with: request) { (response: MoatApi.SettingsResponse?, error) in
				if let error = error {
					return completion(error)
				}

				if let conf = self.extract(from: response?.settings) {
					self.delegate?.transport = conf.transport

					if let customBridges = conf.customBridges {
						self.delegate?.customBridges = customBridges
					}

					return completion(nil)
				}

				return completion(ApiError.notUnderstandable)
			}
			task.resume()
		}
		task.resume()
	}

	/**
	 Fetches the current knowledge of the circumvention mechanisms that works for each location.

	 - parameter completion: Callback containing the response or any errors.
	 */
	open func fetchMap(_ completion: @escaping (_ response: [String: MoatApi.SettingsResponse]?, _ error: Error?) -> Void) {
		guard var request = MoatApi.buildRequest(.map) else {
			return completion(nil, ApiError.notUnderstandable)
		}

		delegate?.auth(request: &request)

		delegate?.startMeek()

		let task = URLSession.shared.apiTask(with: request) { (response: [String: MoatApi.SettingsResponse]?, error) in
			self.delegate?.stopMeek()
			
			completion(response, error)
		}
		task.resume()
	}

	/**
	 Provides the full list of builtin bridges currently in use. Builtin bridges are public bridges often included in the client.

	 - parameter completion: Callback containing the response or any errors.
	 */
	open func fetchBuiltin(_ completion: @escaping (_ response: [String: [String]]?, _ error: Error?) -> Void) {
		guard var request = MoatApi.buildRequest(.builtin) else {
			return completion(nil, ApiError.notUnderstandable)
		}

		delegate?.auth(request: &request)

		delegate?.startMeek()

		let task = URLSession.shared.apiTask(with: request) { (response: [String: [String]]?, error) in
			self.delegate?.stopMeek()

			completion(response, error)
		}
		task.resume()
	}

	/**
	 Provides the list of country codes for which we know circumvention is needed to connect to Tor.

	 - parameter completion: Callback containing the response or any errors.
	 */
	open func fetchCountries(_ completion: @escaping (_ response: [String]?, _ error: Error?) -> Void) {
		guard var request = MoatApi.buildRequest(.countries) else {
			return completion(nil, ApiError.notUnderstandable)
		}

		delegate?.auth(request: &request)

		delegate?.startMeek()

		let task = URLSession.shared.apiTask(with: request) { (response: [String]?, error) in
			self.delegate?.stopMeek()

			completion(response, error)
		}
		task.resume()
	}

	/**
	 Extract the correct PT settings from the given settings from the server.

	 *NOTE*: The priority is given by the server's list sorting. We honor that and always use the first one which works with `IPtProxy`!

	 - parameter settings: The settings from the MOAT server.
	 */
	private func extract(from settings: [MoatApi.Setting]?) -> (transport: Transport, customBridges: [String]?)? {
		for setting in settings ?? [] {
			if setting.bridge.type == "snowflake" {
				return (.snowflake, nil)
			}

			if setting.bridge.type == "obfs4" {
				if setting.bridge.source == "builtin" {
					return (.obfs4, nil)
				}

				if !(setting.bridge.bridges?.isEmpty ?? true) {
					return (.custom, setting.bridge.bridges)
				}
			}
		}

		return nil
	}
}
