//
//  update-bridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03.12.19.
//  Copyright © 2019 - 2022 Guardian Project. All rights reserved.
//

import Foundation

// MARK: Config

let request = MoatApi.buildRequest(.builtin)

let outfile = resolve("IPtProxyUI/Assets/Shared/obfs4-bridges.plist")



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


let task = URLSession.shared.apiTask(with: request!) { (response: [String: [String]]?, error) in
//	print("response=\(String(describing: response)), error=\(String(describing: error))")

	if let error = error {
		return exit(error.localizedDescription)
	}

	let bridges = response?["obfs4"] ?? []

	let encoder = PropertyListEncoder()
	encoder.outputFormat = .xml

	let output: Data

	do {
		output = try encoder.encode(bridges)
	}
	catch {
		return exit("Plist could not be encoded! error=\(error)")
	}

	do {
		try output.write(to: outfile, options: .atomic)
	}
	catch {
		exit("Plist file could not be written! error=\(error)")
	}

	exit(0)
}
task.resume()


// Wait on explicit exit.
_ = DispatchSemaphore(value: 0).wait(timeout: .distantFuture)
