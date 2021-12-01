//
//  AssetExtensions.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 1/22/21.
//

import SwiftUI
import URKit
import BCFoundation

extension Asset {
    var cbor: CBOR {
        CBOR.unsignedInt(UInt64(rawValue))
    }
    
    init(cbor: CBOR) throws {
        guard
            case let CBOR.unsignedInt(r) = cbor,
            let a = Asset(rawValue: UInt32(r)) else {
            throw GeneralError("Invalid Asset.")
        }
        self = a
    }

    var image: AnyView {
        switch self {
        case .btc:
            return Symbol.assetBTC
        case .eth:
            return Symbol.assetETH
        }
    }

    var icon: AnyView {
        image
            .accessibility(label: Text(self.name))
            .eraseToAnyView()
    }
    
    var subtype: ModelSubtype {
        ModelSubtype(id: id, icon: icon)
    }
    
    var derivations: [KeyExportDerivationPreset] {
        switch self {
        case .btc:
            return [.master, .cosigner, .segwit, .custom]
        case .eth:
            return [.master, .ethereum, .custom]
        }
    }
    
    var defaultDerivation: KeyExportDerivationPreset {
        switch self {
        case .btc:
            return .master
        case .eth:
            return .ethereum
        }
    }
}

extension Asset: Segment {
    var label: AnyView {
        makeSegmentLabel(title: name, icon: icon)
    }
}
