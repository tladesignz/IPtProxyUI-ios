//
//  update-bridges.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 03.12.19.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import Foundation

// MARK: Config

let moatBaseUrl = URL(string: "https://bridges.torproject.org")

let moatRequest = MoatApi.buildRequest(moatBaseUrl, .builtin)

let outfolder = resolve("IPtProxyUI/Assets/Shared")

let bridgesOutfile = outfolder.appendingPathComponent("builtin-bridges.json")

let dnsSource = URL(string: "https://raw.githubusercontent.com/dnstt-xyz/dnstt_xyz_app/refs/heads/main/assets/dns")!

let dnsCountries = ["ae", "af", "bd", "cn", "co", "global", "id", "ir", "kw", "pk", "qa", "ru", "sy", "tr", "ug", "uz"]

let dnsFileExt = "json"


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

let modified = (try? bridgesOutfile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date(timeIntervalSince1970: 0)

guard Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 2 > 1 else {
	print("File too young, won't update!")
	exit(0)
}

Task {
	print("- Read builtin bridges")

	var lastError: Error?
	let response: Data

	do {
		response = try await URLSession.shared.apiTask(with: moatRequest!)
	}
	catch {
		print(error)
		lastError = error
		response = .init()
	}

	if !response.isEmpty {
		print("- Write builtin bridges")

		do {
			try response.write(to: bridgesOutfile, options: .atomic)
		}
		catch {
			print(error)
			lastError = error
		}
	}

	for country in dnsCountries {
		print("- Read DNS info for: \(country)")

		let data: Data

		do {
			data = try await URLSession.shared.apiTask(with:
					.init(url: dnsSource.appendingPathComponent(country).appendingPathExtension(dnsFileExt)))
		}
		catch {
			print(error)
			lastError = error
			continue
		}

		print("- Write DNS info for: \(country)")

		do {
			try data.write(
				to: outfolder.appendingPathComponent("dns-\(country)")
					.appendingPathExtension(dnsFileExt),
				options: .atomic)
		}
		catch {
			print(error)
			lastError = error
		}
	}

	if let lastError {
		exit(lastError.localizedDescription)
	}
	else {
		exit(0)
	}
}


// Wait on explicit exit.
_ = DispatchSemaphore(value: 0).wait(timeout: .distantFuture)
