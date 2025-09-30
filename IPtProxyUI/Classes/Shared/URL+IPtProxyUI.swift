//
//  URL+IPtProxyUI.swift
//  Pods
//
//  Created by Benjamin Erhart on 30.09.25.
//

import Foundation

public extension URL {

	var hostPort: String? {
		var value: String?

		if let host = host, !host.isEmpty {
			value = host

			if let port = port {
				value?.append(":\(port)")
			}
		}

		return value
	}

	var proxyDict: [AnyHashable: Any]? {
		guard let host, !host.isEmpty, let port else {
			return nil
		}

		var dict: [AnyHashable: Any] = [:]

		switch scheme {
		case "https":
			dict[kCFProxyTypeKey] = kCFProxyTypeHTTPS
			dict[kCFStreamPropertyHTTPSProxyHost] = host
			dict[kCFStreamPropertyHTTPSProxyPort] = port

			if let user, !user.isEmpty, let password, !password.isEmpty {
				dict[kCFProxyUsernameKey] = user
				dict[kCFProxyPasswordKey] = password
			}

		case "socks4":
			dict[kCFProxyTypeKey] = kCFProxyTypeSOCKS
			dict[kCFStreamPropertySOCKSVersion] = kCFStreamSocketSOCKSVersion4
			dict[kCFStreamPropertySOCKSProxyHost] = host
			dict[kCFStreamPropertySOCKSProxyPort] = port

		case "socks5":
			dict[kCFProxyTypeKey] = kCFProxyTypeSOCKS
			dict[kCFStreamPropertySOCKSVersion] = kCFStreamSocketSOCKSVersion5
			dict[kCFStreamPropertySOCKSProxyHost] = host
			dict[kCFStreamPropertySOCKSProxyPort] = port

			if let user, !user.isEmpty, let password, !password.isEmpty {
				dict[kCFStreamPropertySOCKSUser] = user
				dict[kCFStreamPropertySOCKSPassword] = password
			}

		default:
			return nil
		}

		return dict

	}
}
