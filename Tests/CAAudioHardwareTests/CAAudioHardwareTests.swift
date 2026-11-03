//
// SPDX-FileCopyrightText: 2023 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import XCTest
import CoreAudio
@testable import CAAudioHardware

final class CAAudioHardwareTests: XCTestCase {
	func testObject() {
		XCTAssertThrowsError(try AudioObject.make(kAudioObjectUnknown))
	}

	func testDevices() throws {
		let devices = try AudioDevice.devices
		for device in devices {
			let ownedObjects = try device.ownedObjects
			for ownedObject in ownedObjects {
				let owner = try ownedObject.owner
				XCTAssertEqual(owner, device)
			}

			_ = try device.controlList

			_ = try device.streams(inScope: .output)
			_ = try device.streams(inScope: .input)
		}
	}

	func testStatusFourCC() {
		XCTAssertEqual(kAudioHardwareBadObjectError.fourCC, "!obj")
		XCTAssertEqual(OSStatus(-308).fourCC, "-308")
		XCTAssertEqual(OSStatus(-50).fourCC, "-50")
	}

	/// A create call can report success and still hand back no object; that must be thrown, not wrapped, since an
	/// object of ID 0 traps `AudioObject`'s precondition.
	func testCreatedObject() throws {
		XCTAssertEqual(try createdObject(kAudioHardwareNoError, 42, "create a tap"), 42)
		XCTAssertThrowsError(try createdObject(kAudioHardwareNoError, kAudioObjectUnknown, "create a tap")) { error in
			XCTAssertEqual((error as NSError).code, Int(kAudioHardwareUnspecifiedError))
		}
		XCTAssertThrowsError(try createdObject(-50, 42, "create a tap")) { error in
			XCTAssertEqual((error as NSError).code, -50)
		}
	}

	/// For a few milliseconds after a process tap is destroyed, reads on it can fail with a negative status (-308 on
	/// macOS 27) before they settle on `kAudioHardwareBadObjectError`. Each failure must be thrown.
	func testReadingATapAsItIsDestroyed() throws {
		guard #available(macOS 14.2, *) else {
			throw XCTSkip("Process taps need macOS 14.2")
		}
		for _ in 0..<20 {
			let description = CATapDescription(stereoMixdownOfProcesses: [])
			description.isPrivate = true
			var tapID = AudioObjectID(kAudioObjectUnknown)
			guard AudioHardwareCreateProcessTap(description, &tapID) == kAudioHardwareNoError else {
				throw XCTSkip("A process tap could not be created")
			}
			XCTAssertEqual(AudioHardwareDestroyProcessTap(tapID), kAudioHardwareNoError)
			let deadline = ContinuousClock.now + .seconds(2)
			var settled = false
			while !settled && ContinuousClock.now < deadline {
				do {
					_ = try AudioObject.make(tapID)
				} catch let error as NSError {
					settled = error.code == Int(kAudioHardwareBadObjectError)
				}
			}
			XCTAssertTrue(settled, "Reads on the destroyed tap never failed with kAudioHardwareBadObjectError")
		}
	}

	@available(macOS 14.2, *)
	func testAudioProcess() throws {
		let processes = try AudioProcess.processes
		for process in processes {
			_ = try process.pid
		}
	}

	@available(macOS 14.2, *)
	func testTaps() throws {
		let taps = try AudioTap.taps
		for tap in taps {
			_ = try tap.format
		}
	}

	func testUnfairLockCopying() {
		let lock = UnfairLock()
		let copy = lock
		XCTAssertIdentical(lock.storage, copy.storage)
	}

	func testUnfairLockOwnership() {
		let lock = UnfairLock()
		lock.precondition(.notOwner)
		lock.lock()
		lock.precondition(.owner)
		lock.unlock()
		lock.precondition(.notOwner)
	}
}
