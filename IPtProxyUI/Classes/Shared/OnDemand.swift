//
//  OnDemand.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 2023-03-10.
//  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
//

import CommonCrypto

open class OnDemand {

	public struct Configuration {
		public let accessKey: String
		public let secretKey: String
		public let region: String
		public let groupName: String

		public init(accessKey: String, secretKey: String, region: String, groupName: String) {
			self.accessKey = accessKey
			self.secretKey = secretKey
			self.region = region
			self.groupName = groupName
		}
	}

	public static let shared = OnDemand()


	private init() {}

	public weak var delegate: BridgesConfDelegate?


	open func fetch(_ conf: Configuration) async throws -> String? {
		let conf = AwsConfiguration(conf.accessKey, conf.secretKey, conf.region, "gamelift", conf.groupName)

		guard let url = conf.url else {
			throw ApiError.noRequestPossible
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
		request.setValue(url.host, forHTTPHeaderField: "Host")
		request.setValue("GameLift.ClaimGameServer", forHTTPHeaderField: "X-Amz-Target")
		request.setValue(conf.isoDate, forHTTPHeaderField: "X-Amz-Date")

		request.httpBody = try? MoatApi.encoder.encode(ClaimGameServerRequest(groupName: conf.groupName))

		guard let authorization = AwsAuthorization(request, conf) else {
			throw ApiError.noRequestPossible
		}

		request.setValue(authorization.description, forHTTPHeaderField: "Authorization")

		delegate?.auth(request: &request)

		let response: ClaimGameServerResponse

		do {
			response = try await URLSession.shared.apiTask(with: request)
		}
		catch {
			switch error as? ApiError {
			case .no200Status(_, let body):
				if let body = body,
					let awsError = (try? MoatApi.decoder.decode(AwsError.self, from: body))
				{
					throw awsError
				}

			default:
				break
			}

			throw error
		}

		var bridge = response.gameServer?.payload?.bridge

		if bridge?.hasPrefix("Bridge ") ?? false {
			bridge = String(bridge!.dropFirst(7))
		}

		return bridge
	}
}

public struct ClaimGameServerRequest: Codable {

	public var groupName: String

	enum CodingKeys: String, CodingKey {
		case groupName = "GameServerGroupName"
	}
}

public struct AwsError: LocalizedError, Codable {

	public var type: String

	public var message: String

	enum CodingKeys: String, CodingKey {
		case type = "__type"

		case message = "message"
	}

	public var errorDescription: String? {
		"\(type): \(message)"
	}
}

public struct ClaimGameServerResponse: Codable {

	public var gameServer: GameServer?

	enum CodingKeys: String, CodingKey {
		case gameServer = "GameServer"
	}
}

public struct GameServer: Codable, CustomStringConvertible {

	public var claimStatus: String?

	public var connectionInfo: String?

	public var data: String?

	public var groupArn: String?

	public var groupName: String?

	public var id: String?

	public var instanceId: String?

	public var lastClaimTime: Double?

	public var lastHealthCheckTime: Double?

	public var registrationTime: Double?

	public var utilizationStatus: String?


	var payload: Payload? {
		guard let data = data?.data(using: .utf8) else {
			return nil
		}

		return try? MoatApi.decoder.decode(Payload.self, from: data)
	}


	enum CodingKeys: String, CodingKey {
		case claimStatus = "ClaimStatus"
		case connectionInfo = "ConnectionInfo"
		case data = "GameServerData"
		case groupArn = "GameServerGroupArn"
		case groupName = "GameServerGroupName"
		case id = "GameServerId"
		case instanceId = "InstanceId"
		case lastClaimTime = "LastClaimTime"
		case lastHealthCheckTime = "LastHealthCheckTime"
		case registrationTime = "RegistrationTime"
		case utilizationStatus = "UtilizationStatus"
	}

	public var description: String {
		"[\(String(describing: type(of: self)))] claimStatus=\(claimStatus ?? "(nil)"), "
		+ "connectionInfo=\(connectionInfo ?? "(nil)"), data=\(data ?? "(nil)"), groupArn=\(groupArn ?? "(nil)"), "
		+ "groupName=\(groupName ?? "(nil)"), id=\(id ?? "(nil)"), instanceId=\(instanceId ?? "(nil)"), "
		+ "lastClaimTime=\(lastClaimTime ?? .infinity), lastHealthCheckTime=\(lastHealthCheckTime ?? .infinity), "
		+ "registrationTime=\(registrationTime ?? .infinity), utilizationStatus=\(utilizationStatus ?? "(nil)")"
	}
}

public struct Payload: Codable, CustomStringConvertible {

	public var bridge: String?

	enum CodingKeys: String, CodingKey {
		case bridge = "obfs4_bridgeline"
	}

	public var description: String {
		"[\(String(describing: type(of: self)))] bridge=\(bridge ?? "(nil)")"
	}
}

public struct AwsConfiguration {

	public static let iso8601DateFormat = "yyyyMMdd'T'HHmmss'Z'"
	public static let shortDateFormat = "yyyyMMdd"


	public let accessKey: String
	public let secretKey: String
	public let region: String
	public let service: String
	public let groupName: String
	public let date = Date()


	public let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.timeZone = TimeZone(abbreviation: "GMT")
		df.locale = Locale(identifier: "en_US_POSIX")

		return df
	}()

	public var isoDate: String {
		dateFormatter.dateFormat = Self.iso8601DateFormat

		return dateFormatter.string(from: date)
	}

	public var shortDate: String {
		dateFormatter.dateFormat = Self.shortDateFormat

		return dateFormatter.string(from: date)
	}

	public var url: URL? {
		URL(string: String(format: "https://%@.%@.amazonaws.com/", service, region))
	}


	public init(_ accessKey: String, _ secretKey: String, _ region: String, _ service: String, _ groupName: String) {
		self.accessKey = accessKey
		self.secretKey = secretKey
		self.region = region.lowercased()
		self.service = service.lowercased()
		self.groupName = groupName
	}
}

public struct AwsCanonicalRequest: CustomStringConvertible, CustomDebugStringConvertible {

	public let method: String
	public let canonicalUri: String
	public let canonicalQuery: String
	public let headers: [String]
	public let signedHeaders: String
	public let hashedPayload: String


	public var description: String {
		var content = [method, canonicalUri, canonicalQuery]
		content.append(contentsOf: headers)
		content.append("")
		content.append(signedHeaders)
		content.append(hashedPayload)

		return content.joined(separator: "\n")
	}

	public var debugDescription: String {
		"[\(String(describing: type(of: self))) method=\(method), canonicalUri=\(canonicalUri), "
		+ "canonicalQuery=\(canonicalQuery), headers=\(headers), signedHeaders=\(signedHeaders), "
		+ "hashedPayload=\(hashedPayload)]"
	}


	public init?(_ request: URLRequest) {
		guard request.allHTTPHeaderFields?.contains(where: { $0.key.lowercased() == "host" }) ?? false,
			  let payloadHash = AwsAuthorization.hash(request.httpBody ?? "".data(using: .utf8))
		else {
			return nil
		}

		method = request.httpMethod ?? "GET"

		if let path = request.url?.path, !path.isEmpty {
			canonicalUri = path
		}
		else {
			canonicalUri = "/"
		}

		canonicalQuery = request.url?.query ?? ""

		var headers = [String]()
		var signedHeaders = [String]()

		for header in request.allHTTPHeaderFields ?? [:] {
			let key = header.key.lowercased()

			if key == "host" || key.hasPrefix("x-amz-") {
				headers.append("\(key):\(header.value.trimmingCharacters(in: .whitespacesAndNewlines))")
				signedHeaders.append(key)
			}
		}

		self.headers = headers.sorted()
		self.signedHeaders = signedHeaders.sorted().joined(separator: ";")

		hashedPayload = payloadHash
	}
}

public struct AwsStringToSign: CustomStringConvertible, CustomDebugStringConvertible {

	public let canonicalRequest: AwsCanonicalRequest

	public let algorithm = "AWS4-HMAC-SHA256"
	public let requestDateTime: String
	public let credentialScope: String
	public let hashedCanonicalRequest: String


	public var description: String {
		[algorithm, requestDateTime, credentialScope, hashedCanonicalRequest].joined(separator: "\n")
	}

	public var debugDescription: String {
		"[\(String(describing: type(of: self))) algorithm=\(algorithm), requestDateTime=\(requestDateTime), "
		+ "credentialScope=\(credentialScope), hashedCanonicalRequest=\(hashedCanonicalRequest), "
		+ "canonicalRequest=\(canonicalRequest)]"
	}


	public init?(_ request: URLRequest, _ conf: AwsConfiguration) {
		guard let canonicalRequest = AwsCanonicalRequest(request),
			  let canonicalRequestHash = AwsAuthorization.hash(canonicalRequest.description.data(using: .utf8))
		else {
			return nil
		}

		requestDateTime = conf.isoDate

		credentialScope = "\(conf.shortDate)/\(conf.region)/\(conf.service)/\(AwsAuthorization.terminator)"

		self.canonicalRequest = canonicalRequest

		hashedCanonicalRequest = canonicalRequestHash
	}
}

public struct AwsAuthorization: CustomStringConvertible, CustomDebugStringConvertible {

	public static let terminator = "aws4_request"


	public let algorithm: String
	public let credential: String
	public let signedHeaders: String
	public let signature: String


	private let stringToSign: AwsStringToSign


	public var description: String {
		"\(algorithm) Credential=\(credential), SignedHeaders=\(signedHeaders), Signature=\(signature)"
	}

	public var debugDescription: String {
		"[\(String(describing: type(of: self))) algorithm=\(algorithm), credential=\(credential), "
		+ "signedHeaders=\(signedHeaders), signature=\(signature), stringToSign=\(stringToSign.debugDescription)]"
	}


	public init?(_ request: URLRequest, _ conf: AwsConfiguration) {
		guard let stringToSign = AwsStringToSign(request, conf) else {
			return nil
		}

		self.stringToSign = stringToSign

		algorithm = stringToSign.algorithm

		credential = "\(conf.accessKey)/\(stringToSign.credentialScope)"

		signedHeaders = stringToSign.canonicalRequest.signedHeaders

		guard let kDate = Self.sha256Mac("AWS4\(conf.secretKey)", conf.shortDate),
			  let kRegion = Self.sha256Mac(kDate, conf.region),
			  let kService = Self.sha256Mac(kRegion, conf.service),
			  let kSigning = Self.sha256Mac(kService, Self.terminator),
			  let signature = Self.sha256Mac(kSigning, stringToSign.description)
		else {
			return nil
		}

		self.signature = Self.hexEncode(signature)
	}


	public static func sha256Mac(_ key: Data, _ data: Data) -> Data {
		var context = CCHmacContext()

		key.withUnsafeBytes { pointer in
			CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), pointer.baseAddress, key.count)
		}

		data.withUnsafeBytes { pointer in
			CCHmacUpdate(&context, pointer.baseAddress, data.count)
		}

		var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

		digest.withUnsafeMutableBytes { pointer in
			CCHmacFinal(&context, pointer.baseAddress)
		}

		return digest
	}

	public static func sha256Mac(_ key: Data, _ data: String) -> Data? {
		guard let data = data.data(using: .utf8) else {
			return nil
		}

		return sha256Mac(key, data)
	}

	public static func sha256Mac(_ key: String, _ data: String) -> Data? {
		guard let key = key.data(using: .utf8) else {
			return nil
		}

		return sha256Mac(key, data)
	}

	public static func hash(_ data: Data?) -> String? {
		guard let data = data,
			  data.count <= UInt32.max
		else {
			return nil
		}

		var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

		data.withUnsafeBytes { inPointer in
			digest.withUnsafeMutableBytes { outPointer in
				// Keep this around, otherwise a stupid wrong warning will appear about
				// `data` or `digest` being unused.
				let outPointer = outPointer

				CC_SHA256(inPointer.baseAddress, UInt32(data.count), outPointer.baseAddress)
			}
		}

		return hexEncode(digest)
	}

	public static func hexEncode(_ data: Data) -> String {
		data.map({ String(format: "%02hhx", $0) }).joined()
	}
}
