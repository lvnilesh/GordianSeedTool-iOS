//
//  KeyExportDerivationPreset.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 1/26/21.
//

import SwiftUI
import LibWally

enum KeyExportDerivationPreset: Identifiable, CaseIterable, Equatable {
    case master
    case cosigner
    case segwit
    case custom

    var name: String {
        switch self {
        case .master:
            return "Master Key"
        case .cosigner:
            return "Cosigner"
        case .segwit:
            return "Segwit"
        case .custom:
            return "Custom"
        }
    }
    
    var id: String {
        "derivation-\(description)"
    }
    
    func base58Prefix(network: Network, keyType: KeyType) -> UInt32? {
        switch self {
        case .master:
            return nil
        case .cosigner:
            return nil
        case .segwit:
            // https://github.com/satoshilabs/slips/blob/master/slip-0132.md
            switch network {
            case .mainnet:
                switch keyType {
                case .private:
                    return 0x04b2430c // zprv
                case .public:
                    return 0x04b24746 // zpub
                }
            case .testnet:
                switch keyType {
                case .private:
                    return 0x045f18bc // vprv
                case .public:
                    return 0x045f1cf6 // vpub
                }
            @unknown default:
                fatalError()
            }
        case .custom:
            return nil
        }
    }
    
    init?(origin: DerivationPath, useInfo: UseInfo) {
        guard let derivation = Self.allCases.first(where: {
            let path = $0.path(useInfo: useInfo, sourceFingerprint: origin.sourceFingerprint, depth: origin.depth)
            return path == origin
        }) else {
            return nil
        }
        self = derivation
    }
    
    static func preset(for path: DerivationPath) -> KeyExportDerivationPreset {
        if path == [] {
            return .master
        }
        else if path == [
            .init(48, isHardened: true),
            .init(0, isHardened: true),
            .init(0, isHardened: true),
            .init(2, isHardened: true)
        ] || path == [
            .init(48, isHardened: true),
            .init(1, isHardened: true),
            .init(0, isHardened: true),
            .init(2, isHardened: true)
        ] {
            return .cosigner
        }
        else if path == [
            .init(84, isHardened: true),
            .init(0, isHardened: true),
            .init(0, isHardened: true),
        ] || path == [
            .init(84, isHardened: true),
            .init(1, isHardened: true),
            .init(0, isHardened: true),
        ] {
            return .segwit
        }
        else {
            return .custom
        }
    }
    
    func path(useInfo: UseInfo, sourceFingerprint: UInt32? = nil, depth: UInt8? = nil) -> DerivationPath {
        var path: DerivationPath
        switch self {
        case .master:
            path = []
        case .cosigner:
            path = [
                .init(48, isHardened: true),
                .init(useInfo.coinType, isHardened: true),
                .init(0, isHardened: true),
                .init(2, isHardened: true)
            ]
        case .segwit:
            path = [
                .init(84, isHardened: true),
                .init(useInfo.coinType, isHardened: true),
                .init(0, isHardened: true),
            ]
        case .custom:
            path = []
        }
        
        path.sourceFingerprint = sourceFingerprint
        path.depth = depth
        return path
    }
}

extension KeyExportDerivationPreset: CustomStringConvertible {
    var description: String {
        switch self {
        case .master:
            return "master"
        case .cosigner:
            return "gordian"
        case .segwit:
            return "segwit"
        case .custom:
            return "custom"
        }
    }
}

struct KeyExportDerivationPresetSegment: Segment {
    let preset: KeyExportDerivationPreset
    let useInfo: UseInfo
    
    var id: String {
        preset.id
    }
    
    var pathString: String? {
        let path = preset.path(useInfo: useInfo)
        guard !path.isEmpty else {
            return nil
        }
        return String(describing: path)
    }
    
    var label: AnyView {
        switch preset {
        case .master:
            return segmentLabel(image: "key.fill.circle", caption: pathString)
        case .cosigner:
            return segmentLabel(image: "bc-logo", caption: pathString)
        case .segwit:
            return segmentLabel(image: "segwit", caption: pathString)
        case .custom:
            return segmentLabel(caption: "Edit the field below.")
        }
    }
    
    private func segmentLabel(image: String? = nil, caption: String? = nil) -> AnyView {
        return VStack(alignment: .leading) {
            HStack {
                if let image = image {
                    Image(image)
                }
                Text(preset.name)
            }
            .font(.headline)
            if let caption = caption {
                Text(caption)
                    .font(.footnote)
            }
        }
        .eraseToAnyView()
    }
}