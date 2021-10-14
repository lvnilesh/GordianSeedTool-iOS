//
//  SeedRequest.swift
//  SeedTool
//
//  Created by Wolf McNally on 10/13/21.
//

import SwiftUI
import URKit
import LibWally

struct SeedRequest: View {
    let transactionID: UUID
    let requestBody: SeedRequestBody
    let requestDescription: String?
    @EnvironmentObject private var model: Model
    @State private var seed: ModelSeed?
    @State private var activityParams: ActivityParams?

    init(transactionID: UUID, requestBody: SeedRequestBody, requestDescription: String?) {
        self.transactionID = transactionID
        self.requestBody = requestBody
        self.requestDescription = requestDescription
    }
    
    var responseUR: UR {
        TransactionResponse(id: transactionID, body: .seed(seed!)).ur
    }

    var body: some View {
        Group {
            if let seed = seed {
                VStack(alignment: .leading, spacing: 20) {
                    Info("Another device is requesting a seed on this device:")
                        .font(.title3)
                    ObjectIdentityBlock(model: .constant(seed))
                        .frame(height: 100)
                    Caution("Sending this seed will allow the other device to derive keys and other objects from it. The seed’s name, notes, and other metadata will also be sent.")
                    LockRevealButton {
                        VStack {
                            URDisplay(ur: responseUR, title: "UR for response")
                            ExportDataButton("Share as ur:crypto-response", icon: Image("ur.bar"), isSensitive: true) {
                                activityParams = ActivityParams(responseUR)
                            }
                        }
                    } hidden: {
                        Text("Approve")
                            .foregroundColor(.yellowLightSafe)
                    }
                }
                .background(ActivityView(params: $activityParams))
            } else {
                Failure("Another device requested a seed that is not on this device.")
            }
        }
        .onAppear {
            seed = model.findSeed(with: requestBody.fingerprint)
        }
    }
}

#if DEBUG

import WolfLorem

struct SeedRequest_Previews: PreviewProvider {
    static let model = Lorem.model()
    static let settings = Settings(storage: MockSettingsStorage())
    static let matchingSeed = model.seeds.first!
    static let nonMatchingSeed = Lorem.seed()

    static func requestForSeed(_ seed: ModelSeed) -> TransactionRequest {
        TransactionRequest(body: .seed(.init(fingerprint: seed.fingerprint)))
    }

    static let matchingSeedRequest = requestForSeed(matchingSeed)
    static let nonMatchingSeedRequest = requestForSeed(nonMatchingSeed)
    
    static let selectSeedRequest: TransactionRequest = {
        let useInfo = UseInfo(asset: .btc, network: .testnet)
        let keyType = KeyType.public
        let path = KeyExportDerivationPreset.cosigner.path(useInfo: useInfo)
        return TransactionRequest(body: .key(.init(keyType: keyType, path: path, useInfo: useInfo)))
    }()
        
    static var previews: some View {
        Group {
            ApproveTransaction(isPresented: .constant(true), request: matchingSeedRequest)
                .environmentObject(model)
                .environmentObject(settings)
                .previewDisplayName("Matching Seed Request")

            ApproveTransaction(isPresented: .constant(true), request: nonMatchingSeedRequest)
                .environmentObject(model)
                .environmentObject(settings)
                .previewDisplayName("Non-Matching Seed Request")

            ApproveTransaction(isPresented: .constant(true), request: selectSeedRequest)
                .environmentObject(model)
                .environmentObject(settings)
                .previewDisplayName("Select Seed Request")
        }
        .environmentObject(model)
        .darkMode()
    }
}

#endif