// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

@MainActor
class Address: Identifiable, ObservableObject {
    let core: AppCoreProtocol

    let id: String
    let checksumAddress: String
    let blockchainExplorerLink: URL?
    let chainDisplayName: String
    let chainIcon: UIImage

    @Published var nativeToken: Token
    @Published var fungibleTokens: [Token] = []
    @Published var loading: Bool = false

    required init(_ core: AppCoreProtocol, id: String, checksumAddress: String, blockchainExplorerLink: URL?,
                  chainDisplayName: String, chainIcon: UIImage, nativeToken: Token) {
        self.core = core
        self.id = id
        self.checksumAddress = checksumAddress
        self.blockchainExplorerLink = blockchainExplorerLink
        self.chainDisplayName = chainDisplayName
        self.chainIcon = chainIcon
        self.nativeToken = nativeToken
    }

    static func fromCore(_ core: AppCoreProtocol, _ address: CoreAddress) -> Self {
        let chainIcon = UIImage(data: Data(address.chainIcon)) ?? UIImage(systemName: "diamond")!
        let url = URL(string: address.blockchainExplorerLink)
        let nativeToken = Token.fromCore(address.nativeToken)
        return Self(
            core, id: address.id, checksumAddress: address.checksumAddress, blockchainExplorerLink: url,
            chainDisplayName: address.chainDisplayName, chainIcon: chainIcon, nativeToken: nativeToken
        )
    }

    private func refreshNativeToken() async {
        let coreToken: CoreToken? = await dispatchBackground(.userInteractive) {
            do {
                return try self.core.nativeTokenForAddress(addressId: self.id)
            } catch {
                print("Failed to fetch native token for address id \(self.id)")
                return nil
            }
        }
        if let token = coreToken {
            withAnimation {
                self.nativeToken = Token.fromCore(token)
            }
        }
    }

    private func refreshFungibleTokens() async {
        let tokens: [CoreToken] = await dispatchBackground(.userInteractive) {
            do {
                return try self.core.fungibleTokensForAddress(addressId: self.id)
            } catch {
                print("Failed to fetch fungible tokens for address id \(self.id)")
                return []
            }
        }
        withAnimation {
            // Not passing the function as that'd lose MainActor context.
            self.fungibleTokens = tokens.map { Token.fromCore($0) }
        }
    }

    func refreshTokens() async {
        self.loading = true
        defer { self.loading = false }
        async let native: () = self.refreshNativeToken()
        async let fungible: () = self.refreshFungibleTokens()
        // Execute concurrently
        _ = await [native, fungible]
    }

}

// MARK: - Hashable

extension Address: Equatable, Hashable {

    static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

// MARK: - display

extension Address {
    var addressDisplay: String {
        "\(checksumAddress.prefix(5))...\(checksumAddress.suffix(3))"
    }

    var image: Image {
        Image(uiImage: chainIcon)
    }
}

// MARK: - preview

#if DEBUG
extension Address {
    static func ethereumWallet() -> Self {
        Self.ethereum(checksumAddress: "0xb3f5354C4c4Ca1E9314302CcFcaDc9de5da53AdA")
    }

    static func polygonWallet() -> Self {
        Self.polygon(checksumAddress: "0xb3f5354C4c4Ca1E9314302CcFcaDc9de5da53AdA")
    }

    static func ethereumDapp() -> Self {
        Self.ethereum(checksumAddress: "0x696e931B0d3112FebAA9401A89C2658f96C725f2")
    }

    static func polygonDapp() -> Self {
        Self.polygon(checksumAddress: "0x696e931B0d3112FebAA9401A89C2658f96C725f2")
    }

    static func ethereum(checksumAddress: String) -> Self {
        let nativeToken = Token.eth()
        let icon = UIImage(named: "eth")!
        let explorer = URL(string: "https://etherscan.io/address/\(checksumAddress)")!
        let id = "eth-\(checksumAddress)"
        return Self(
            PreviewAppCore(), id: id, checksumAddress: "0xb3f5354C4c4Ca1E9314302CcFcaDc9de5da53AdA",
            blockchainExplorerLink: explorer, chainDisplayName: "Ethereum", chainIcon: icon,
            nativeToken: nativeToken
        )
    }

    static func polygon(checksumAddress: String) -> Self {
        let nativeToken = Token.matic()
        let icon = UIImage(named: "matic")!
        let explorer = URL(string: "https://polygonscan.com/address/\(checksumAddress)")!
        let id = "polygon-pos-\(checksumAddress)"
        return Self(
            PreviewAppCore(), id: id, checksumAddress: checksumAddress, blockchainExplorerLink: explorer,
            chainDisplayName: "Polygon PoS", chainIcon: icon, nativeToken: nativeToken
        )
    }
}
#endif
