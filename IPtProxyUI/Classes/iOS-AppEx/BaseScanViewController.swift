//
//  BaseScanViewController.swift
//  IPtProxyUI-iOS
//
//  Created by Benjamin Erhart on 16.01.23.
//

import UIKit
import AVFoundation


@objc
public protocol ScanQrDelegate: AnyObject {

	@objc
	optional func scanned(raw: String?)

	@objc
	optional func scanned(bridges: [String])

	@objc
	optional func scanned(error: Error)
}


public enum ScanError: Error, LocalizedError {

	case notSupported
	case notBridges

	public var errorDescription: String? {
		switch self {
		case .notSupported:
			return NSLocalizedString(
				"Camera access was not granted or QR Code scanning is not supported by your device.",
				bundle: .iPtProxyUI, comment: "")

		case .notBridges:
			return String(format: NSLocalizedString(
				"QR Code could not be decoded! Are you sure you scanned a QR code from %@?",
                bundle: .iPtProxyUI, comment: ""), Constants.bridgesUrl.absoluteString)
		}
	}
}


open class BaseScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

	open var captureSession: AVCaptureSession?
	open var videoPreviewLayer: AVCaptureVideoPreviewLayer?

	open weak var delegate: ScanQrDelegate?


	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		stopReading()
	}


	// MARK: Public Methods

	open func startReading() throws
	{
		guard let captureDevice = AVCaptureDevice.default(for: .video) else {
			throw ScanError.notSupported
		}

		do {
			let input = try AVCaptureDeviceInput(device: captureDevice)

			captureSession = AVCaptureSession()

			captureSession?.addInput(input)

			let captureMetadataOutput = AVCaptureMetadataOutput()
			captureSession?.addOutput(captureMetadataOutput)
			captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
			captureMetadataOutput.metadataObjectTypes = [.qr]

			videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
			videoPreviewLayer?.videoGravity = .resizeAspectFill

			Task {
				captureSession?.startRunning()
			}
		}
		catch {
			throw ScanError.notSupported
		}
	}

	open func stopReading() {
		captureSession?.stopRunning()
		captureSession = nil

		videoPreviewLayer?.removeFromSuperlayer()
		videoPreviewLayer = nil
	}

	/**
	 Extract a list of bridge lines from a raw JSON string, which might be buggy.

	 They really had to use JSON for content encoding but with illegal single quotes instead
	 of double quotes as per JSON standard.
	 */
	open class func extractBridges(from raw: String?) -> [String]? {
		if let data = raw?.replacingOccurrences(of: "'", with: "\"").data(using: .utf8),
		   let bridges = try? JSONSerialization.jsonObject(with: data, options: []) as? [String],
		   !bridges.isEmpty
		{
			return bridges
		}
		else {
			return nil
		}
	}

	open class func extractBridges(from image: UIImage?) -> [String]? {
		guard let ciImage = image?.ciImage ?? (image?.cgImage != nil ? CIImage(cgImage: image!.cgImage!) : nil),
			  let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
		else {
			return nil
		}

		let features = detector.features(in: ciImage)

		var raw = ""

		for feature in features as? [CIQRCodeFeature] ?? [] {
			raw += feature.messageString ?? ""
		}

		return Self.extractBridges(from: raw)
	}


	// MARK: AVCaptureMetadataOutputObjectsDelegate

	/**
	 BUGFIX: Signature of method changed in Swift 4, without notifications.
	 No migration assistance either.

	 See https://stackoverflow.com/questions/46639519/avcapturemetadataoutputobjectsdelegate-not-called-in-swift-4-for-qr-scanner
	 */
	public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput
							   metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)
	{
		if let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
		   metadata.type == .qr
		{
			delegate?.scanned?(raw: metadata.stringValue)

			if let bridges = Self.extractBridges(from: metadata.stringValue) {
				delegate?.scanned?(bridges: bridges)
			}
			else {
				delegate?.scanned?(error: ScanError.notBridges)
			}
		}
	}
}
