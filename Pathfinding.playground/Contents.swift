
import GameplayKit
class NamedGKGraphNode: GKGraphNode {
    var name: String
    convenience init(_ name:String) {
        self.init()
        self.name = name
    }
    override init() {
        self.name = ""
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let node1 = NamedGKGraphNode("1") // declaring the Graph Nodes
let node2 = NamedGKGraphNode("2")
let node3 = NamedGKGraphNode("3")
let node4 = NamedGKGraphNode("4")
let node5 = NamedGKGraphNode("5")
let node6 = NamedGKGraphNode("6")
let node7 = NamedGKGraphNode("7")
let node8 = NamedGKGraphNode("8")
let node9 = NamedGKGraphNode("9")
let node10 = NamedGKGraphNode("10")
let node11 = NamedGKGraphNode("11")
let node12 = NamedGKGraphNode("12")
let node13 = NamedGKGraphNode("13")
let node14 = NamedGKGraphNode("14")
let node15 = NamedGKGraphNode("15")
let node16 = NamedGKGraphNode("16")
let node17 = NamedGKGraphNode("17")

func prepareGraph() -> GKGraph {
    let graph = GKGraph() // declaring the Graph
    
    // adding the Graph Nodes to the Graph
    graph.add([
        node1, node2, node3, node4, node5, node6, node8, node9, node10,
        node11, node12, node13, node14, node15, node16, node17
        ])
    
    //column 1
    node1.addConnections(to: [node2,node3,node4,node5,node6], bidirectional: false)
    node2.addConnections(to: [node13], bidirectional: false)
    node3.addConnections(to: [node7], bidirectional: false)
    node4.addConnections(to: [node7], bidirectional: false)
    node5.addConnections(to: [node8], bidirectional: false)
    node6.addConnections(to: [node17], bidirectional: false)
    //column 2
    node7.addConnections(to: [node9, node10], bidirectional: false)
    node8.addConnections(to: [node11, node12], bidirectional: false)
    //column 3
    node9.addConnections(to: [node13], bidirectional: false)
    node10.addConnections(to: [node17], bidirectional: false)
    node11.addConnections(to: [node17], bidirectional: false)
    node12.addConnections(to: [node14], bidirectional: false)
    //column 4
    node13.addConnections(to: [node15], bidirectional: false)
    node14.addConnections(to: [node16], bidirectional: false)
    //column 5
    node15.addConnections(to: [node17], bidirectional: false)
    node16.addConnections(to: [node17], bidirectional: false)
    
    return graph
}


func printPath(_ path:[GKGraphNode] ){
    path.forEach { node in
        if let node = node as? NamedGKGraphNode {
            print(node.name)
        }
    }
}

for _ in 1...1000 {
    let path: [GKGraphNode] = prepareGraph().findPath(from: node1, to: node17)
    if path.count != 3 {
        fatalError("path length should be 1->6->17, 3 steps!")
    }
}



