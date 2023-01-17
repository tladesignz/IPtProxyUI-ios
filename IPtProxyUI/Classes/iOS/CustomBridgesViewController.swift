//
//  CustomBridgesViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import MessageUI

open class CustomBridgesViewController: FixedFormViewController, UIImagePickerControllerDelegate,
										UINavigationControllerDelegate, MFMailComposeViewControllerDelegate,
										ScanQrDelegate
{

	open weak var delegate: BridgesConfDelegate?


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
			"Use Custom Bridges", bundle: .iPtProxyUI, comment: "")

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
        +++ Section(footer: L10n.customBridgesExplanation)

		+++ ButtonRow() {
            $0.title = L10n.copyToClipboard
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection({ _, _ in
            UIPasteboard.general.string = Constants.bridgesUrl.absoluteString
		})

        +++ Section(L10n.pasteBridges)
		<<< textAreaRow
			.onChange({ [weak self] row in
				self?.navigationItem.rightBarButtonItem?.isEnabled = !(row.value?.isEmpty ?? true)
			})

		+++ Section(NSLocalizedString("Use QR Code", bundle: .iPtProxyUI, comment: ""))
			<<< ButtonRow() {
				$0.title = NSLocalizedString("Scan QR Code",
											 bundle: .iPtProxyUI, comment: "")
			}
			.cellUpdate({ cell, _ in
				cell.accessibilityTraits = .button
			})
			.onCellSelection({ [weak self] _, _ in
				let vc = ScanQrViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			})
			<<< ButtonRow() {
				$0.title = NSLocalizedString("Upload QR Code", bundle: .iPtProxyUI, comment: "")
			}
			.cellUpdate({ cell, _ in
				cell.accessibilityTraits = .button
			})
			.onCellSelection({ [weak self] _, _ in
				if let self = self {
					self.present(self.picker, animated: true)
				}
			})

		if MFMailComposeViewController.canSendMail() {
			form
			+++ Section(NSLocalizedString("E-Mail", bundle: .iPtProxyUI, comment: ""))
				<<< ButtonRow() {
					$0.title = requestViaEmailText
				}
				.cellUpdate({ cell, _ in
					cell.accessibilityTraits = .button
				})
				.onCellSelection({ [weak self] _, _ in
					let vc = MFMailComposeViewController()
					vc.mailComposeDelegate = self
					vc.setToRecipients([Self.emailRecipient])
					vc.setSubject(Self.emailSubjectAndBody)
					vc.setMessageBody(Self.emailSubjectAndBody, isHTML: false)

					self?.present(vc, animated: true)
				})
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		updateDelegate(textAreaRow.value)
	}


	// MARK: UIImagePickerControllerDelegate

	public func imagePickerController(_ picker: UIImagePickerController,
									  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
	{
		picker.dismiss(animated: true)

		var raw = ""

		if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
		   let ciImage = image.ciImage ?? (image.cgImage != nil ? CIImage(cgImage: image.cgImage!) : nil)
		{
			let features = detector?.features(in: ciImage)

			for feature in features as? [CIQRCodeFeature] ?? [] {
				raw += feature.messageString ?? ""
			}
		}

		if let bridges = BaseScanViewController.extractBridges(from: raw) {
			textAreaRow.value = bridges.joined(separator: "\n")
			textAreaRow.updateCell()
		}
		else {
			AlertHelper.present(self, message: ScanError.notBridges.localizedDescription)
		}
	}

	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}


	// MARK: MFMailComposeViewControllerDelegate

	public func mailComposeController(_ controller: MFMailComposeViewController,
									  didFinishWith result: MFMailComposeResult,
									  error: Error?)
	{
		controller.dismiss(animated: true)
	}


	// MARK: ScanQrDelegate

	public func scanned(bridges: [String]) {
		navigationController?.popViewController(animated: true)

		textAreaRow.value = bridges.joined(separator: "\n")
		textAreaRow.updateCell()
	}

	public func scanned(error: Error) {
		navigationController?.popViewController(animated: true)

		AlertHelper.present(self, message: error.localizedDescription)
	}


	// MARK: Private Methods

	@objc
	private func save() {
		updateDelegate(textAreaRow.value)

		delegate?.save()
	}
}
