/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Render the graph to a string.
public protocol GraphRepresentation {
    var fileExtension: String { get }
    func begin()
    func renderScreenStateNode(name: String, isDismissedOnUse: Bool)
    func renderScreenActionNode(name: String)
    func renderEdgeToScreenState(src: String, dest: String, label: String?, isBackable: Bool)
    func renderEdgeToScreenAction(src: String, dest: String, label: String?)
    func end()
    func stringValue() -> String
}

public extension MMScreenGraph {
    public func stringRepresentation(_ renderer: GraphRepresentation = DotRepresentation()) -> String {
        buildGkGraph()
        renderer.begin()
        namedScenes.forEach { (name, node) in
            if let node = node as? MMScreenStateNode {
                renderer.renderScreenStateNode(name: name, isDismissedOnUse: node.dismissOnUse)
            } else if let _ = node as? MMScreenActionNode {
                renderer.renderScreenActionNode(name: name)
            }
        }

        namedScenes.forEach { (src, node) in
            if let node = node as? MMScreenStateNode {
                node.edges.values.forEach { edge in
                    guard let dest = namedScenes[edge.destinationName] else { return }
                    let directed: Bool
                    if let dest = dest as? MMScreenStateNode {
                        directed = !dest.hasBack
                        renderer.renderEdgeToScreenState(src: src,
                                                         dest: dest.name,
                                                         label: edge.predicate?.predicateFormat,
                                                         isBackable: directed)
                    } else if let _ = dest as? MMScreenActionNode {
                        renderer.renderEdgeToScreenAction(
                            src: src,
                            dest: dest.name,
                            label: edge.predicate?.predicateFormat)
                    } else {
                        return
                    }


                }
            } else if let node = node as? MMScreenActionNode {
                if let destName = node.nextNodeName {
                    renderer.renderEdgeToScreenState(src: src, dest: destName, label: nil, isBackable: true)
                }
            }
        }

        renderer.end()
        return renderer.stringValue()
    }
}

/// The default implementation
class DotRepresentation: GraphRepresentation {
    var lines: [String] = []

    var namedIDs: [String: String] = [:]
    var idGenerator = 0

    let actionColor = "lightblue"
    let fontActionColor = "white"

    public var fileExtension: String { return "dot" }

    init() {
    }

    func begin() {
        lines = []
        append("digraph G {",
               "fontsize=15;",
               "font=Helvetica;",
               "labelloc=t;",
               "label=\"\"", "splines=true", "overlap=false", "rankdir = LR;",
               "ratio = auto;",
               "node [ shape = box ]"
        )

        renderLegend()
    }

    func stringValue() -> String {
        return lines.joined(separator: "\n")
    }

    private func append(_ additional: String...) {
        lines = lines + additional
    }

    private func id(for name: String) -> String {
        if let id = namedIDs[name] {
            return id
        }

        let id = "_\(idGenerator)"
        idGenerator += 1
        namedIDs[name] = id
        return id
    }


    func renderScreenStateNode(name: String, isDismissedOnUse dismissOnUse: Bool) {
        let id = self.id(for: name)
        var styleCode = "label=\"\(name)\"; "
        if dismissOnUse {
            styleCode += "fillcolor=lightgray; color=gray; style=filled"
        } else {
            styleCode += "color=black"
        }
        append("\(id) [ \(styleCode) ];")
    }

    func renderScreenActionNode(name: String) {
        let id = self.id(for: name)
        append("\(id) [ label = \"\(name)\"; shape=egg; style=filled; color=\(actionColor); fillcolor=\(actionColor); fontcolor=\(fontActionColor); fontsize=10];")
    }

    func renderEdgeToScreenState(src: String, dest: String, label: String?, isBackable: Bool) {
        var styleCode: String = "[ "

        if let label = label {
            styleCode += "label=\"\(label)\"; style=dashed"
        } else {
            styleCode += "style=solid"
        }

        if isBackable {
            styleCode += "; dir=both; arrowtail=obox; arrowhead=normal"
        } 

        let srcID = id(for: src)
        let destID = id(for: dest)

        let edgeCode = "->"

        styleCode += " ]"

        append("\(srcID) \(edgeCode) \(destID)\(styleCode);")
    }

    func renderEdgeToScreenAction(src: String, dest: String, label: String?) {
        let labelCode: String

        if let label = label {
            labelCode = " [ label=\"\(label)\"; style=dashed; color=\(actionColor) ]"
        } else {
            labelCode = " [ color=\(actionColor) ]"
        }
        let srcID = id(for: src)
        let destID = id(for: dest)

        let edgeCode = "->"

        append("\(srcID) \(edgeCode) \(destID)\(labelCode);")
    }

    func end() {
        append("}")
    }

    func renderLegend() {
        var i = 1;
        var labels = [String]()
        func label(_ string: String) {
            labels += [("k\(i) [label=\"\(string)\\r\"];")]
            i += 1
        }

        append("subgraph cluster_legend {",
               "fontsize=15;",
               "label=\"Legend\";")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen2", label: nil, isBackable: false)
        label("Transition between two screens")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen2", label: "numItems > 0", isBackable: false)
        label("Transition between two screens\\rconditional on user state")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen3", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen3", label: nil, isBackable: true)
        renderEdgeToScreenState(src: "Screen2", dest: "Screen3", label: nil, isBackable: true)
        label("Screen3 has a back action\\rto get back to where it came from")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: true)
        renderScreenStateNode(name: "Screen3", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen2", label: nil, isBackable: true)
        renderEdgeToScreenState(src: "Screen2", dest: "Screen3", label: nil, isBackable: true)
        label("Screen2 is not added to the back stack.\\rGoing back from Screen3 goes to Screen1")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen", isDismissedOnUse: false)
        renderScreenActionNode(name: "Named Action")
        renderEdgeToScreenAction(src: "Screen", dest: "Named Action", label: nil)
        label("Named Action can be performed from Screen")

        namedIDs = [:]
        renderScreenActionNode(name: "Menu-NewTab")
        renderScreenActionNode(name: "TabTray-NewTab")
        renderScreenActionNode(name: "NewTab")
        renderScreenStateNode(name: "NewTabScreen", isDismissedOnUse: false)
        renderEdgeToScreenAction(src: "Menu-NewTab", dest: "NewTab", label: nil)
        renderEdgeToScreenAction(src: "TabTray-NewTab", dest: "NewTab", label: nil)
        renderEdgeToScreenState(src: "NewTab", dest: "NewTabScreen", label: nil, isBackable: false)
        label("NewTab action can be accessed —\\rand tested — from multiple places.\\rBoth lead to the NewTabScreen.")


        append("{",
            "rank=source",
            "node [shape=plaintext, style=solid, width=3.5];")

        lines += labels

        append("}")

        append("}")
    }
}
