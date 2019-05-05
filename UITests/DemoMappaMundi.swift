/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MappaMundi
import XCTest

class Actions {
    static let addItem = "addItem"
    static let editItemMode = "editItems"
    static let deleteItem = "deleteItem"
    static let deleteAllItems = "deleteAllItems"
    static let initialWithExactlyOne = "initialWithExactlyOne"
    static let postAddItem = "postAddItem"
    static let action1 = "item_action_1"
    static let action2 = "item_action_2"
    static let action3 = "item_action_3"
    static let action4 = "item_action_4"
    static let action5 = "item_action_5"
    static let action6 = "item_action_6"
    static let action7 = "item_action_7"
    static let action8 = "item_action_8"
    static let action9 = "item_action_9"
    static let action10 = "item_action_10"
    static let action11 = "item_action_11"
    static let action12 = "item_action_12"
}

class Screens {
    static let itemList = "ItemList"
    static let itemListEditing = "EditingItemList"
    static let itemDetail = "ItemDetail"
    static let foo1 = "foo_1"
    static let foo2 = "foo_2"
    static let foo3 = "foo_3"
    static let foo4 = "foo_4"
    static let foo5 = "foo_5"
}
@objcMembers
class DemoAppUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = Screens.itemList
    }
    var numItems = 0
}

func createGraph(with app: XCUIApplication, for test: XCTestCase) -> MMScreenGraph<DemoAppUserState> {
    let map = MMScreenGraph(for: test, with: DemoAppUserState.self)

    // Let's add our first screen state.
    // This is a node in the graph; we get to define edges out to other nodes,
    // by defining gestures (tap, swipe, press etc) to other screens.
    map.addScreenState(Screens.itemList) { screenState in
        let table = app.tables.element(boundBy: 0)

        // When we first enter the screen, we'll record the number of items in the list.
        screenState.onEnter { userState in
            userState.numItems = Int(table.cells.count)
        }

        // Optionally, we can wait for an element to exist.
        // screenState.onEnterWaitFor(element: table)

        // 1. an action to add an item to the list.
        screenState.tap(app.buttons["addButton"], forAction: Actions.addItem, transitionTo: Actions.postAddItem) { userState in
            userState.numItems += 1
        }

        // 2. an action to put the list into edit mode.
        // We've encoded edit mode as a separate screenState.
        screenState.tap(app.buttons["editButton"], forAction: Actions.editItemMode, transitionTo: Screens.itemListEditing)

        // 3. navigate away from this screen by tapping on the first item in the list.
        //    Note, we can only do this if numItems > 0.
        screenState.tap(table.cells.element(boundBy: 0), to: Screens.itemDetail, if: "numItems > 0")
    }

    // We're able to encapsulate going back when we declare the next couple of screenStates.
    // Having a `backAction` means we can get to it from multiple places, and still navigate back.
    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    // The detail screen only has a text item on it,
    // and a back button.
    map.addScreenState(Screens.itemDetail) { screenState in
        screenState.backAction = navigationControllerBackAction
        
        screenState.gesture(forAction: Actions.action1,transitionTo: Screens.foo5) { _ in
        }
        screenState.gesture(forAction: Actions.action2,transitionTo: Screens.foo1) { _ in
        }
        screenState.gesture(forAction: Actions.action3,transitionTo: Screens.foo2) { _ in
        }
        screenState.gesture(forAction: Actions.action4,transitionTo: Screens.foo2) { _ in
        }
        screenState.gesture(forAction: Actions.action5,transitionTo: Screens.foo4) { _ in
        }
    }
    
    map.addScreenState(Screens.foo1) { screenState in
        screenState.gesture(forAction: Actions.action6,transitionTo: Screens.foo5) { _ in
        }
        screenState.gesture(forAction: Actions.action7,transitionTo: Screens.foo3) { _ in
        }
    }
    map.addScreenState(Screens.foo2) { screenState in
        screenState.gesture(forAction: Actions.action8,transitionTo: Screens.foo5) { _ in
        }
        screenState.gesture(forAction: Actions.action9,transitionTo: Screens.foo4) { _ in
        }
    }
    map.addScreenState(Screens.foo3) { screenState in
        screenState.gesture(forAction: Actions.action10,transitionTo: Screens.foo5) { _ in
        }
    }
   
    map.addScreenState(Screens.foo4) { screenState in
        screenState.gesture(forAction: Actions.action11,transitionTo: Screens.foo5) { _ in
        }
    }
    
    map.addScreenState(Screens.foo5) { screenState in
    }
    
    // The edit screen has a delete action. We can also
    map.addScreenState(Screens.itemListEditing) { screenState in
        let table = app.tables.element(boundBy: 0)

        func deleteFirst(_ userState: DemoAppUserState) {
            table.cells.element(boundBy: 0).buttons.element(boundBy: 0).tap()
            table.buttons["Delete"].tap()
            userState.numItems -= 1
        }

        screenState.gesture(forAction: Actions.deleteItem) { userState in
            deleteFirst(userState)
        }

        // Just for ease of use, we include a delete all items gesture.
        screenState.gesture(forAction: Actions.deleteAllItems) { userState in
            for _ in 0 ..< userState.numItems {
                deleteFirst(userState)
            }
        }

        screenState.backAction = navigationControllerBackAction
    }

    map.addNavigatorAction(Actions.initialWithExactlyOne) { navigator in
        navigator.performAction(Actions.deleteAllItems)
        navigator.performAction(Actions.addItem)
    }

    map.addNavigatorAction(Actions.postAddItem) { navigator in
        print("In \(navigator.screenState)")
    }
    
    return map
}
