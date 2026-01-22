//
//  MoatTunnel.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 22.01.26.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

extension String {

    var middle: String.Index {
        index(startIndex, offsetBy: count / 2)
    }

    var firstHalf: String {
        String(self[..<middle])
    }

    var secondHalf: String {
        String(self[middle...])
    }
}

public enum MoatTunnel: String {
    case meek

    static let meekConf = "url=https://1723079976.rsc.cdn77.org;front=www.phpmyadmin.net"

    var transport: Transport {
        switch self {
        case .meek:
            return .meek
        }
    }

    var baseUrl: URL? {
        switch self {
        case .meek:
            return URL(string: "https://bridges.torproject.org")
        }
    }

    var proxyConf: [AnyHashable: Any] {
        let user: String
        let password: String

        switch self {
        case .meek:
            user = Self.meekConf.firstHalf
            password = Self.meekConf.secondHalf
        }

        return [
            kCFProxyTypeKey as AnyHashable: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5,
            kCFStreamPropertySOCKSProxyHost: "127.0.0.1",
            kCFStreamPropertySOCKSProxyPort: transport.port,
            kCFStreamPropertySOCKSUser: user,
            kCFStreamPropertySOCKSPassword: password,
        ]
    }
}
