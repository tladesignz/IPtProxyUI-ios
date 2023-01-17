//
//  CustomBridgesViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 01.09.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Cocoa

open class CustomBridgesViewController: NSViewController {

	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
            explanationLb.stringValue = L10n.customBridgesExplanation
		}
	}

	@IBOutlet weak var pasteboardBt: NSButton! {
		didSet {
            pasteboardBt.title = L10n.copyToClipboard
		}
	}

	@IBOutlet weak var emailBt: NSButton! {
		didSet {
            emailBt.title = L10n.requestViaEmail
		}
	}

	@IBOutlet weak var headerLb: NSTextField! {
		didSet {
            headerLb.stringValue = L10n.pasteBridges
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

        view.window?.title = L10n.title
	}

	open override func viewWillDisappear() {
		super.viewWillDisappear()

		updateDelegate(bridgesTf.stringValue)
	}


	// MARK: Actions

	@IBAction func copyToPasteboard(_ sender: Any) {
		NSPasteboard.general.declareTypes([.URL], owner: nil)
        NSPasteboard.general.setString(Constants.bridgesUrl.absoluteString, forType: .URL)
	}

	@IBAction func requestViaEmail(_ sender: Any) {
		let service = NSSharingService(named: .composeEmail)
		service?.recipients = [Constants.emailRecipient]
		service?.subject = Constants.emailSubjectAndBody
		service?.perform(withItems: [Constants.emailSubjectAndBody])
	}
}
