//
//  CustomBridgesViewController+Shared.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 01.09.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

extension CustomBridgesViewController {
	
	public static let bridgesUrl = "https://bridges.torproject.org/"

	public static let emailRecipient = "bridges@torproject.org"

	public static let emailSubjectAndBody = "get transport"


	public var explanationText: String {
		String(format: NSLocalizedString(
			"In a separate browser, visit %@ and tap \"Get Bridges\" > \"Just Give Me Bridges!\"",
			bundle: .iPtProxyUI, comment: ""), Self.bridgesUrl)
	}

	public var copyToClipboardText: String {
		NSLocalizedString("Copy URL to Clipboard", bundle: .iPtProxyUI, comment: "")
	}

	public var requestViaEmailText: String {
		NSLocalizedString("Request via E-Mail", bundle: .iPtProxyUI, comment: "")
	}

	public var pasteBridgesText: String {
		NSLocalizedString("Paste Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public var titleText: String {
		NSLocalizedString("Use Custom Bridges", bundle: Bundle.iPtProxyUI, comment: "")
	}


	public func updateDelegate(_ customBridges: String?) {
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
