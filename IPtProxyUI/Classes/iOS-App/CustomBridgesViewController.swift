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
import PhotosUI

open class CustomBridgesViewController: FixedFormViewController, UIImagePickerControllerDelegate,
										PHPickerViewControllerDelegate, UINavigationControllerDelegate,
										MFMailComposeViewControllerDelegate, ScanQrDelegate
{

	open weak var delegate: BridgesConfDelegate?


	private let textAreaRow = TextAreaRow() {
		$0.placeholder = BuiltInBridges.shared?.obfs4?.first?.raw
		$0.cell.clipsToBounds = true
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
			$0.title = L10n.scanQrCode
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
			$0.title = L10n.uploadQrCode
		}
		.cellUpdate({ cell, _ in
			cell.accessibilityTraits = .button
		})
		.onCellSelection({ [weak self] _, _ in
			guard let self = self else {
				return
			}

			let picker: UIViewController

			if #available(iOS 14.0, *) {
				var conf = PHPickerConfiguration()
				conf.filter = PHPickerFilter.images

				let vc = PHPickerViewController(configuration: conf)
				vc.delegate = self

				picker = vc
			}
			else {
				let vc = UIImagePickerController()
				vc.sourceType = .photoLibrary
				vc.delegate = self

				picker = vc
			}

			self.present(picker, animated: true)
		})


		if MFMailComposeViewController.canSendMail() || UIApplication.shared.canOpenURL(Constants.telegramBot) {
			form
			+++ Section(NSLocalizedString("Other", bundle: .iPtProxyUI, comment: ""))
		}

		if MFMailComposeViewController.canSendMail() {
			form.last!
			<<< ButtonRow() {
				$0.title = L10n.requestViaEmail
			}
			.cellUpdate({ cell, _ in
				cell.accessibilityTraits = .button
			})
			.onCellSelection({ [weak self] _, _ in
				let vc = MFMailComposeViewController()
				vc.mailComposeDelegate = self
				vc.setToRecipients([Constants.emailRecipient])
				vc.setSubject(Constants.emailSubjectAndBody)
				vc.setMessageBody(Constants.emailSubjectAndBody, isHTML: false)

				self?.present(vc, animated: true)
			})
		}

		if UIApplication.shared.canOpenURL(Constants.telegramBot) {
			form.last!
			<<< ButtonRow() {
				$0.title = L10n.requestViaTelegram
			}
			.cellUpdate({ cell, _ in
				cell.accessibilityTraits = .button
			})
			.onCellSelection({ _, _ in
				UIApplication.shared.open(Constants.telegramBot)
			})
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		Helpers.update(delegate: delegate, textAreaRow.value)
	}


	// MARK: UIImagePickerControllerDelegate

	public func imagePickerController(_ picker: UIImagePickerController,
									  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
	{
		picker.dismiss(animated: true)

		extract(from: (info[.editedImage] ?? info[.originalImage]) as? UIImage)
	}

	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}


	// MARK: PHPickerViewControllerDelegate

	@available(iOS 14.0, *)
	public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		picker.dismiss(animated: true)

		results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
			self?.extract(from: object as? UIImage)
		}
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
		Helpers.update(delegate: delegate, textAreaRow.value)

		delegate?.save()
	}

	private func extract(from image: UIImage?) {
		let bridges = BaseScanViewController.extractBridges(from: image)

		DispatchQueue.main.async {
			if let bridges = bridges {
				self.textAreaRow.value = bridges.joined(separator: "\n")
				self.textAreaRow.updateCell()
			}
			else {
				AlertHelper.present(self, message: ScanError.notBridges.localizedDescription)
			}
		}
	}
}
