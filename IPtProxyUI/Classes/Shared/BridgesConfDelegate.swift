//
//  BridgesConfDelegate.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2022-08-11.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation
import OSLog

public protocol BridgesConfDelegate: AnyObject {

    var transport: Transport { get set }

    var customBridges: [String]? { get set }

    var saveButtonTitle: String? { get }

    func save()

    func startMeek()

    func auth(request: inout URLRequest)

    func stopMeek()
}

public extension BridgesConfDelegate {

    var saveButtonTitle: String? {
        nil
    }

    func startMeek() {
        do {
            try MoatTunnel.meek.transport.start()
        }
        catch {
            Logger(subsystem: "IPtProxyUI", category: String(describing: type(of: self)))
                .error("Error starting Meek transport: \(error)")
        }
    }

    func stopMeek() {
        MoatTunnel.meek.transport.stop()
    }

    func auth(request: inout URLRequest) {
        // Nothing to do with the default implementation.
    }
}
