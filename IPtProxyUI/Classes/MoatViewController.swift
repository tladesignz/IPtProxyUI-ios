//
//  MoatViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import MBProgressHUD

/**
Implements the MOAT protocol: Fetches OBFS4 bridges via Meek Azure.

The bare minimum of the communication is implemented. E.g. no check, if OBFS4 is possible or which
protocol version the server wants to speak. The first should be always good, as OBFS4 is the most widely
supported bridge type, the latter should be the same as we requested (0.1.0) anyway.

API description:
https://github.com/NullHypothesis/bridgedb#accessing-the-moat-interface
*/
open class MoatViewController: FixedFormViewController {

	private static let moatBaseUrl = URL(string: "https://bridges.torproject.org/moat")

	public weak var delegate: BridgeConfDelegate?

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
		guard let request = buildRequest("fetch", [
			"type": "client-transports", "supported": ["obfs4"]])
		else {
			return
		}

		navigationItem.rightBarButtonItem?.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		// Contact Moat service.
		let task = URLSession.shared.apiTask(with: request) { [weak self] payload, error in
			DispatchQueue.main.async {
				guard let vc = self else {
					return
				}

//				print("[\(String(describing: type(of: vc)))] moat request: payload=\(payload), error=\(String(describing: error))")

				hud.hide(animated: true)
				vc.navigationItem.rightBarButtonItem?.isEnabled = true

				if let error = error {
					AlertHelper.present(vc, message: error.localizedDescription)
					return
				}

				guard let data = payload["data"] as? [[String: Any]],
					  let challenge = data.first?["challenge"] as? String,
					  let image = data.first?["image"] as? String,
					  let captcha = Data(base64Encoded: image, options: .ignoreUnknownCharacters)
				else {
					AlertHelper.present(
						vc, message: NSLocalizedString("Couldn't understand server response.",
													   bundle: Bundle.iPtProxyUI, comment: ""))
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
		guard let request = buildRequest("check", [
			"id": "2", "type": "moat-solution", "transport": "obfs4",
			"challenge": challenge ?? "", "solution": solutionRow.value ?? "",
			"qrcode": "false"])
		else {
			return
		}

		navigationItem.rightBarButtonItem?.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		URLSession.shared.apiTask(with: request) { [weak self] payload, error in
//			print("[\(String(describing: type(of: self)))] moat request: payload=\(payload), error=\(String(describing: error))")

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

				if let errors = payload["errors"] as? [[String: Any]],
				   let detail = errors.first?["detail"] as? String ?? errors.first?["status"] as? String {

					AlertHelper.present(vc, message: detail)
					return
				}

				guard let data = payload["data"] as? [[String: Any]],
					  let bridges = data.first?["bridges"] as? [String]
				else {
					AlertHelper.present(
						vc, message: NSLocalizedString("Couldn't understand server response.",
													   bundle: Bundle.iPtProxyUI, comment: ""))
					return
				}

				vc.delegate?.customBridges = bridges.isEmpty ? nil : bridges
				vc.delegate?.bridgesType = .custom

				vc.navigationController?.popViewController(animated: true)
			}
		}.resume()
	}

	private func buildRequest(_ endpoint: String, _ payload: [String: Any]) -> URLRequest? {
		guard let url = MoatViewController.moatBaseUrl?.appendingPathComponent(endpoint) else {
			return nil
		}

		var payload = ["data": [payload]]
		payload["data"]?[0]["version"] = "0.1.0"

//		print("[\(String(describing: type(of: self)))] request payload=\(payload)")

		let request = NSMutableURLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
		request.addValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")

		delegate?.auth(request: request)

		return request as URLRequest
	}
}
