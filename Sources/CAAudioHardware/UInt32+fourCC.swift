//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation

extension UInt32 {
	/// Returns the value of `self` as a four character code string.
	var fourCC: String {
		String(decoding: [
			UInt8(self >> 24),
			UInt8((self >> 16) & 0xff),
			UInt8((self >> 8) & 0xff),
			UInt8(self & 0xff),
		], as: UTF8.self)
	}
}

extension OSStatus {
	/// Returns `self` as a four character code string when its four bytes are printable ASCII, and as a decimal number
	/// otherwise.
	///
	/// Error statuses may be negative, which `UInt32(_:)` cannot represent.
	var fourCC: String {
		let bits = UInt32(bitPattern: self)
		let bytes = [bits >> 24, bits >> 16, bits >> 8, bits].map { UInt8($0 & 0xff) }
		guard bytes.allSatisfy({ $0 >= 0x20 && $0 < 0x7f }) else {
			return String(self)
		}
		return bits.fourCC
	}
}
