//
//  MoatMacViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 29.08.22.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Cocoa

class MoatMacViewController: NSViewController, NSTextFieldDelegate {

	open weak var delegate: BridgesConfDelegate?


	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
			explanationLb.stringValue = NSLocalizedString(
				"Solve the CAPTCHA to request bridges.", bundle: Bundle.iPtProxyUI, comment: "")
		}
	}

	@IBOutlet weak var refreshBt: NSButton!

	@IBOutlet weak var captchaIv: NSImageView! {
		didSet {
			captchaIv.setAccessibilityLabel(NSLocalizedString(
				"CAPTCHA Image", bundle: Bundle.iPtProxyUI, comment: ""))
		}
	}
	@IBOutlet weak var solutionTf: NSTextField! {
		didSet {
			solutionTf.placeholderString = NSLocalizedString(
				"Enter characters from image", bundle: Bundle.iPtProxyUI, comment: "")

			solutionTf.delegate = self
		}
	}

	@IBOutlet weak var requestBt: NSButton! {
		didSet {
			requestBt.title = NSLocalizedString(
				"Request Bridges", bundle: Bundle.iPtProxyUI, comment: "")

			requestBt.isEnabled = false
		}
	}


	private var challenge: String?


	public convenience init() {
		self.init(nibName: String(describing: MoatMacViewController.self), bundle: .iPtProxyUI)
	}

	open override func viewWillAppear() {
		super.viewWillAppear()

		view.window?.title = NSLocalizedString(
			"Request Bridges", bundle: Bundle.iPtProxyUI, comment: "")

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
		guard var request = MoatApi.buildRequest(.fetch) else {
			return
		}

		delegate?.auth(request: &request)

		refreshBt.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		// Contact Moat service.
		let task = URLSession.shared.apiTask(with: request) { [weak self] (response: MoatApi.Wrapper<MoatApi.FetchResponse>?, error) in
			DispatchQueue.main.async {
				guard let vc = self else {
					return
				}

				hud?.hide(true)
				vc.refreshBt.isEnabled = true

				if let error = error {
					NSAlert(error: error).runModal()
					return
				}

				guard let challenge = response?.data.first?.challenge,
					  let captcha = response?.data.first?.captcha
				else {
					NSAlert(error: ApiError.notUnderstandable).runModal()
					return
				}

				vc.challenge = challenge
				vc.captchaIv.image = NSImage(data: captcha)
			}
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			task.resume()
		}
	}


	@IBAction func request(_ sender: Any) {
		guard var request = MoatApi.buildRequest(.check(challenge: challenge ?? "", solution: solutionTf.stringValue))
		else {
			return
		}

		delegate?.auth(request: &request)

		refreshBt.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		URLSession.shared.apiTask(with: request) { [weak self] (response: MoatApi.Wrapper<MoatApi.CheckResponse>?, error) in

			DispatchQueue.main.async {
				guard let vc = self else {
					return
				}

				hud?.hide(true)
				vc.refreshBt.isEnabled = true

				if let error = error {
					NSAlert(error: error).runModal()
					return
				}

				guard let bridges = response?.data.first?.bridges, !bridges.isEmpty
				else {
					NSAlert(error: ApiError.notUnderstandable).runModal()
					return
				}

				vc.delegate?.customBridges = bridges
				vc.delegate?.transport = .custom

				vc.view.window?.close()
			}
		}.resume()
	}
}
