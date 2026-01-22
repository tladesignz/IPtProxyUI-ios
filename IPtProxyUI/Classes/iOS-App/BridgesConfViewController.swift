//
//  BridgesConfViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import ProgressHUD

open class BridgesConfViewController: FixedFormViewController, UINavigationControllerDelegate,
									  BridgesConfDelegate
{

	open weak var delegate: BridgesConfDelegate?

	open var onDemandConf: OnDemand.Configuration?

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

				UIAccessibility.post(notification: .announcement, argument: self.transportsLabelMap[self.transport])
			}
		}
	}

	open var customBridges: [String]?

	open var transportsLabelMap: [Transport: String] = [
		.none: L10n.noBridges,
		.obfs4: L10n.builtInObfs4,
		.snowflake: L10n.builtInSnowflake,
		.snowflakeAmp: L10n.builtInSnowflakeAmp,
		.custom: L10n.customBridges,
	]


	open override func viewDidLoad() {
		super.viewDidLoad()

		transport = delegate?.transport ?? .none
		customBridges = delegate?.customBridges

		navigationController?.delegate = self

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

		navigationItem.title = L10n.bridgeConfiguration

		if let title = saveButtonTitle, !title.isEmpty {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: title, style: .done, target: self, action: #selector(save))
		}
		else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				barButtonSystemItem: .save, target: self, action: #selector(save))
		}

		if !(BuiltInBridges.shared?.meek?.isEmpty ?? true) {
			transportsLabelMap[.meek] = L10n.builtInMeek
		}

		if onDemandConf != nil {
			transportsLabelMap[.onDemand] = Transport.onDemand.description
		}

		transportSection.onSelectSelectableRow = { [weak self] _, row in
			if row.value == .custom {
				let vc = CustomBridgesViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			}
			else if row.value == .onDemand, let self = self {
				ProgressHUD.animate()

				DispatchQueue.global(qos: .userInitiated).async {
					OnDemand.shared.delegate = self

					OnDemand.shared.fetch(self.onDemandConf!) { bridge, error in
						if let bridge = bridge {
							Settings.onDemandBridges = [bridge]
						}

						DispatchQueue.main.async {
							if let error = error {
								ProgressHUD.failed()

								AlertHelper.present(self, message: error.localizedDescription)
							}
							else {
								ProgressHUD.succeed()
							}
						}
					}
				}
			}
		}

		transportSection.footer = HeaderFooterView(stringLiteral: L10n.bridgeTypeExplanation)

		form
		+++ Section(L10n.automaticConfiguration)
		<<< SwitchRow("cannotConnect") {
			$0.title = L10n.cannotConnect

			let font = $0.cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
			$0.cell.textLabel?.font = UIFont(name: font.familyName, size: font.pointSize * 8 / 10)
			$0.cell.textLabel?.numberOfLines = 0
		}
		<<< ButtonRow() {
			$0.title = L10n.tryAutoConfiguration
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection({ cell, row in
			ProgressHUD.animate()

			let autoconf = AutoConf(self)

			Task {
				do {
					try await autoconf.do(cannotConnectWithoutPt: (self.form.rowBy(tag: "cannotConnect") as? SwitchRow)?.value ?? false)

					await MainActor.run {
						ProgressHUD.succeed()
					}
				}
				catch {
					await MainActor.run {
						ProgressHUD.failed()

						AlertHelper.present(self, message: error.localizedDescription)
					}
				}
			}
		})

		+++ transportSection

		for t in transportsLabelMap.keys.sorted() {
			form.last! <<< ListCheckRow<Transport>() {
				$0.title = transportsLabelMap[t]
				$0.selectableValue = t
				$0.value = t == transport ? transport : nil
				$0.cell.accessibilityIdentifier = "transport_\(t.rawValue)"
			}
		}

		// The "Custom Bridges" selection is actually a button leading to another scene.
		(form.last?.first(where: { ($0 as? ListCheckRow<Transport>)?.selectableValue == .custom }) as? ListCheckRow<Transport>)?.cellUpdate({ cell, _ in
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
