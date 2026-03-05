//
//  ViewController.swift
//  IPtProxyUI_Mac_Example
//
//  Created by Benjamin Erhart on 10.03.23.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI
import OSLog

class ViewController: NSViewController, NSWindowDelegate, BridgesConfDelegate {

	private let log = Logger(subsystem: "IPtProxyUI", category: String(describing: ViewController.self))

	override func viewDidAppear() {
		super.viewDidAppear()

		if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
			Settings.stateLocation = url

			log.info("stateLocation=\(url)")
		}

		bridgeSettings(self)
	}

	// MARK: NSWindowDelegate

	public func windowWillClose(_ notification: Notification) {
		NSApp.stopModal()
	}


	// MARK: BridgesConfDelegate

	var transport = Settings.transport

	var customBridges = Settings.customBridges

	var countryCode = Settings.countryCode

	var saveButtonTitle: String? = nil

	func save() {
		Settings.transport = transport
		Settings.customBridges = customBridges
		Settings.countryCode = countryCode

		log.info("Conf: \(Settings.transport.torConf(Transport.asArguments))")
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
