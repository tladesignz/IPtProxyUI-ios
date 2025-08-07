//
//  BridgesConfViewController+Shared.swift
//  Pods
//
//  Created by Benjamin Erhart on 01.09.22.
//

import Foundation

public class L10n {

	public static var automaticConfiguration: String {
		NSLocalizedString("Automatic Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public static var cannotConnect: String {
		NSLocalizedString("I'm sure I cannot connect without a bridge.",
						  bundle: .iPtProxyUI, comment: "")
	}

	public static var tryAutoConfiguration: String {
		NSLocalizedString("Try Auto-Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public static var requestBridgesFrom: String {
		NSLocalizedString("Request Bridges from torproject.org",
						  bundle: .iPtProxyUI, comment: "")
	}

	public static var noBridges: String {
		NSLocalizedString("No Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public static var builtInObfs4: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "obfs4")
	}

	public static var builtInSnowflake: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "snowflake")
	}

	public static var builtInSnowflakeAmp: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .iPtProxyUI, comment: ""), "snowflake (AMP)")
	}

	public static var builtInMeek: String {
		String(format: NSLocalizedString("Built-in %@", bundle: .iPtProxyUI, comment: ""), "meek")
	}

	public static var customBridges: String {
		NSLocalizedString("Custom Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public static var bridgeTypeExplanation: String {
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

	public static var cancel: String {
		NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "")
	}

	public static var bridgeConfiguration: String {
		NSLocalizedString("Bridge Configuration", bundle: .iPtProxyUI, comment: "")
	}

	public static var save: String {
		NSLocalizedString("Save", bundle: .iPtProxyUI, comment: "")
	}

	public static var customBridgesExplanation: String {
		String(format: NSLocalizedString(
			"In a separate browser, visit %@ and tap \"Get Bridges\" > \"Just Give Me Bridges!\"",
            bundle: .iPtProxyUI, comment: ""), Constants.bridgesUrl.absoluteString)
	}

	public static var copyToClipboard: String {
		NSLocalizedString("Copy URL to Clipboard", bundle: .iPtProxyUI, comment: "")
	}

	public static var requestViaEmail: String {
		NSLocalizedString("Request via E-Mail", bundle: .iPtProxyUI, comment: "")
	}

	public static var requestViaTelegram: String {
		NSLocalizedString("Request via Telegram", bundle: .iPtProxyUI, comment: "")
	}

	public static var pasteBridges: String {
		NSLocalizedString("Paste Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public static var title: String {
		NSLocalizedString("Use Custom Bridges", bundle: .iPtProxyUI, comment: "")
	}

	public static var error: String {
		NSLocalizedString("Error", bundle: .iPtProxyUI, comment: "")
	}

	public static var ok: String {
		NSLocalizedString("OK", bundle: .iPtProxyUI, comment: "")
	}

	public static var scanQrCode: String {
		NSLocalizedString("Scan QR Code", bundle: .iPtProxyUI, comment: "")
	}

	public static var uploadQrCode: String {
		NSLocalizedString("Upload QR Code", bundle: .iPtProxyUI, comment: "")
	}
}
