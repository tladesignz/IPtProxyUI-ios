//
//  Settings.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-12-01.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy

open class Settings {

	open class var defaults: UserDefaults? {
		UserDefaults.standard
	}

	open class var transport: Transport {
		get {
			Transport(rawValue: defaults?.integer(forKey: "transport") ?? 0) ?? .none
		}
		set {
			defaults?.set(newValue.rawValue, forKey: "transport")
		}
	}

	open class var customBridges: [String]? {
		get {
			defaults?.stringArray(forKey: "customBridges")
		}
		set {
			defaults?.set(newValue, forKey: "customBridges")
		}
	}

	open class var onDemandBridges: [String]? {
		get {
			defaults?.stringArray(forKey: "onDemandBridges")
		}
		set {
			defaults?.set(newValue, forKey: "onDemandBridges")
		}
	}

	open class var stateLocation: URL {
		get {
			Transport.stateLocation
		}
		set {
			Transport.stateLocation = newValue
		}
	}

	open class var proxy: URL? {
		get {
			guard let proxy = defaults?.string(forKey: "proxy") else {
				return nil
			}

			return URL(string: proxy)
		}
		set {
			defaults?.set(newValue?.absoluteString, forKey: "proxy")
		}
	}
}
