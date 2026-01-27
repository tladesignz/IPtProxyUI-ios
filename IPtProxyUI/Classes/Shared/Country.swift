//
//  Country.swift
//  Pods
//
//  Created by Benjamin Erhart on 26.01.26.
//

import Foundation

open class Country: Comparable, CustomStringConvertible, Codable {

	// MARK: Comparable

	public static func == (lhs: Country, rhs: Country) -> Bool {
		lhs.code == rhs.code
	}

	public static func < (lhs: Country, rhs: Country) -> Bool {
		lhs.localizedName < rhs.localizedName
	}

	public static func > (lhs: Country, rhs: Country) -> Bool {
		lhs.localizedName > rhs.localizedName
	}


	// MARK: Country
	/**
	 All countries Apple knows about.
	 */
	public static var all: [Country] = {
		NSLocale.isoCountryCodes.map { Country(code: $0) }.sorted()
	}()

	/**
	 The ``Country`` object from ``Country.all`` which has the stored ``Settings.countryCode``.
	 */
	public static var selected: Country? {
		guard let code = Settings.countryCode
		else {
			return nil
		}

		return all.first { $0.code == code }
	}


	/**
	 The ISO country code.
	 */
	public let code: String

	private var _flag: String?

	/**
	 The country's flag as Emoji.
	 */
	open var flag: String {
		if _flag == nil {
			let base: UInt32 = 127397
			_flag = ""

			for v in code.uppercased().unicodeScalars {
				_flag?.unicodeScalars.append(UnicodeScalar(base + v.value)!)
			}
		}
		
		return _flag!
	}

	fileprivate var _localizedName: String?

	/**
	 The localized country name.
	 */
	open var localizedName: String {
		if _localizedName == nil {
			_localizedName = Locale.current.localizedString(forRegionCode: code) ?? code
		}

		return _localizedName!
	}


	/**
	 - parameter code: The ISO country code.
	 */
	public init(code: String) {
		self.code = code.lowercased()
	}


	/**
	 Clears the Emoji ``flag`` and ``localizedName`` cache.

	 Useful, when user changed localization.
	 See ``NSLocale.currentLocaleDidChangeNotification``.

	 You should also resort your country list, afterwards!
	 */
	open func clearCache() {
		_flag = nil
		_localizedName = nil
	}


	// MARK: CustomStringConvertible

	/**
	 String of ``flag`` and ``localizedName``.
	 */
	open var description: String {
		"\(flag) \(localizedName)"
	}
}
