#!/usr/bin/env xcrun --sdk macosx swift

//
//  update-bridges.swift
//  Orbot
//
//  Created by Benjamin Erhart on 03.12.19.
//  Copyright © 2019 - 2021 Guardian Project. All rights reserved.
//

import Foundation

// MARK: Config

let url = URL(string: "https://gitweb.torproject.org/builders/tor-browser-build.git/plain/projects/common/bridges_list.obfs4.txt")!

let outfile = resolve("IPtProxyUI/Assets/obfs4-bridges.plist")



// MARK: Helper Methods

func exit(_ msg: String) {
	print(msg)
	exit(1)
}

func resolve(_ path: String) -> String {
	let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	let script = URL(fileURLWithPath: CommandLine.arguments.first ?? "", relativeTo: cwd).deletingLastPathComponent()

	return URL(fileURLWithPath: path, relativeTo: script).path
}


// MARK: Main

let modified = (try? FileManager.default.attributesOfItem(atPath: outfile)[.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)

guard Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 2 > 1 else {
	print("File too young, won't update!")
	exit(0)
}


let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
//	print("data=\(String(describing: data)), response=\(String(describing: response)), error=\(String(describing: error))")

	if let error = error {
		return exit(error.localizedDescription)
	}

	guard let data = data else {
		return exit("No data!")
	}

	guard let content = String(data: data, encoding: .utf8) else {
		return exit("Data could not be converted to a UTF-8 string!")
	}

	let bridges = NSMutableArray()

	for line in content.split(separator: "\n") {
		bridges.add(String(line.trimmingCharacters(in: .whitespacesAndNewlines)))
	}

	if !bridges.write(toFile: outfile, atomically: true) {
		exit("Couldn't write bridge file!")
	}

	exit(0)
}
task.resume()


// Wait on explicit exit.
_ = DispatchSemaphore(value: 0).wait(timeout: .distantFuture)
