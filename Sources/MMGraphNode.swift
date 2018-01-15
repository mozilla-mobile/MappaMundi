/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GameplayKit

/// The super class of screen action and screen state nodes.
/// By design, the user should not be able to construct these nodes.
public class MMGraphNode<T: MMUserState> {
    let name: String
    let gkNode: GKGraphNode

    weak var map: MMScreenGraph<T>?

    let file: String
    let line: UInt

    init(_ map: MMScreenGraph<T>, name: String, file: String, line: UInt) {
        self.map = map
        self.name = name
        self.file = file
        self.line = line

        self.gkNode = GKGraphNode()
    }
}
