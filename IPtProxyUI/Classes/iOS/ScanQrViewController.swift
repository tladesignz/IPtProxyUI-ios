//
//  ScanQrViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit

open class ScanQrViewController: BaseScanViewController {

	open override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString(
			"Scan QR Code", bundle: .iPtProxyUI, comment: "")

		if #available(iOS 13.0, *) {
			view.backgroundColor = .systemGroupedBackground
		}
		else {
			view.backgroundColor = .init(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
		}
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		do {
			try startReading()

			videoPreviewLayer?.frame = view.layer.bounds
			view.layer.addSublayer(videoPreviewLayer!)
		}
		catch {
			let warning = UILabel(frame: .zero)
			warning.text = error.localizedDescription
			warning.translatesAutoresizingMaskIntoConstraints = false
			warning.numberOfLines = 0
			warning.textAlignment = .center

			if #available(iOS 13.0, *) {
				warning.textColor = .secondaryLabel
			}
			else {
				warning.textColor = .init(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.6)
			}

			view.addSubview(warning)
			warning.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
			warning.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
			warning.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
			warning.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
		}
	}
}
