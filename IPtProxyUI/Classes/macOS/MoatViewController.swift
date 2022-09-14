//
//  MoatViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 29.08.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Cocoa

class MoatViewController: NSViewController, NSTextFieldDelegate {

	open weak var delegate: BridgesConfDelegate?


	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
			explanationLb.stringValue = explanationText
		}
	}

	@IBOutlet weak var refreshBt: NSButton!

	@IBOutlet weak var captchaIv: NSImageView! {
		didSet {
			captchaIv.setAccessibilityLabel(captchaImageText)
		}
	}
	@IBOutlet weak var solutionTf: NSTextField! {
		didSet {
			solutionTf.placeholderString = enterCharactersText

			solutionTf.delegate = self
		}
	}

	@IBOutlet weak var requestBt: NSButton! {
		didSet {
			requestBt.title = requestBridgesText

			requestBt.isEnabled = false
		}
	}


	private var challenge: String?


	public convenience init() {
		self.init(nibName: String(describing: MoatViewController.self), bundle: .iPtProxyUI)
	}

	open override func viewWillAppear() {
		super.viewWillAppear()

		view.window?.title = requestBridgesText

		view.window?.defaultButtonCell = requestBt.cell as? NSButtonCell

		delegate?.startMeek()

		fetchCaptcha(self)
	}

	override func viewWillDisappear() {
		super.viewWillDisappear()

		delegate?.stopMeek()
	}


	// MARK: NSTextFieldDelegate

	func controlTextDidChange(_ obj: Notification) {
		requestBt.isEnabled = !solutionTf.stringValue.isEmpty
	}


	// MARK: Actions

	@IBAction func fetchCaptcha(_ sender: Any) {
		refreshBt.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		fetchCaptcha() { [weak self] challenge, captcha, error in
			DispatchQueue.main.async {
				hud?.hide(true)
				self?.refreshBt.isEnabled = true

				if let error = error {
					NSAlert(error: error).runModal()
					return
				}

				self?.challenge = challenge

				if let captcha = captcha {
					self?.captchaIv.image = NSImage(data: captcha)
				}
			}
		}
	}


	@IBAction func requestBridges(_ sender: Any) {
		refreshBt.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		requestBridges(challenge, solutionTf.stringValue) { [weak self] bridges, error in
			DispatchQueue.main.async {
				hud?.hide(true)
				self?.refreshBt.isEnabled = true

				if let error = error {
					NSAlert(error: error).runModal()
					return
				}

				guard let bridges = bridges else {
					return
				}

				self?.delegate?.customBridges = bridges
				self?.delegate?.transport = .custom

				self?.view.window?.close()
			}
		}
	}
}