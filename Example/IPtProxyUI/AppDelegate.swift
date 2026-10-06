//
//  AppDelegate.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03/10/2023.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI
import OSLog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
			Settings.stateLocation = url

			Logger(subsystem: "IPtProxyUI", category: String(describing: type(of: self)))
				.info("stateLocation=\(url)")
		}

		return true
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}
