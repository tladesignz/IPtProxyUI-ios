//
//  Bundle+IPtProxyUI.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import Foundation

public extension Bundle {

	class var iPtProxyUI: Bundle {
		Bundle(url: Bundle(for: BridgeConfViewController.self)
				.url(forResource: "IPtProxyUI", withExtension: "bundle")!)!
	}
}
