/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MappaMundi
import XCTest

class DemoAppUserState: UserState {

}

func createGraph(for test: XCTestCase) -> ScreenGraph<DemoAppUserState> {
    let map = ScreenGraph(for: test, with: DemoAppUserState.self)

    // Describe the app by creating a map.
    return map
}
