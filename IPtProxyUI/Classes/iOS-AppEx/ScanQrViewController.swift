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

		navigationItem.title = L10n.scanQrCode

		view.backgroundColor = .systemGroupedBackground
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

			warning.textColor = .secondaryLabel

			view.addSubview(warning)
			warning.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
			warning.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
			warning.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
			warning.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
		}
	}
}
