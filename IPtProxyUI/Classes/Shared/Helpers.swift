//
//  Helpers.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 01.09.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

public class Helpers {
	
	public class func update(delegate: BridgesConfDelegate?, _ customBridges: String?) {
		delegate?.customBridges = customBridges?
				.components(separatedBy: "\n")
				.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
				.filter({ !$0.isEmpty && !$0.hasPrefix("//") && !$0.hasPrefix("#") })

		if delegate?.customBridges?.isEmpty ?? true {
			if delegate?.transport == .custom {
				delegate?.transport = .none
			}
		}
		else {
			delegate?.transport = .custom
		}
	}
}
