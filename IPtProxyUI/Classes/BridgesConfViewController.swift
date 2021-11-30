//
//  BridgesConfViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

public protocol BridgesConfDelegate: AnyObject {

	var transport: Transport { get set }

	var customBridges: [String]? { get set }

	var saveButtonTitle: String? { get }

	func save()

	func startMeek()

	func auth(request: NSMutableURLRequest)

	func stopMeek()
}

public extension BridgesConfDelegate {

	var saveButtonTitle: String? {
		nil
	}

	func startMeek() {
		MeekURLProtocol.start()
	}

	func stopMeek() {
		MeekURLProtocol.stop()
	}

	func auth(request: NSMutableURLRequest) {
		// Nothing to do with the default implementation.
	}
}

open class BridgesConfViewController: FixedFormViewController, UINavigationControllerDelegate,
									 BridgesConfDelegate
{

	open weak var delegate: BridgesConfDelegate?

	open var transportSection: SelectableSection<ListCheckRow<Transport>> = {
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

		return SelectableSection<ListCheckRow<Transport>>(
			header: "", footer: description.joined(separator: "\n"),
			selectionType: .singleSelection(enableDeselection: false))
	}()

	open var transport: Transport = .none {
		didSet {
			for row in transportSection {
				if (row as? ListCheckRow<Transport>)?.value == transport {
					row.select()
				}
				else {
					row.deselect()
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

		navigationItem.title = NSLocalizedString("Bridge Configuration",
												 bundle: Bundle.iPtProxyUI, comment: "")

		if let title = saveButtonTitle, !title.isEmpty {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: title, style: .done, target: self, action: #selector(save))
		}
		else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				barButtonSystemItem: .save, target: self, action: #selector(save))
		}

		let bridges: [Transport: String] = [
			.none: NSLocalizedString(
				"No Bridges", bundle: Bundle.iPtProxyUI, comment: ""),
			.obfs4: String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "obfs4"),
			.snowflake: String(format: NSLocalizedString(
				"Built-in %@", bundle: Bundle.iPtProxyUI, comment: ""), "snowflake"),
			.custom: NSLocalizedString(
				"Custom Bridges", bundle: Bundle.iPtProxyUI, comment: ""),
		]

		transportSection.onSelectSelectableRow = { [weak self] _, row in
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

		+++ transportSection

		for option in bridges.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
			form.last! <<< ListCheckRow<Transport>() {
				$0.title = option.value
				$0.selectableValue = option.key
				$0.value = option.key == transport ? transport : nil
			}
		}
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

	open func auth(request: NSMutableURLRequest) {
		delegate?.auth(request: request)
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
