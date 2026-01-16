package main
import fmt "core:fmt"
import encoding "core:encoding"

n :: struct {
    id : int,
    name: string,
    parent: int,
    children: [dynamic]int,
    addChild: proc(this: ^n, nm: ^NodeManager, child_node: ^n),
}

ParentChild :: [2]int

addChild :: proc(this: ^n, nm: ^NodeManager, child_node: ^n) {
    if this == nil {
        fmt.printfln("Cannot add child. Parent node is nil")
        return
    }

    child_index := nm->getNodeIndex(child_node.id)
    if child_index == -1 {
        fmt.printfln("Cannot add child. Child node not found in NodeManager")
        return
    }
    parent_index := nm->getNodeIndex(this.id)
    if parent_index == -1 {
        fmt.printfln("Cannot add child. Parent node not found in NodeManager")
        return
    }
    
    append(&nm.addQueue, ParentChild{parent_index, child_index})
}

removeChild :: proc(this: ^n, nm: ^NodeManager, child_node: ^n) {
    if this == nil {
        fmt.printfln("Cannot add child. Parent node is nil")
        return
    }

    parent_index := nm->getNodeIndex(this.id)
    if parent_index == -1 {
        fmt.printfln("Cannot add child. Parent node not found in NodeManager")
        return
    }

    if child_node == nil {
        fmt.printfln("Cannot add child. Child node is nil")
        return
    }
    child_index := nm->getNodeIndex(child_node.id)
    if child_index == -1 {
        fmt.printfln("Cannot add child. Child node not found in NodeManager")
        return
    }
    
    
    append(&nm.removeQueue, ParentChild{parent_index, child_index})
}

NodeManager :: struct {
    nodes: [dynamic]rawptr,
    node_id_counter: int,
    createNode: proc(this: ^NodeManager, name: string = "") -> ^n,
    newNodeId: proc(this: ^NodeManager, node: ^n),
    getNodeIndex: proc(this: ^NodeManager, node_id: int) -> int,
    getNodeById: proc(this: ^NodeManager, node_id: int) -> ^n,
    addQueue: [dynamic]ParentChild, // (parent_index, child_index)
    removeQueue: [dynamic]ParentChild,
    processQueues: proc(nm: ^NodeManager),
}

getNodeIndex :: proc(this: ^NodeManager, node_id: int) -> int {
   for &node, index in &this.nodes {
       if node.id == node_id {
           return index
       }
   }
   return -1
}

getNodeById :: proc(this: ^NodeManager, node_id: int) -> ^n {
    index := this->getNodeIndex(node_id)
    if index == -1 {
        return nil
    }
    return &this.nodes[index]
}

constructNodeManager :: proc() -> ^NodeManager {
    manager := new(NodeManager)
    manager.node_id_counter = 0
    manager.createNode = createNode
    manager.newNodeId = getNewNodeId
    manager.getNodeIndex = getNodeIndex
    manager.nodes = make([dynamic]n, 0)
    manager.getNodeById = getNodeById
    manager.processQueues = processNodeManagerQueues
    return manager
}

getNewNodeId :: proc(this: ^NodeManager, node: ^n) {
    node.id = this.node_id_counter
    this.node_id_counter += 1
}

createNode :: proc(this: ^NodeManager, name: string = "") -> ^n {
    new_node := n{}
    this->newNodeId(&new_node)
    new_node.addChild = addChild
    if name != "" {
        new_node.name = name
    } else {
        new_node.name = fmt.tprintf("Node_%d", new_node.id)
    }
    new_node.parent = -1
    _, err := append(&this.nodes, new_node)
    if err != nil {
        fmt.printfln("Error creating node: %s", err)
        return nil
    }
    
    return &this.nodes[len(this.nodes) - 1]
}

processNodeManagerQueues :: proc(nm: ^NodeManager) {
    for &pc in &nm.addQueue {
        parent_index := pc[0]
        child_index := pc[1]
        parent_node := &nm.nodes[parent_index]
        if parent_node == nil {
            fmt.printfln("Parent node not found in add queue processing")
            continue
        }
        child_node := &nm.nodes[child_index]
        if child_node == nil {
            fmt.printfln("Child node not found in add queue processing")
            continue
        }
        append(&parent_node.children, child_node.id)
        child_node.parent =  parent_index
    }
    // Clear add queue after processing
    clear(&nm.addQueue)

    // Process remove queue (not implemented in this example)
    for &pc in &nm.removeQueue {
        parent_index := pc[0]
        child_index := pc[1]
        parent_node := &nm.nodes[parent_index]
        if parent_node == nil {
            fmt.printfln("Parent node not found in add queue processing")
            continue
        }
        child_node := &nm.nodes[child_index]
        if child_node == nil {
            fmt.printfln("Child node not found in add queue processing")
            continue
        }
        for child_node_index, i in &parent_node.children {
            if child_node_index == child_index {
                ordered_remove(&parent_node.children, i)
                break
            }
        }
    }
    
}


main :: proc() {
    nodeManager := constructNodeManager()

    root := nodeManager->createNode("Root")
    root_id := root.id
    root->addChild(nodeManager, nodeManager->createNode("Child_A"))
    for i :=0; i < 50; i += 1 {
        if root_node := nodeManager->getNodeById(root_id); root_node != nil {
            root_node->addChild(nodeManager, nodeManager->createNode(fmt.tprintf("Child_%d", i)))
        } else {
            fmt.printfln("Root node not found")
        }
        
    }
    nodeManager->processQueues()

    for &node in &nodeManager.nodes {
        fmt.printfln("Node ID: %d, Name: %s, Parent ID: %d, Children Count: %d", node.id, node.name, node.parent, len(node.children))
    }


    

   
}