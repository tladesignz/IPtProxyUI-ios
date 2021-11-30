//
//  CustomBridgesViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2021 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import MessageUI

open class CustomBridgesViewController: FixedFormViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, ScanQrDelegate {

	public weak var delegate: BridgesConfDelegate?

	private static let bridgesUrl = "https://bridges.torproject.org/"

	private lazy var picker: UIImagePickerController = {
		let picker = UIImagePickerController()

		picker.sourceType = .photoLibrary
		picker.delegate = self

		return picker
	}()

	private let textAreaRow = TextAreaRow() {
		$0.placeholder = Transport.builtInObfs4Bridges.first
		$0.cell.placeholderLabel?.font = .systemFont(ofSize: 15)
		$0.cell.textLabel?.font = .systemFont(ofSize: 15)
	}

	private lazy var detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    open override func viewDidLoad() {
		super.viewDidLoad()

		textAreaRow.value = delegate?.customBridges?.joined(separator: "\n")

		navigationItem.title = NSLocalizedString(
			"Use Custom Bridges", bundle: Bundle.iPtProxyUI, comment: "")

		if let title = delegate?.saveButtonTitle, !title.isEmpty {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: title, style: .done, target: self, action: #selector(save))
		}
		else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				barButtonSystemItem: .save, target: self, action: #selector(save))
		}
		navigationItem.rightBarButtonItem?.isEnabled = !(textAreaRow.value?.isEmpty ?? true)

		form
		+++ Section(footer:
			String(format: NSLocalizedString(
				"In a separate browser, visit %@ and tap \"Get Bridges\" > \"Just Give Me Bridges!\"",
				bundle: Bundle.iPtProxyUI, comment: ""), CustomBridgesViewController.bridgesUrl))

		+++ ButtonRow() {
			$0.title = NSLocalizedString("Copy URL to Clipboard",
										 bundle: Bundle.iPtProxyUI, comment: "")
		}
		.onCellSelection({ _, _ in
			UIPasteboard.general.string = CustomBridgesViewController.bridgesUrl
		})

		+++ Section(NSLocalizedString("Paste Bridges", bundle: Bundle.iPtProxyUI, comment: ""))
			<<< textAreaRow
			.onChange({ [weak self] row in
				self?.navigationItem.rightBarButtonItem?.isEnabled = !(row.value?.isEmpty ?? true)
			})

		+++ Section(NSLocalizedString("Use QR Code", bundle: Bundle.iPtProxyUI, comment: ""))
			<<< ButtonRow() {
				$0.title = NSLocalizedString("Scan QR Code",
											 bundle: Bundle.iPtProxyUI, comment: "")
			}
			.onCellSelection({ [weak self] _, _ in
				let vc = ScanQrViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			})
			<<< ButtonRow() {
				$0.title = NSLocalizedString("Upload QR Code", bundle: Bundle.iPtProxyUI, comment: "")
			}
			.onCellSelection({ [weak self] _, _ in
				if let self = self {
					self.present(self.picker, animated: true)
				}
			})

		if MFMailComposeViewController.canSendMail() {
			form
			+++ Section(NSLocalizedString("E-Mail", bundle: Bundle.iPtProxyUI, comment: ""))
				<<< ButtonRow() {
					$0.title = NSLocalizedString("Request via E-Mail",
												 bundle: Bundle.iPtProxyUI, comment: "")
				}
				.onCellSelection({ [weak self] _, _ in
					let vc = MFMailComposeViewController()
					vc.mailComposeDelegate = self
					vc.setToRecipients(["bridges@torproject.org"])
					vc.setSubject("get transport")
					vc.setMessageBody("get transport", isHTML: false)

					self?.present(vc, animated: true)
				})
		}
	}

    open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		updateDelegate()
	}

	// MARK: UIImagePickerControllerDelegate

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true)

		var raw = ""

		if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
			let ciImage = image.ciImage ?? (image.cgImage != nil ? CIImage(cgImage: image.cgImage!) : nil) {

			let features = detector?.features(in: ciImage)

			for feature in features as? [CIQRCodeFeature] ?? [] {
				raw += feature.messageString ?? ""
			}
		}

		scanned(value: raw)
	}

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}


    // MARK: MFMailComposeViewControllerDelegate

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }


	// MARK: ScanQrDelegate

    public func scanned(value raw: String?) {
		// They really had to use JSON for content encoding but with illegal single quotes instead
		// of double quotes as per JSON standard. Srsly?
		if let data = raw?.replacingOccurrences(of: "'", with: "\"").data(using: .utf8),
			let newBridges = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {

			textAreaRow.value = newBridges.joined(separator: "\n")
			textAreaRow.updateCell()
		}
		else {
			AlertHelper.present(self, message:
				String(format: NSLocalizedString(
					"QR Code could not be decoded! Are you sure you scanned a QR code from %@?",
					bundle: Bundle.iPtProxyUI, comment: ""), CustomBridgesViewController.bridgesUrl))
		}
	}


	// MARK: Private Methods

	@objc
	private func save() {
		updateDelegate()

		delegate?.save()
	}

	private func updateDelegate() {
		delegate?.customBridges = textAreaRow.value?
				.components(separatedBy: "\n")
				.map({ bridge in bridge.trimmingCharacters(in: .whitespacesAndNewlines) })
				.filter({ bridge in !bridge.isEmpty && !bridge.hasPrefix("//") && !bridge.hasPrefix("#") })

		if delegate?.customBridges?.isEmpty ?? true {
			if delegate?.transport == .custom {
				delegate?.transport = .none
			}
		}
		else {
			delegate?.transport = .custom
		}
	}
}
