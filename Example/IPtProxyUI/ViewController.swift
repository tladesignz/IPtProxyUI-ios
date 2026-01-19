//
//  ViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03/10/2023.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class ViewController: UIViewController, BridgesConfDelegate {

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		bridgeSettings()
	}


	// MARK: BridgesConfDelegate

	var transport = Settings.transport

	var customBridges = Settings.customBridges

	var saveButtonTitle: String?

	func save() {
		Settings.transport = transport
		Settings.customBridges = customBridges
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
