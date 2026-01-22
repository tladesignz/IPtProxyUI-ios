//
//  update-bridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03.12.19.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

// MARK: Config

let baseUrl = URL(string: "https://bridges.torproject.org")

let request = MoatApi.buildRequest(baseUrl, .builtin)

let outfile = resolve("IPtProxyUI/Assets/Shared/builtin-bridges.json")



// MARK: Helper Methods

func exit(_ msg: String) {
	print(msg)
	exit(1)
}

func resolve(_ path: String) -> URL {
	let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	let base = URL(fileURLWithPath: ProcessInfo.processInfo.environment["UPDATE_BRIDGES_BASE"]!, relativeTo: cwd)

	return URL(fileURLWithPath: path, relativeTo: base)
}


// MARK: Main

let modified = (try? outfile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date(timeIntervalSince1970: 0)

guard Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 2 > 1 else {
	print("File too young, won't update!")
	exit(0)
}


let task = URLSession.shared.apiTask(with: request!) { (response: Data?, error) in
//	print("response=\(String(describing: response)), error=\(String(describing: error))")

	if let error = error {
		return exit(error.localizedDescription)
	}

	guard let response = response else {
		return exit("Empty response!")
	}

	do {
		try response.write(to: outfile, options: .atomic)
	}
	catch {
		exit("JSON file could not be written! error=\(error)")
	}

	exit(0)
}
task.resume()


// Wait on explicit exit.
_ = DispatchSemaphore(value: 0).wait(timeout: .distantFuture)
