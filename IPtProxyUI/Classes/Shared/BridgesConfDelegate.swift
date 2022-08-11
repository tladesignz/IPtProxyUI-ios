//
//  BridgesConfDelegate.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2022-08-11.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

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
        MeekURLProtocol.start()
    }

    func stopMeek() {
        MeekURLProtocol.stop()
    }

    func auth(request: inout URLRequest) {
        // Nothing to do with the default implementation.
    }
}
