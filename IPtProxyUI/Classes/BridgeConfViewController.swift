//
//  BridgeConfViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import NetworkExtension

public protocol BridgeConfDelegate: AnyObject {

	var bridgesType: Bridge { get set }

	var customBridges: [String]? { get set }

	func save()
}

open class BridgeConfViewController: FixedFormViewController, UINavigationControllerDelegate,
									 BridgeConfDelegate
{

	open weak var delegate: BridgeConfDelegate?

	private let bridgesSection: SelectableSection<ListCheckRow<Bridge>> = {
		let description = [
			NSLocalizedString("If you are in a country or using a connection that censors Tor, you might need to use bridges.",
							  bundle: Bundle.iPtProxyUI, comment: ""),
			"",
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic appear \"random\".",
				bundle: Bundle.iPtProxyUI, comment: ""), "\u{2022}", "obfs4"),
			String(format: NSLocalizedString(
				"%1$@ %2$@ makes your traffic look like a phone call to a random user on the net.",
				bundle: Bundle.iPtProxyUI, comment: ""), "\u{2022}", "snowflake"),
			"",
			NSLocalizedString("If one type of bridge does not work, try using a different one.",
							  bundle: Bundle.iPtProxyUI, comment: "")
		]

		return SelectableSection<ListCheckRow<Bridge>>(
			header: "", footer: description.joined(separator: "\n"),
			selectionType: .singleSelection(enableDeselection: false))
	}()

	public var bridgesType: Bridge = .none {
		didSet {
			for row in bridgesSection {
				if (row as? ListCheckRow<Bridge>)?.value == bridgesType {
					row.select()
				}
				else {
					row.deselect()
				}
			}
		}
	}

	public var customBridges: [String]?

	open override func viewDidLoad() {
		super.viewDidLoad()

		bridgesType = delegate?.bridgesType ?? .none
		customBridges = delegate?.customBridges

		navigationController?.delegate = self

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

		navigationItem.title = NSLocalizedString("Bridge Configuration",
												 bundle: Bundle.iPtProxyUI, comment: "")

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .save, target: self, action: #selector(save))

		let bridges: [Bridge: String] = [
			.none: NSLocalizedString(
				"No Bridges", bundle: Bundle.iPtProxyUI, comment: ""),
			.obfs4: String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "obfs4"),
			.snowflake: String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "snowflake"),
			.custom: NSLocalizedString(
				"Custom Bridges", bundle: Bundle.iPtProxyUI, comment: ""),
		]

		bridgesSection.onSelectSelectableRow = { [weak self] _, row in
			if row.value == .custom {
				let vc = CustomBridgesViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			}
		}

		form
		+++ ButtonRow() {
			$0.title = NSLocalizedString("Request Bridges from torproject.org",
										 bundle: Bundle.iPtProxyUI, comment: "")
		}
		.onCellSelection { [weak self] _, _ in
			let vc = MoatViewController()
			vc.delegate = self

			self?.navigationController?.pushViewController(vc, animated: true)
		}

		+++ bridgesSection

		for option in bridges.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
			form.last! <<< ListCheckRow<Bridge>() {
				$0.title = option.value
				$0.selectableValue = option.key
				$0.value = option.key == bridgesType ? bridgesType : nil
			}
		}
	}


	// MARK: UINavigationControllerDelegate

	public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		guard viewController == self else {
			return
		}

		for row in bridgesSection.allRows as? [ListCheckRow<Bridge>] ?? [] {
			row.value = row.selectableValue == bridgesType ? bridgesType : nil
		}
	}


	// MARK: Actions

	@objc
	public func save() {
		bridgesType = bridgesSection.selectedRow()?.value ?? .none
		delegate?.bridgesType = bridgesType

		delegate?.customBridges = customBridges

		delegate?.save()

		navigationController?.dismiss(animated: true)
	}

	@objc
	private func cancel() {
		dismiss(animated: true)
	}
}
