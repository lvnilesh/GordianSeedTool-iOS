//
//  DerivationPath.swift
//  Guardian
//
//  Created by Wolf McNally on 1/22/21.
//

import Foundation
import URKit

// https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-007-hdkey.md#cddl-for-key-path
struct DerivationPath: ExpressibleByArrayLiteral {
    let steps: [DerivationStep]
    let sourceFingerprint: UInt32?
    let depth: UInt8?
    
    var effectiveDepth: UInt8 {
        depth ?? UInt8(steps.count)
    }
    
    init(steps: [DerivationStep], sourceFingerprint: UInt32? = nil, depth: UInt8? = nil) {
        if let sourceFingerprint = sourceFingerprint {
            assert(sourceFingerprint != 0)
        }
        self.steps = steps
        self.sourceFingerprint = sourceFingerprint
        self.depth = depth
    }
    
    init(arrayLiteral elements: DerivationStep...) {
        self.init(steps: elements)
    }
    
    var cbor: CBOR {
        var a: [OrderedMapEntry] = [
            .init(key: 1, value: CBOR.array(steps.flatMap { $0.array } ))
        ]
        
        if let sourceFingerprint = sourceFingerprint {
            a.append(.init(key: 2, value: CBOR.unsignedInt(UInt64(sourceFingerprint))))
        }
        
        if let depth = depth {
            a.append(.init(key: 3, value: CBOR.unsignedInt(UInt64(depth))))
        }
        
        return CBOR.orderedMap(a)
    }
    
    var taggedCBOR: CBOR {
        CBOR.tagged(.init(rawValue: 304), cbor)
    }
    
    init(cbor: CBOR) throws {
        guard case let CBOR.map(pairs) = cbor
        else {
            throw GeneralError("DerivationPath doesn't contain a map.")
        }
        
        guard
            case let CBOR.array(componentsItem) = pairs[1] ?? CBOR.null,
            componentsItem.count.isMultiple(of: 2)
        else {
            throw GeneralError("Invalid DerivationPath components.")
        }
        
        let steps: [DerivationStep] = try stride(from: 0, to: componentsItem.count, by: 2).map { i in
            let childIndexSpec = try ChildIndexSpec.decode(cbor: componentsItem[i])
            guard case let CBOR.boolean(isHardened) = componentsItem[i + 1] else {
                throw GeneralError("Invalid path component.")
            }
            return DerivationStep(childIndexSpec, isHardened: isHardened)
        }
        
        let sourceFingerprint: UInt32?
        if let sourceFingerprintItem = pairs[2] {
            guard
                case let CBOR.unsignedInt(sourceFingerprintValue) = sourceFingerprintItem,
                sourceFingerprintValue != 0,
                sourceFingerprintValue <= UInt32.max
            else {
                throw GeneralError("Invalid source fingerprint.")
            }
            sourceFingerprint = UInt32(sourceFingerprintValue)
        } else {
            sourceFingerprint = nil
        }
        
        let depth: UInt8?
        if let depthItem = pairs[3] {
            guard
                case let CBOR.unsignedInt(depthValue) = depthItem,
                depthValue <= UInt8.max
            else {
                throw GeneralError("Invalid depth.")
            }
            depth = UInt8(depthValue)
        } else {
            depth = nil
        }
        
        self.init(steps: steps, sourceFingerprint: sourceFingerprint, depth: depth)
    }
    
    init(taggedCBOR: CBOR) throws {
        guard case let CBOR.tagged(.init(rawValue: 304), cbor) = taggedCBOR else {
            throw GeneralError("DerivationPath tag (304) not found.")
        }
        try self.init(cbor: cbor)
    }
}

extension DerivationPath: CustomStringConvertible {
    var description: String {
        var result: [String] = []
        
        if let sourceFingerprint = sourceFingerprint {
            result.append(sourceFingerprint.bigEndianData.hex)
        }
        result.append(contentsOf: steps.map({ $0.description }))
        
        return result.joined(separator: "/")
    }
}
