//
//  ViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03/10/2023.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI
import OSLog

class ViewController: UIViewController, BridgesConfDelegate {

	private let log = Logger(subsystem: "IPtProxyUI", category: String(describing: ViewController.self))

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		bridgeSettings()
	}


	// MARK: BridgesConfDelegate

	var transport = Settings.transport

	var customBridges = Settings.customBridges

	var countryCode = Settings.countryCode

	var saveButtonTitle: String?

	func save() {
		Settings.transport = transport
		Settings.customBridges = customBridges
		Settings.countryCode = countryCode

		log.info("Conf: \(Settings.transport.torConf(Transport.asArguments))")
	}


	// MARK: Actions

	@IBAction func bridgeSettings() {
		let vc = BridgesConfViewController()
		vc.delegate = self
		vc.transport = transport
		vc.customBridges = customBridges

		present(UINavigationController(rootViewController: vc), animated: true)
	}
}
