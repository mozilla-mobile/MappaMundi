/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * MappaMundi helps you get rid of the navigation boiler plate found in a lot of whole-application UI testing.
 *
 * You create a shared graph of UI 'screenStates' and 'screenActions' for your app, and use it for every test.
 *
 * In your tests, you use a navigator which does the job of getting your tests from place to place in your application,
 * leaving you to concentrate on testing, rather than maintaining brittle and duplicated navigation code.
 * 
 * The shared graph may also have other uses, such as generating screen shots for the App Store or L10n translators.
 *
 * Under the hood, the MappaMundi is using GameplayKit's path finding to do the heavy lifting.
 */

import Foundation
import GameplayKit
import XCTest

public typealias MMScreenStateBuilder<T: MMUserState> = (MMScreenStateNode<T>) -> Void

/**
 * ScreenGraph
 * This is the main interface to building a graph of screens/app states and how to navigate between them.
 * The ScreenGraph will be used as a map to navigate the test agent around the app.
 */
open class MMScreenGraph<T: MMUserState> {
    fileprivate let userStateType: T.Type
    let xcTest: XCTestCase

    var namedScenes: [String: MMGraphNode<T>] = [:]
    var nodedScenes: [GKGraphNode: MMGraphNode<T>] = [:]

    var conditionalEdges: [ConditionalEdge<T>] = []

    fileprivate var isReady: Bool = false

    let gkGraph: GKGraph

    public typealias UserStateChange = (T) -> ()
    fileprivate let defaultStateRecorder: UserStateChange = { _ in }

    public init(for test: XCTestCase, with userStateType: T.Type) {
        self.gkGraph = GKGraph()
        self.userStateType = userStateType
        self.xcTest = test
    }
}

public extension MMScreenGraph {
    /**
     * Method for creating a ScreenStateNode in the graph. The node should be accompanied by a closure
     * used to document the exits out of this node to other nodes.
     */
    public func addScreenState(_ name: String, file: String = #file, line: UInt = #line, builder: @escaping MMScreenStateBuilder<T>) {
        namedScenes[name] = MMScreenStateNode(map: self, name: name, file: file, line: line, builder: builder)
    }

    /**
     * Method for creating a ScreenActionNode in the graph.
     * The transitionTo: node is the screen state that the navigator should go to next from here. It will be called with the userState as an argument.
     * The recorder: closure will be called when the navigator travels to this node.
     */
    public func addScreenAction(_ name: String, transitionTo nextNodeName: String, file: String = #file, line: UInt = #line, recorder: @escaping (T) -> ()) {
        addOrCheckScreenAction(name, transitionTo: nextNodeName, file: file, line: line, recorder: recorder)
    }

    /**
     * Method for creating a ScreenActionNode in the graph.
     * The transitionTo: node is the screen state that the navigator should go to next from here. It will be called with the userState as an argument.
     */
    public func addScreenAction(_ name: String, transitionTo nextNodeName: String, file: String = #file, line: UInt = #line) {
        addOrCheckScreenAction(name, transitionTo: nextNodeName, file: file, line: line, recorder: defaultStateRecorder)
    }
}

extension MMScreenGraph {
    func addActionChain(_ actions: [String], finalState screenState: String?, recorder: @escaping UserStateChange, file: String, line: UInt) {
        guard actions.count > 0 else {
            return
        }

        let firstNodeName = actions[0]
        if let existing = namedScenes[firstNodeName] {
            xcTest.recordFailure(withDescription: "Action \(firstNodeName) is defined elsewhere, but should be unique", inFile: file, atLine: line, expected: true)
            xcTest.recordFailure(withDescription: "Action \(firstNodeName) is defined elsewhere, but should be unique", inFile: existing.file, atLine: existing.line, expected: true)
        }

        if let screenState = screenState {
            guard let _ = namedScenes[screenState] as? MMScreenStateNode else {
                xcTest.recordFailure(withDescription: "Expected \(screenState) to be a screen state", inFile: file, atLine: line, expected: false)
                return
            }
        }

        for i in 0..<actions.count {
            let thisNodeName = actions[i]
            let nextNodeName = i + 1 < actions.count ? actions[i + 1] : screenState
            let thisRecorder: UserStateChange?
            if i == 0 {
                thisRecorder = recorder
            } else {
                thisRecorder = nil
            }
            addOrCheckScreenAction(thisNodeName, transitionTo: nextNodeName, file: file, line: line, recorder: thisRecorder)
        }
    }

    fileprivate func addOrCheckScreenAction(_ name: String, transitionTo nextNodeName: String? = nil, file: String = #file, line: UInt = #line, recorder: UserStateChange?) {
        let actionNode: MMScreenActionNode<T>
        if let existingNode = namedScenes[name] {
            guard let existing = existingNode as? MMScreenActionNode else {
                self.xcTest.recordFailure(withDescription: "Screen state \(name) conflicts with an identically named action", inFile: existingNode.file, atLine: existingNode.line, expected: false)
                self.xcTest.recordFailure(withDescription: "Action \(name) conflicts with an identically named screen state", inFile: file, atLine: line, expected: false)
                return
            }
            // The new node has to have the same nextNodeName as the existing node.
            // unless either one of them is nil, so use whichever is the non nil one.
            if let d1 = existing.nextNodeName,
                let d2 = nextNodeName,
                d1 != d2 {
                self.xcTest.recordFailure(withDescription: "\(name) action points to \(d2) elsewhere", inFile: existing.file, atLine: existing.line, expected: false)
                self.xcTest.recordFailure(withDescription: "\(name) action points to \(d1) elsewhere", inFile: file, atLine: line, expected: false)
                return
            }

            let overwriteNodeName = existing.nextNodeName ?? nextNodeName

            // The new version of the same node can have additional UserStateChange recorders,
            // so we just combine these together.
            let overwriteRecorder: UserStateChange?
            if let r1 = existing.onEnterStateRecorder,
                let r2 = recorder {
                overwriteRecorder = { userState in
                    r1(userState)
                    r2(userState)
                }
            } else {
                overwriteRecorder = existing.onEnterStateRecorder ?? recorder
            }

            actionNode = MMScreenActionNode(self,
                                          name: name,
                                          then: overwriteNodeName,
                                          file: file,
                                          line: line,
                                          recorder: overwriteRecorder)

        } else {
            actionNode = MMScreenActionNode(self,
                                          name: name,
                                          then: nextNodeName,
                                          file: file,
                                          line: line,
                                          recorder: recorder)
        }

        self.namedScenes[name] = actionNode
    }
}

public extension MMScreenGraph {
    /**
     * Create a new navigator object. Navigator objects are the main way of getting around the app.
     * Typically, you'll do this in `TestCase.setUp()`
     */
    public func navigator(startingAt: String? = nil, file: String = #file, line: UInt = #line) -> MMNavigator<T> {
        buildGkGraph()
        let userState = userStateType.init()
        guard let name = startingAt ?? userState.initialScreenState,
            let startingScreenState = namedScenes[name] as? MMScreenStateNode else {
                xcTest.recordFailure(withDescription: "The app's initial state couldn't be established.",
                                     inFile: file, atLine: line, expected: false)
                fatalError("The app's initial state couldn't be established.")
        }

        userState.initialScreenState = startingScreenState.name

        return MMNavigator(self, xcTest: xcTest, startingScreenState: startingScreenState, userState: userState)
    }

    func buildGkGraph() {
        if isReady {
            return
        }

        isReady = true

        // We have a collection of named nodes – mostly screen states.
        // Each of those have builders, so use them to build the edges.
        // However, they may also contribute some actions, which are also nodes,
        // so namedScenes here is not the same as namedScenes after this block.
        namedScenes.values.forEach { graphNode in
            if let screenStateNode = graphNode as? MMScreenStateNode {
                screenStateNode.builder(screenStateNode)
            }
        }

        // Construct all the GKGraphNodes, and add them to the GKGraph.
        let graphNodes = namedScenes.values
        gkGraph.add(graphNodes.map { $0.gkNode })

        graphNodes.forEach { graphNode in
            nodedScenes[graphNode.gkNode] = graphNode
        }

        // Now, we should have a good idea what the edges of the nodes look like,
        // so we need to construct the GKGraph edges from it.
        graphNodes.forEach { graphNode in
            if let screenStateNode = graphNode as? MMScreenStateNode {
                let gkNodes = screenStateNode.edges.keys.flatMap { self.namedScenes[$0]?.gkNode } as [GKGraphNode]
                screenStateNode.gkNode.addConnections(to: gkNodes, bidirectional: false)
            } else if let screenActionNode = graphNode as? MMScreenActionNode {
                if let destName = screenActionNode.nextNodeName,
                    let destGkNode = namedScenes[destName]?.gkNode {
                    screenActionNode.gkNode.addConnections(to: [destGkNode], bidirectional: false)
                }
            }
        }

        self.conditionalEdges = calculateConditionalEdges()
    }

    fileprivate func calculateConditionalEdges() -> [ConditionalEdge<T>] {
        buildGkGraph()
        let screenStateNodes = namedScenes.values.flatMap { $0 as? MMScreenStateNode }

        return screenStateNodes.map { node -> [ConditionalEdge<T>] in
            let src = node.gkNode
            return node.edges.values.flatMap { edge -> ConditionalEdge<T>? in
                guard let predicate = edge.predicate,
                    let dest = self.namedScenes[edge.destinationName]?.gkNode else { return nil }

                return ConditionalEdge<T>(src: src, dest: dest, predicate: predicate)
            } as [ConditionalEdge<T>]
        }.flatMap { $0 }
    }
}
