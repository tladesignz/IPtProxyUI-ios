//
//  BridgesConfViewController.swift
//  IPtProxyUI-macOS
//
//  Created by Benjamin Erhart on 26.08.22.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Cocoa

open class BridgesConfViewController: NSViewController, BridgesConfDelegate, NSWindowDelegate,
									  NSComboBoxDataSource, NSComboBoxDelegate
{

	open weak var delegate: BridgesConfDelegate?

	open var transport: Transport = .none {
		didSet {
			DispatchQueue.main.async {
				switch self.transport {
				case .obfs4:
					self.obfs4Rb.state = .on
					self.announce(self.obfs4Rb.title)

				case .snowflake:
					self.snowflakeRb.state = .on
					self.announce(self.snowflakeRb.title)

				case .snowflakeAmp:
					self.snowflakeAmpRb.state = .on
					self.announce(self.snowflakeAmpRb.title)

				case .meek:
					self.meekRb.state = .on
					self.announce(self.meekRb.title)

				case .dnstt:
					self.dnsttRb.state = .on
					self.announce(self.dnsttRb.title)

				case .custom:
					self.customBridgesRb.state = .on
					self.announce(self.customBridgesRb.title)

				default:
					self.noBridgesRb.state = .on
					self.announce(self.noBridgesRb.title)
				}
			}
		}
	}

	open var customBridges: [String]?


	@IBOutlet weak var autoConfBox: NSBox! {
		didSet {
			autoConfBox.title = L10n.automaticConfiguration
		}
	}

	@IBOutlet weak var cannotConnectLb: NSTextField! {
		didSet {
			cannotConnectLb.stringValue = L10n.cannotConnect
			cannotConnectLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var cannotConnectSw: NSSwitch! {
		didSet {
			cannotConnectSw.setAccessibilityLabel(L10n.cannotConnect)
		}
	}

	@IBOutlet weak var countryCb: NSComboBox! {
		didSet {
			countryCb.placeholderString = L10n.myCountry

			countryCb.stringValue = Country.selected?.description ?? ""
		}
	}

	@IBOutlet weak var tryAutoConfBt: NSButton! {
		didSet {
			tryAutoConfBt.title = L10n.tryAutoConfiguration
		}
	}

	@IBOutlet weak var noBridgesRb: NSButton! {
		didSet {
			noBridgesRb.title = L10n.noBridges
		}
	}

	@IBOutlet weak var obfs4Rb: NSButton! {
		didSet {
			obfs4Rb.title = L10n.builtInObfs4
		}
	}

	@IBOutlet weak var snowflakeRb: NSButton! {
		didSet {
			snowflakeRb.title = L10n.builtInSnowflake
		}
	}

	@IBOutlet weak var snowflakeAmpRb: NSButton! {
		didSet {
			snowflakeAmpRb.title = L10n.builtInSnowflakeAmp
		}
	}

	@IBOutlet weak var meekRb: NSButton! {
		didSet {
			meekRb.title = L10n.builtInMeek
		}
	}

	@IBOutlet weak var dnsttRb: NSButton! {
		didSet {
			dnsttRb.title = L10n.builtInDnstt
		}
	}

	@IBOutlet weak var customBridgesRb: NSButton! {
		didSet {
			customBridgesRb.title = L10n.customBridges
		}
	}

	@IBOutlet weak var descLb: NSTextField! {
		didSet {
			descLb.stringValue = L10n.bridgeTypeExplanation
		}
	}

	@IBOutlet weak var cancelBt: NSButton! {
		didSet {
			cancelBt.title = L10n.cancel
		}
	}

	@IBOutlet weak var saveBt: NSButton!


	private var filteredCountries = Country.all


	public convenience init() {
		self.init(nibName: String(describing: BridgesConfViewController.self), bundle: .iPtProxyUI)
	}


	open override func viewWillAppear() {
		super.viewWillAppear()

		view.window?.title = L10n.bridgeConfiguration

		saveBt.title = saveButtonTitle ?? L10n.save

		view.window?.defaultButtonCell = saveBt.cell as? NSButtonCell
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

	open func save() {
		delegate?.transport = transport

		delegate?.customBridges = customBridges

		delegate?.save()
	}


	// MARK: NSWindowDelegate

	public func windowWillClose(_ notification: Notification) {
		NSApp.stopModal()
	}


	// MARK: NSComboBoxDataSource

	public func numberOfItems(in comboBox: NSComboBox) -> Int {
		filteredCountries.count
	}

	public func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		filteredCountries[index].description
	}


	// MARK: NSComboBoxDelegate

	public func controlTextDidChange(_ obj: Notification) {
		guard let comboBox = obj.object as? NSComboBox else {
			return
		}

		let search = comboBox.stringValue

		if search.isEmpty {
			filteredCountries = Country.all
		}
		else {
			filteredCountries = Country.all.filter({
				$0.localizedName.localizedCaseInsensitiveContains(search)
			})
		}

		comboBox.reloadData()

		if !(comboBox.cell?.isAccessibilityExpanded() ?? false) {
			comboBox.cell?.setAccessibilityExpanded(true)
		}
	}


	// MARK: Actions

	@IBAction func changeCountry(_ sender: NSComboBox) {
		let entered = sender.stringValue

		let country = Country.all.first { $0.description.localizedCaseInsensitiveCompare(entered) == .orderedSame }


		if let country {
			Settings.countryCode = country.code
		}
		else {
			sender.stringValue = ""
			Settings.countryCode = nil
		}
	}

	@IBAction open func tryAutoConf(_ sender: Any) {
		let hud = MBProgressHUD.showAdded(to: self.view, animated: true)

		announce(L10n.tryAutoConfiguration)

		let autoconf = AutoConf(self)
		Task {
			do {
				try await autoconf.do(country: Settings.countryCode, cannotConnectWithoutPt: cannotConnectSw.state == .on)

				await MainActor.run {
					var delay = 0.0

					if let checkmark = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil) {
						checkmark.isTemplate = true

						let iv = NSImageView(image: checkmark)
						iv.contentTintColor = .white

						hud?.mode = MBProgressHUDModeCustomView
						hud?.customView = iv

						delay = 1
					}

					hud?.hide(true, afterDelay: delay)
				}
			}
			catch {
				await MainActor.run {
					hud?.hide(true)

					NSAlert(error: error).runModal()
				}
			}
		}
	}

	@IBAction open func selectBridge(_ sender: NSButton) {
		if sender == obfs4Rb {
			transport = .obfs4
		}
		else if sender == snowflakeRb {
			transport = .snowflake
		}
		else if sender == snowflakeAmpRb {
			transport = .snowflakeAmp
		}
		else if sender == meekRb {
			transport = .meek
		}
		else if sender == dnsttRb {
			transport = .dnstt
		}
		else if sender == customBridgesRb {
			let vc = CustomBridgesViewController()
			vc.delegate = self

			let window = NSWindow(contentViewController: vc)
			window.delegate = self

			NSApp.runModal(for: window)

			window.close()

			// Trigger reset of selected transport UI, in case
			// the user never added custom bridges.
			let t = transport
			transport = t
		}
		else {
			transport = .none
		}
	}

	@IBAction open func cancel(_ sender: Any) {
		NSApp.stopModal()

		view.window?.close()
	}

	@IBAction open func save(_ sender: Any) {
		save()

		NSApp.stopModal()

		view.window?.close()
	}


	// MARK: Private Methods

	private func announce(_ text: String) {
		if let window = NSApp.mainWindow {
			NSAccessibility.post(
				element: window,
				notification: .announcementRequested,
				userInfo: [.announcement: text,
						   .priority: NSAccessibilityPriorityLevel.high.rawValue])
		}
	}
}
