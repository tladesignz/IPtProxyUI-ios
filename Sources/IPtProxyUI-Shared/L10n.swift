//
//  BridgesConfViewController+Shared.swift
//  Pods
//
//  Created by Benjamin Erhart on 01.09.22.
//

import Foundation

public class L10n {

	public static var automaticConfiguration: String {
		NSLocalizedString("Automatic Configuration", bundle: .module, comment: "")
	}

	public static var bridgeConfiguration: String {
		NSLocalizedString("Bridge Configuration", bundle: .module, comment: "")
	}

	public static var bridgeTypeExplanation: String {
		[
			NSLocalizedString("If you are in a country or using a connection that censors Tor, you might need to use bridges.",
							  bundle: .module, comment: ""),
			"",
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic appear \"random\".",
				bundle: .module, comment: ""), "\u{2022}", "obfs4"),
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic look like a phone call to a random user on the net.",
				bundle: .module, comment: ""), "\u{2022}", "snowflake"),
			"",
			NSLocalizedString("If one type of bridge does not work, try using a different one.",
							  bundle: .module, comment: "")
		].joined(separator: "\n")
	}

	public static var builtInDnstt: String {
		String(format: NSLocalizedString("Built-in %@", bundle: .module, comment: ""), "DNS Tunnel")
	}

	public static var builtInMeek: String {
		String(format: NSLocalizedString("Built-in %@", bundle: .module, comment: ""), "meek")
	}

	public static var builtInObfs4: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .module, comment: ""), "obfs4")
	}

	public static var builtInSnowflake: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .module, comment: ""), "snowflake")
	}

	public static var builtInSnowflakeAmp: String {
		String(format: NSLocalizedString(
			"Built-in %@", bundle: .module, comment: ""), "snowflake (AMP)")
	}

	public static var cameraNotSupported: String {
		NSLocalizedString(
			"Camera access was not granted or QR Code scanning is not supported by your device.",
			bundle: .module, comment: "")
	}

	public static var cancel: String {
		NSLocalizedString("Cancel", bundle: .module, comment: "")
	}

	public static var cannotConnect: String {
		NSLocalizedString("I'm sure I cannot connect without a bridge.",
						  bundle: .module, comment: "")
	}

	public static var copyToClipboard: String {
		NSLocalizedString("Copy URL to Clipboard", bundle: .module, comment: "")
	}

	public static var customBridges: String {
		NSLocalizedString("Custom Bridges", bundle: .module, comment: "")
	}

	public static var customBridgesExplanation: String {
		String(format: NSLocalizedString(
			"In a separate browser, visit %@ and tap \"Get Bridges\" > \"Just Give Me Bridges!\"",
			bundle: .module, comment: ""), Constants.bridgesUrl.absoluteString)
	}

	public static var error: String {
		NSLocalizedString("Error", bundle: .module, comment: "")
	}

	public static var myCountry: String {
		NSLocalizedString("My Country", bundle: .module, comment: "")
	}

	public static var noBridges: String {
		NSLocalizedString("No Bridges", bundle: .module, comment: "")
	}

	public static var ok: String {
		NSLocalizedString("OK", bundle: .module, comment: "")
	}

	public static var other: String {
		NSLocalizedString("Other", bundle: .module, comment: "")
	}

	public static var pasteBridges: String {
		NSLocalizedString("Paste Bridges", bundle: .module, comment: "")
	}

	public static var qrCodeCouldNotBeDecoded: String {
		String(format: NSLocalizedString(
			"QR Code could not be decoded! Are you sure you scanned a QR code from %@?",
			bundle: .module, comment: ""), Constants.bridgesUrl.absoluteString)
	}

	public static var requestBridgesFrom: String {
		NSLocalizedString("Request Bridges from torproject.org",
						  bundle: .module, comment: "")
	}

	public static var requestViaEmail: String {
		NSLocalizedString("Request via E-Mail", bundle: .module, comment: "")
	}

	public static var requestViaTelegram: String {
		NSLocalizedString("Request via Telegram", bundle: .module, comment: "")
	}

	public static var save: String {
		NSLocalizedString("Save", bundle: .module, comment: "")
	}

	public static var scanQrCode: String {
		NSLocalizedString("Scan QR Code", bundle: .module, comment: "")
	}

	public static var title: String {
		NSLocalizedString("Use Custom Bridges", bundle: .module, comment: "")
	}

	public static var tryAutoConfiguration: String {
		NSLocalizedString("Try Auto-Configuration", bundle: .module, comment: "")
	}

	public static var uploadQrCode: String {
		NSLocalizedString("Upload QR Code", bundle: .module, comment: "")
	}

	public static var useCustomBridges: String {
		NSLocalizedString("Use Custom Bridges", bundle: .module, comment: "")
	}

	public static var useQrCode: String {
		NSLocalizedString("Use QR Code", bundle: .module, comment: "")
	}
}
