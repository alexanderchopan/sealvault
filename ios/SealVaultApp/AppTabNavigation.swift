// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct AppTabNavigation: View {
    @EnvironmentObject private var model: GlobalModel

    var body: some View {
        AppTabNavigationInner(callbackModel: model.callbackModel)
    }
}

struct AppTabNavigationInner: View {
    enum Tab {
        case dapps
        case webBrowser
    }

    @ObservedObject var callbackModel: CallbackModel
    @State var selection: Tab = .dapps
    @State var dappAllotmentTransferBanner: BannerData?

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                AccountListView()
            }
            .tabItem {
                let menuText = Text("Dapps")

                Label {
                    menuText
                } icon: {
                    Image(systemName: "key")
                }.accessibility(label: menuText)
            }
            .tag(Tab.dapps)

            NavigationView {
                BrowserView()
            }
            .tabItem {
                let menuText = Text("Browser")
                Label {
                    menuText
                } icon: {
                    Image(systemName: "network")
                }.accessibility(label: menuText)
            }
            .tag(Tab.webBrowser)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: callbackModel.dappAllotmentResult) { val in
            guard let res = val else {
                return
            }
            if let errorMessage = res.errorMessage {
                let title = "Failed to transfer to \(res.dappIdentifier)"
                let detail = "Error: \(errorMessage)"
                dappAllotmentTransferBanner = BannerData(title: title, detail: detail, type: .error)
            } else {
                let title = "Successfully transferred to \(res.dappIdentifier)"
                let details = """
                Transferred \(res.amount) \(res.tokenSymbol) on \(res.chainDisplayName) to \(res.dappIdentifier)
                """
                dappAllotmentTransferBanner = BannerData(title: title, detail: details, type: .success)
            }
        }
        .banner(data: $dappAllotmentTransferBanner)
        .edgesIgnoringSafeArea(.bottom)
    }
}

#if DEBUG
struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        let model = GlobalModel.buildForPreview()
        let callbackSuccess = CallbackModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            callbackSuccess.dappAllotmentResult = DappAllotmentTransferResult(
                dappIdentifier: "example.com", amount: "0.1", tokenSymbol: "MATIC",
                chainDisplayName: "Polygon PoS", errorMessage: nil
            )
        }

        let callbackError = CallbackModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            callbackError.dappAllotmentResult = DappAllotmentTransferResult(
                dappIdentifier: "example.com", amount: "0.1", tokenSymbol: "MATIC",
                chainDisplayName: "Polygon PoS", errorMessage: "insufficient funds"
            )
        }

        return Group {
            AppTabNavigationInner(callbackModel: callbackSuccess, selection: .webBrowser).environmentObject(model)
            AppTabNavigationInner(callbackModel: callbackError, selection: .dapps).environmentObject(model)
        }
    }
}
#endif
