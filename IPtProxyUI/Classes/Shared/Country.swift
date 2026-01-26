//
//  Country.swift
//  Pods
//
//  Created by Benjamin Erhart on 26.01.26.
//

import Foundation

class Country: Equatable, CustomStringConvertible {

	static func == (lhs: Country, rhs: Country) -> Bool {
		lhs.code == rhs.code
	}

	static var all: [Country] = {
		NSLocale.isoCountryCodes.map { Country(code: $0) }
	}()

	static var selected: Country? {
		guard let code = Settings.countryCode
		else {
			return nil
		}

		return all.first { $0.code == code }
	}

	let code: String

	private var _flag: String?
	var flag: String {
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
	var localizedName: String {
		if _localizedName == nil {
			_localizedName = Locale.current.localizedString(forRegionCode: code) ?? code
		}

		return _localizedName!
	}

	init(code: String) {
		self.code = code.lowercased()
	}

	var description: String {
		"\(flag) \(localizedName)"
	}
}
