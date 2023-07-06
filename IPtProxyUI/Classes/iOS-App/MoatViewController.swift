//
//  MoatViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import ProgressHUD

/**
 Implements the MOAT protocol: Fetches OBFS4 bridges via Meek.
 
 The bare minimum of the communication is implemented. E.g. no check, if OBFS4 is possible or which
 protocol version the server wants to speak. The first should be always good, as OBFS4 is the most widely
 supported bridge type, the latter should be the same as we requested (0.1.0) anyway.
 
 API description:
 https://github.com/NullHypothesis/bridgedb#accessing-the-moat-interface
 */
open class MoatViewController: FixedFormViewController {

	open weak var delegate: BridgesConfDelegate?

	private var challenge: String?

	private var captchaRow = CaptchaRow("captcha") {
		$0.disabled = false
	}

	private var solutionRow = AccountRow("solution")


	open override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.requestBridges

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh, target: self, action: #selector(fetchCaptcha(_:)))

		form
		+++ Section("to be replaced in #willDisplayHeaderView to avoid capitalization")
		<<< captchaRow
			.cellUpdate({ cell, row in
				cell.accessibilityLabel = L10n.captchaImage
			})
		+++ solutionRow
			.cellSetup{ [weak self] _, row in
				row.placeholder = L10n.enterCharacters

				row.disabled = Condition.function(["captcha"]) { [weak self] _ in
					return self?.challenge == nil
				}
			}
		+++ ButtonRow() {
			$0.title = L10n.requestBridges
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

		fetchCaptcha(nil)
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

			header.textLabel?.text = L10n.solveCaptcha
		}
	}


	// MARK: Private Methods

	@objc private func fetchCaptcha(_ sender: Any?) {
		navigationItem.rightBarButtonItem?.isEnabled = false
        ProgressHUD.show()

		MoatViewControllerHelper.fetchCaptcha(delegate) { [weak self] challenge, captcha, error in
			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

				ProgressHUD.dismiss()
				self.navigationItem.rightBarButtonItem?.isEnabled = true

				if let error = error {
					AlertHelper.present(self, message: error.localizedDescription)
					return
				}

				self.challenge = challenge

				if let captcha = captcha {
					self.captchaRow.value = UIImage(data: captcha)
					self.captchaRow.updateCell()
				}
			}
		}
	}

	private func requestBridges() {
		navigationItem.rightBarButtonItem?.isEnabled = false
		ProgressHUD.show()

        MoatViewControllerHelper.requestBridges(delegate, challenge, solutionRow.value) { [weak self] bridges, error in
			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

				ProgressHUD.dismiss()
				self.navigationItem.rightBarButtonItem?.isEnabled = true

				if let error = error {
					AlertHelper.present(self, message: error.localizedDescription)
					return
				}

				guard let bridges = bridges else {
					return
				}

				self.delegate?.customBridges = bridges
				self.delegate?.transport = .custom

				self.navigationController?.popViewController(animated: true)
			}
		}
	}
}
