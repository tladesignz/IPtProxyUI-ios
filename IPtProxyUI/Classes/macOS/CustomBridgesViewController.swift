//
//  CustomBridgesViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 01.09.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Cocoa

open class CustomBridgesViewController: NSViewController, NSTextFieldDelegate {

	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
			explanationLb.stringValue = explanationText
		}
	}

	@IBOutlet weak var pasteboardBt: NSButton! {
		didSet {
			pasteboardBt.title = copyToClipboardText
		}
	}

	@IBOutlet weak var emailBt: NSButton! {
		didSet {
			emailBt.title = requestViaEmailText
		}
	}

	@IBOutlet weak var headerLb: NSTextField! {
		didSet {
			headerLb.stringValue = pasteBridgesText
		}
	}

	@IBOutlet weak var bridgesTf: NSTextField! {
		didSet {
			bridgesTf.placeholderString = Transport.builtInObfs4Bridges.prefix(2).joined(separator: "\n")
			bridgesTf.stringValue = delegate?.customBridges?.joined(separator: "\n") ?? ""
		}
	}


	open weak var delegate: BridgesConfDelegate?


	public convenience init() {
		self.init(nibName: String(describing: CustomBridgesViewController.self), bundle: .iPtProxyUI)
	}

	open override func viewWillAppear() {
		super.viewWillAppear()

		view.window?.title = titleText
	}


	// MARK: NSTextFieldDelegate

    public func controlTextDidChange(_ obj: Notification) {
		updateDelegate(bridgesTf.stringValue)
	}


	// MARK: Actions

	@IBAction func copyToPasteboard(_ sender: Any) {
		NSPasteboard.general.declareTypes([.URL], owner: nil)
		NSPasteboard.general.setString(Self.bridgesUrl, forType: .URL)
	}

	@IBAction func requestViaEmail(_ sender: Any) {
		let service = NSSharingService(named: .composeEmail)
		service?.recipients = [Self.emailRecipient]
		service?.subject = Self.emailSubjectAndBody
		service?.perform(withItems: [Self.emailSubjectAndBody])
	}
}
