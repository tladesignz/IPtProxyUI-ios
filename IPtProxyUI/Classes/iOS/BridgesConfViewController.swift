//
//  BridgesConfViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import MBProgressHUD

open class BridgesConfViewController: FixedFormViewController, UINavigationControllerDelegate,
									  BridgesConfDelegate
{

	open weak var delegate: BridgesConfDelegate?

	open var transportSection: SelectableSection<ListCheckRow<Transport>> = {
		return SelectableSection<ListCheckRow<Transport>>(
			header: "", footer: "",
			selectionType: .singleSelection(enableDeselection: false))
	}()

	open var transport: Transport = .none {
		didSet {
			DispatchQueue.main.async {
				for row in self.transportSection as Section {
					guard let row = row as? ListCheckRow<Transport> else {
						continue
					}

					row.value = row.selectableValue == self.transport ? row.selectableValue : nil
					row.updateCell()
				}
			}
		}
	}

	open var customBridges: [String]?

	open override func viewDidLoad() {
		super.viewDidLoad()

		transport = delegate?.transport ?? .none
		customBridges = delegate?.customBridges

		navigationController?.delegate = self

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

		navigationItem.title = bridgeConfigurationText

		if let title = saveButtonTitle, !title.isEmpty {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: title, style: .done, target: self, action: #selector(save))
		}
		else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				barButtonSystemItem: .save, target: self, action: #selector(save))
		}

		let transports: [Transport: String] = [
			.none: noBridgesText,
			.obfs4: builtInObfs4Text,
			.snowflake: builtInSnowflakeText,
			.snowflakeAmp: builtInSnowflakeAmpText,
			.custom: customBridgesText,
		]

		transportSection.onSelectSelectableRow = { [weak self] _, row in
			if row.value == .custom {
				let vc = CustomBridgesViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			}
		}

		transportSection.footer = HeaderFooterView(stringLiteral: explanationText)

		form
		+++ Section(automaticConfigurationText)
		<<< SwitchRow("cannotConnect") {
			$0.title = cannotConnectText

			let font = $0.cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
			$0.cell.textLabel?.font = UIFont(name: font.familyName, size: font.pointSize * 8 / 10)
			$0.cell.textLabel?.numberOfLines = 0
		}
		<<< ButtonRow() {
			$0.title = tryAutoConfigurationText
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection({ cell, row in
			let hud = MBProgressHUD.showAdded(to: self.view, animated: true)

			let autoconf = AutoConf(self)
			autoconf.do(cannotConnectWithoutPt: (self.form.rowBy(tag: "cannotConnect") as? SwitchRow)?.value ?? false) { [weak self] error in
				guard let self = self else {
					return
				}

				DispatchQueue.main.async {
					if let error = error {
						hud.hide(animated: true)

						AlertHelper.present(self, message: error.localizedDescription)
					}
					else {
						var delay = 0.0

						if #available(iOS 13.0, *) {
							if let checkmark = UIImage(systemName: "checkmark") {
								hud.mode = .customView
								hud.customView = UIImageView(image: checkmark)
								delay = 1
							}
						}

						hud.hide(animated: true, afterDelay: delay)
					}
				}
			}
		})

		+++ Section(manualConfigurationText)
		<<< ButtonRow() {
			$0.title = requestBridgesText
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection { [weak self] _, _ in
			let vc = MoatViewController()
			vc.delegate = self

			self?.navigationController?.pushViewController(vc, animated: true)
		}

		+++ transportSection

		for t in transports.keys.sorted() {
			form.last! <<< ListCheckRow<Transport>() {
				$0.title = transports[t]
				$0.selectableValue = t
				$0.value = t == transport ? transport : nil
				$0.cell.accessibilityIdentifier = "transport_\(t.rawValue)"
			}
		}

		// The "Custom Bridges" selection is actually a button leading to another scene.
		(form.last?.last as? ListCheckRow<Transport>)?.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})

	}


	// MARK: UINavigationControllerDelegate

	public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		guard viewController == self else {
			return
		}

		for row in transportSection.allRows as? [ListCheckRow<Transport>] ?? [] {
			row.value = row.selectableValue == transport ? transport : nil
		}
	}


	// MARK: BridgesConfDelegate

	open var saveButtonTitle: String? {
		delegate?.saveButtonTitle
	}

	open func startMeek() {
		delegate?.startMeek()
	}

	open func stopMeek() {
		delegate?.stopMeek()
	}

	open func auth(request: inout URLRequest) {
		delegate?.auth(request: &request)
	}


	// MARK: Actions

	@objc
	open func save() {
		transport = transportSection.selectedRow()?.value ?? .none
		delegate?.transport = transport

		delegate?.customBridges = customBridges

		delegate?.save()

		navigationController?.dismiss(animated: true)
	}

	@objc
	private func cancel() {
		dismiss(animated: true)
	}
}