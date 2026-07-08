//
//  Bundle+IPtProxyUI.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

public extension Bundle {

	class var module: Bundle {
		Bundle(url: Bundle(for: MoatApi.self)
			.url(forResource: "IPtProxyUI", withExtension: "bundle")!)!
	}
}
