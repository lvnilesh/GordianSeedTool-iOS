//
//  URExport.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 2/18/21.
//

import SwiftUI
import URUI
import WolfSwiftUI
import BCFoundation
import SwiftUIFlowLayout

struct URExport: View {
    @Binding var isPresented: Bool
    let isSensitive: Bool
    let ur: UR
    let additionalFlowItems: [AnyView]
    let filename: String
    @State private var activityParams: ActivityParams?

    init(isPresented: Binding<Bool>, isSensitive: Bool, ur: UR, filename: String, items: [AnyView] = []) {
        self._isPresented = isPresented
        self.isSensitive = isSensitive
        self.ur = ur
        self.filename = filename
        self.additionalFlowItems = items
    }
    
    var body: some View {
        var flowItems: [AnyView] = []
        flowItems.append(
            ExportDataButton("Share as ur:\(ur.type)", icon: Image("ur.bar"), isSensitive: isSensitive) {
                activityParams = ActivityParams(ur, export: Export(name: filename))
            }.eraseToAnyView()
        )
        flowItems.append(contentsOf: additionalFlowItems)

        return VStack {
            Text(filename)
                .font(.largeTitle)
                .bold()
                .minimumScaleFactor(0.5)
#if targetEnvironment(macCatalyst)
            URDisplay(ur: ur, title: title)
                .layoutPriority(1)
                .frame(maxHeight: 300)
            FlowLayout(mode: .vstack, items: flowItems, viewMapping: { $0 })
                .fixedVertical()
                .layoutPriority(0.9)
            Spacer()
#else
            URDisplay(ur: ur, filename: filename)
                .layoutPriority(1)
            ScrollView {
                VStack(alignment: .center) {
                    FlowLayout(mode: .scrollable, items: flowItems) { $0 }
                }
            }
            .layoutPriority(0.9)
#endif
        }
        .topBar(trailing: DoneButton($isPresented))
        .padding()
        .background(ActivityView(params: $activityParams))
        .copyConfirmation()
    }
}

#if DEBUG

import WolfLorem

struct URExport_Previews: PreviewProvider {
    static let seed = Lorem.seed()
    
    static var previews: some View {
        try! URExport(
            isPresented: .constant(true),
            isSensitive: true,
            ur: TransactionRequest(
                body: .seed(
                    SeedRequestBody(digest: seed.fingerprint.digest)
                )
            ).ur,
            filename: Lorem.title()
        )
            .darkMode()
    }
}

#endif
