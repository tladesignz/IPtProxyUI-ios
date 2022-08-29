//
//  Settings.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-12-01.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

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
}
