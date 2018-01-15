/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

// Gestures which affect user state are called ScreenActions.
// These cannot be constructed or manipulated directly, but can be added to the graph using `screenStateNode.*(forAction:)` methods.
public class MMScreenActionNode<T: MMUserState>: MMGraphNode<T> {
    public typealias UserStateChange = (T) -> ()
    let onEnterStateRecorder: UserStateChange?

    let nextNodeName: String?

    init(_ map: MMScreenGraph<T>, name: String, then nextNodeName: String?, file: String, line: UInt, recorder: UserStateChange?) {
        self.onEnterStateRecorder = recorder
        self.nextNodeName = nextNodeName
        super.init(map, name: name, file: file, line: line)
    }
}
