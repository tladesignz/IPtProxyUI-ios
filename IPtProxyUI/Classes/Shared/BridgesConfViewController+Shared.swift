//
//  BridgesConfViewController+Shared.swift
//  Pods
//
//  Created by Benjamin Erhart on 01.09.22.
//

import Foundation

extension BridgesConfViewController {

	public var automaticConfigurationText: String {
		NSLocalizedString("Automatic Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public var cannotConnectText: String {
		NSLocalizedString("I'm sure I cannot connect without a bridge.",
			bundle: .iPtProxyUI, comment: "")
	}

	public var tryAutoConfigurationText: String {
		NSLocalizedString("Try Auto-Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public var manualConfigurationText: String {
		NSLocalizedString("Manual Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public var requestBridgesText: String {
		NSLocalizedString("Request Bridges from torproject.org",
						  bundle: .iPtProxyUI, comment: "")
	}

	public var noBridgesText: String {
		NSLocalizedString("No Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public var builtInObfs4Text: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "obfs4")
	}

	public var builtInSnowflakeText: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "snowflake")
	}

	public var builtInSnowflakeAmpText: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "snowflake (AMP)")
	}

	public var customBridgesText: String {
		NSLocalizedString("Custom Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public var explanationText: String {
		[
			NSLocalizedString("If you are in a country or using a connection that censors Tor, you might need to use bridges.",
							  bundle: .iPtProxyUI, comment: ""),
			"",
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic appear \"random\".",
				bundle: .iPtProxyUI, comment: ""), "\u{2022}", "obfs4"),
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic look like a phone call to a random user on the net.",
				bundle: .iPtProxyUI, comment: ""), "\u{2022}", "snowflake"),
			"",
			NSLocalizedString("If one type of bridge does not work, try using a different one.",
							  bundle: .iPtProxyUI, comment: "")
		].joined(separator: "\n")
	}

	public var cancelText: String {
		NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "")
	}

	public var bridgeConfigurationText: String {
		NSLocalizedString("Bridge Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public var saveText: String {
		NSLocalizedString("Save", bundle: .iPtProxyUI, comment: "")
	}
}
