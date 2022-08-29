//
//  FixedFormViewController.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2021-11-29.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

open class FixedFormViewController: FormViewController {

	open override func keyboardWillShow(_ notification: Notification) {
		// When showing inside a popover on iPad, the popover gets resized on
		// keyboard display, so we shall not do this inside the view.
		if popoverPresentationController != nil && UIDevice.current.userInterfaceIdiom == .pad {
			return
		}

		super.keyboardWillShow(notification)
	}
}
