// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

struct Config {
    static let dbFileDir = "database"
    static let dbFileName = "sealvault-db.sqlite3"
    static let tabBarColor = Color(UIColor.systemGray5)
    static let topDappsLimit = 6
    static let searchProvider = URL(string: "https://search.brave.com/search")!
    static let searchQueryParamName = "q"
}
