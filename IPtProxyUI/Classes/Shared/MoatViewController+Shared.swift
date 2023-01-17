//
//  MoatViewController+Shared.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 01.09.22.
//

import Foundation

extension MoatViewController {

	public class func fetchCaptcha(_ delegate: BridgesConfDelegate?,
								   completion: @escaping ((_ challenge: String?, _ captcha: Data?, _ error: Error?) -> Void))
	{
		guard var request = MoatApi.buildRequest(.fetch) else {
			return completion(nil, nil, nil)
		}

		delegate?.auth(request: &request)

		// Contact Moat service.
		let task = URLSession.shared.apiTask(with: request) { (response: MoatApi.Wrapper<MoatApi.FetchResponse>?, error) in
			if let error = error {
				return completion(nil, nil, error)
			}

			guard let challenge = response?.data.first?.challenge,
				  let captcha = response?.data.first?.captcha
			else {
				return completion(nil, nil, ApiError.notUnderstandable)
			}

			completion(challenge, captcha, nil)
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			task.resume()
		}
	}

	public class func requestBridges(_ delegate: BridgesConfDelegate?,
									 _ challenge: String?,
									 _ solution: String?,
									 completion: @escaping ((_ bridges: [String]?, _ error: Error?) -> Void))
	{
		guard var request = MoatApi.buildRequest(.check(challenge: challenge ?? "", solution: solution ?? ""))
		else {
			return completion(nil, nil)
		}

		delegate?.auth(request: &request)

		URLSession.shared.apiTask(with: request) { (response: MoatApi.Wrapper<MoatApi.CheckResponse>?, error) in
			if let error = error {
				return completion(nil, error)
			}

			guard let bridges = response?.data.first?.bridges, !bridges.isEmpty
			else {
				return completion(nil, error)
			}

			completion(bridges, nil)
		}.resume()
	}
}
