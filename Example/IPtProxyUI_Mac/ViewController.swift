//
//  ViewController.swift
//  IPtProxyUI_Mac_Example
//
//  Created by Benjamin Erhart on 10.03.23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Cocoa
import IPtProxyUI

class ViewController: NSViewController, NSWindowDelegate, BridgesConfDelegate {

	override func viewDidAppear() {
		super.viewDidAppear()

		if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
			Settings.stateLocation = url
			print("[\(String(describing: type(of: self)))] stateLocation=\(url)")
		}

		bridgeSettings(self)
	}

	// MARK: NSWindowDelegate

	public func windowWillClose(_ notification: Notification) {
		NSApp.stopModal()
	}


	// MARK: BridgesConfDelegate

	var transport = Settings.transport

	var customBridges: [String]? = Settings.customBridges

	var saveButtonTitle: String? = nil

	func save() {
		Settings.transport = transport
		Settings.customBridges = customBridges
	}


	// MARK: Actions

	@IBAction func bridgeSettings(_ sender: Any) {
		let vc = BridgesConfViewController()
		vc.delegate = self
		vc.transport = transport
		vc.customBridges = customBridges

		let window = NSWindow(contentViewController: vc)
		window.delegate = self

		NSApp.runModal(for: window)

		window.close()
	}
}
