import XCTest
import CoreAudio
@testable import CAAudioHardware

final class CAAudioHardwareTests: XCTestCase {
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

	func testNegativeStatusFourCC() {
		XCTAssertEqual(OSStatus(-308).fourCC, UInt32(bitPattern: -308).fourCC)
		XCTAssertEqual(kAudioHardwareBadObjectError.fourCC, "!obj")
	}

	/// For a few milliseconds after a process tap is destroyed, reads on it can fail with a negative status (-308 on
	/// macOS 27) before they settle on `kAudioHardwareBadObjectError`. Each failure must be thrown.
	@available(macOS 14.2, *)
	func testReadingATapAsItIsDestroyed() throws {
		for _ in 0..<20 {
			let description = CATapDescription(stereoMixdownOfProcesses: [])
			description.isPrivate = true
			var tapID = AudioObjectID(kAudioObjectUnknown)
			guard AudioHardwareCreateProcessTap(description, &tapID) == kAudioHardwareNoError else {
				throw XCTSkip("A process tap could not be created")
			}
			XCTAssertEqual(AudioHardwareDestroyProcessTap(tapID), kAudioHardwareNoError)
			let start = Date()
			while Date().timeIntervalSince(start) < 0.02 {
				_ = try? AudioObject.make(tapID)
			}
			XCTAssertThrowsError(try AudioObject.make(tapID))
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
