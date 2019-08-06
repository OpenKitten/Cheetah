//
//  InternalHelpers.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 18/02/2017.
//
//

extension UInt32 {
    /// Internal function to help with Unicode
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
        ]
    }
}

extension UInt16 {
    /// Internal function to help with Unicode
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF)
        ]
    }
}
