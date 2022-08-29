//
//  BridgesConfMacViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 26.08.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Cocoa

open class BridgesConfMacViewController: NSViewController, BridgesConfDelegate {

	open weak var delegate: BridgesConfDelegate?

	open var transport: Transport = .none {
		didSet {
			DispatchQueue.main.async {
				switch self.transport {
				case .obfs4:
					self.obfs4Rb.state = .on

				case .snowflake:
					self.snowflakeRb.state = .on

				case .snowflakeAmp:
					self.snowflakeAmpRb.state = .on

				case .custom:
					self.customBridgesRb.state = .on

				default:
					self.noBridgesRb.state = .on
				}
			}
		}
	}

	open var customBridges: [String]?


	@IBOutlet weak var autoConfBox: NSBox! {
		didSet {
			autoConfBox.title = NSLocalizedString(
				"Automatic Configuration", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var cannotConnectLb: NSTextField! {
		didSet {
			cannotConnectLb.stringValue = NSLocalizedString(
				"I'm sure I cannot connect without a bridge.",
				bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var cannotConnectSw: NSSwitch!

	@IBOutlet weak var tryAutoConfBt: NSButton! {
		didSet {
			tryAutoConfBt.title = NSLocalizedString(
				"Try Auto-Configuration", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var manualConfBox: NSBox! {
		didSet {
			manualConfBox.title = NSLocalizedString(
				"Manual Configuration", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var manualConfBt: NSButton! {
		didSet {
			manualConfBt.title = NSLocalizedString(
				"Request Bridges from torproject.org",
				bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var noBridgesRb: NSButton! {
		didSet {
			noBridgesRb.title = NSLocalizedString(
				"No Bridges", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var obfs4Rb: NSButton! {
		didSet {
			obfs4Rb.title = String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "obfs4")
		}
	}

	@IBOutlet weak var snowflakeRb: NSButton! {
		didSet {
			snowflakeRb.title = String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "snowflake")
		}
	}

	@IBOutlet weak var snowflakeAmpRb: NSButton! {
		didSet {
			snowflakeAmpRb.title = String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "snowflake (AMP)")
		}
	}

	@IBOutlet weak var customBridgesRb: NSButton! {
		didSet {
			customBridgesRb.title = NSLocalizedString(
				"Custom Bridges", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var descLb: NSTextField! {
		didSet {
			descLb.stringValue = [
				NSLocalizedString("If you are in a country or using a connection that censors Tor, you might need to use bridges.",
								  bundle: Bundle.iPtProxyUI, comment: ""),
				"",
				String(format: NSLocalizedString(
					"%1$@ %2$@ makes your traffic appear \"random\".",
					bundle: Bundle.iPtProxyUI, comment: ""), "\u{2022}", "obfs4"),
				String(format: NSLocalizedString(
					"%1$@ %2$@ makes your traffic look like a phone call to a random user on the net.",
					bundle: Bundle.iPtProxyUI, comment: ""), "\u{2022}", "snowflake"),
				"",
				NSLocalizedString("If one type of bridge does not work, try using a different one.",
								  bundle: Bundle.iPtProxyUI, comment: "")
			].joined(separator: "\n")
		}
	}

	@IBOutlet weak var cancelBt: NSButton! {
		didSet {
			cancelBt.title = NSLocalizedString(
				"Cancel", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var saveBt: NSButton!


	public convenience init() {
		self.init(nibName: String(describing: BridgesConfMacViewController.self), bundle: .iPtProxyUI)
	}


	open override func viewWillAppear() {
		super.viewWillAppear()

		view.window?.title = NSLocalizedString(
			"Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "")

		saveBt.title = saveButtonTitle ?? NSLocalizedString("Save", bundle: .iPtProxyUI, comment: "")
	}


	// MARK: BridgesConfDelegate

	open var saveButtonTitle: String? {
		delegate?.saveButtonTitle
	}

	open func startMeek() {
		delegate?.startMeek()
	}

	open func stopMeek() {
		delegate?.stopMeek()
	}

	open func auth(request: inout URLRequest) {
		delegate?.auth(request: &request)
	}

	open func save() {
		delegate?.transport = transport

		delegate?.customBridges = customBridges

		delegate?.save()
	}


	// MARK: Actions

	@IBAction open func tryAutoConf(_ sender: Any) {
		let hud = MBProgressHUD.showAdded(to: self.view, animated: true)

		let autoconf = AutoConf(self)
		autoconf.do(cannotConnectWithoutPt: cannotConnectSw.state == .on) { error in
			DispatchQueue.main.async {
				if let error = error {
					hud?.hide(true)

					NSAlert(error: error).runModal()
				}
				else {
					var delay = 0.0

					if let checkmark = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil) {
						checkmark.isTemplate = true

						let iv = NSImageView(image: checkmark)
						iv.contentTintColor = .white

						hud?.mode = MBProgressHUDModeCustomView
						hud?.customView = iv

						delay = 1
					}

					hud?.hide(true, afterDelay: delay)
				}
			}
		}
	}

	@IBAction open func manualConf(_ sender: Any) {

	}

	@IBAction open func selectBridge(_ sender: NSButton) {
		if sender == obfs4Rb {
			transport = .obfs4
		}
		else if sender == snowflakeRb {
			transport = .snowflake
		}
		else if sender == snowflakeAmpRb {
			transport = .snowflakeAmp
		}
		else if sender == customBridgesRb {
			transport = .custom
		}
		else {
			transport = .none
		}
	}

	@IBAction open func cancel(_ sender: Any) {
		NSApp.stopModal()

		view.window?.close()
	}

	@IBAction open func save(_ sender: Any) {
		save()

		NSApp.stopModal()

		view.window?.close()
	}
}
