//
//  MoatViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import MBProgressHUD

/**
 Implements the MOAT protocol: Fetches OBFS4 bridges via Meek.
 
 The bare minimum of the communication is implemented. E.g. no check, if OBFS4 is possible or which
 protocol version the server wants to speak. The first should be always good, as OBFS4 is the most widely
 supported bridge type, the latter should be the same as we requested (0.1.0) anyway.
 
 API description:
 https://github.com/NullHypothesis/bridgedb#accessing-the-moat-interface
 */
open class MoatViewController: FixedFormViewController {

	public weak var delegate: BridgesConfDelegate?

	private var challenge: String?

	private var captchaRow = CaptchaRow("captcha") {
		$0.disabled = false
	}

	private var solutionRow = AccountRow("solution") {
		$0.placeholder = NSLocalizedString("Enter characters from image",
										   bundle: Bundle.iPtProxyUI, comment: "")
	}


	open override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Request Bridges",
												 bundle: Bundle.iPtProxyUI, comment: "")

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh, target: self, action: #selector(fetchCaptcha))

		form
		+++ Section("to be replaced in #willDisplayHeaderView to avoid capitalization")
		<<< captchaRow
			.cellUpdate({ cell, row in
				cell.accessibilityLabel = NSLocalizedString("CAPTCHA Image", bundle: Bundle.iPtProxyUI, comment: "")
			})
		+++ solutionRow
			.cellSetup{ _, row in
				row.disabled = Condition.function(["captcha"]) { [weak self] _ in
					return self?.challenge == nil
				}
			}
		+++ ButtonRow() {
			$0.title = NSLocalizedString("Request Bridges",
										 bundle: Bundle.iPtProxyUI, comment: "")
			$0.disabled = Condition.function(["solution"]) { [weak self] form in
				return self?.challenge == nil
				|| (form.rowBy(tag: "solution") as? AccountRow)?.value?.isEmpty ?? true
			}
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection { [weak self] _, row in
			if !row.isDisabled {
				self?.requestBridges()
			}
		}
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		delegate?.startMeek()

		fetchCaptcha()
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		delegate?.stopMeek()
	}


	// MARK: UITableViewDelegate

	/**
	 Workaround to avoid capitalization of header.
	 */
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if section == 0,
		   let header = view as? UITableViewHeaderFooterView {

			header.textLabel?.text = NSLocalizedString(
				"Solve the CAPTCHA to request bridges.",
				bundle: Bundle.iPtProxyUI, comment: "")
		}
	}


	// MARK: Private Methods

	@objc private func fetchCaptcha() {
		guard var request = MoatApi.buildRequest(.fetch) else {
			return
		}

		delegate?.auth(request: &request)

		navigationItem.rightBarButtonItem?.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		// Contact Moat service.
		let task = URLSession.shared.apiTask(with: request) { [weak self] (response: MoatApi.Wrapper<MoatApi.FetchResponse>?, error) in
			DispatchQueue.main.async {
				guard let vc = self else {
					return
				}

				hud.hide(animated: true)
				vc.navigationItem.rightBarButtonItem?.isEnabled = true

				if let error = error {
					AlertHelper.present(vc, message: error.localizedDescription)
					return
				}

				guard let challenge = response?.data.first?.challenge,
					  let captcha = response?.data.first?.captcha
				else {
					AlertHelper.present(vc, message: ApiError.notUnderstandable.localizedDescription)
					return
				}

				vc.challenge = challenge
				vc.captchaRow.value = UIImage(data: captcha)
				vc.captchaRow.updateCell()
			}
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			task.resume()
		}
	}

	private func requestBridges() {
		guard var request = MoatApi.buildRequest(.check(challenge: challenge ?? "", solution: solutionRow.value ?? ""))
		else {
			return
		}

		delegate?.auth(request: &request)

		navigationItem.rightBarButtonItem?.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		URLSession.shared.apiTask(with: request) { [weak self] (response: MoatApi.Wrapper<MoatApi.CheckResponse>?, error) in

			DispatchQueue.main.async {
				guard let vc = self else {
					return
				}

				hud.hide(animated: true)
				vc.navigationItem.rightBarButtonItem?.isEnabled = true

				if let error = error {
					AlertHelper.present(vc, message: error.localizedDescription)
					return
				}

				guard let bridges = response?.data.first?.bridges, !bridges.isEmpty
				else {
					AlertHelper.present(vc, message: ApiError.notUnderstandable.localizedDescription)
					return
				}

				vc.delegate?.customBridges = bridges
				vc.delegate?.transport = .custom

				vc.navigationController?.popViewController(animated: true)
			}
		}.resume()
	}
}
