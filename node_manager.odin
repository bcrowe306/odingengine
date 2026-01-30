package main
import fmt "core:fmt"



NodeIndex :: distinct int
NodeID ::  distinct int
ParentChild :: distinct [2]NodeIndex

NodeIndentifier :: union {
    NodeID,
    NodeIndex,
}


// Manages all nodes in the game object
NodeManager :: struct {

    // Add node to the NodeManager and assign it a unique ID
    addNode: proc(this: ^NodeManager, node: rawptr) -> NodeID,

    // Remove node from the NodeManager and clean up relationships
    removeNode: proc(this: ^NodeManager, node: rawptr),

    // Get index of node by its ID
    getNodeIndex: proc(this: ^NodeManager, node_id: NodeID) -> NodeIndex,

    // Get node by its ID
    getNodeById: proc(this: ^NodeManager, node_id: NodeID) -> rawptr,

    // Get node by its index. Returns rawptr or nil if not found.
    getNodeByIndex: proc(this: ^NodeManager, index: NodeIndex) -> rawptr,

    // Get node by name. Returns the first match found, or nil if not found.
    getNodeByName: proc(this: ^NodeManager, name: string) -> rawptr,

    // Set the root node for the NodeManager
    setRootNode: proc(nm: ^NodeManager, index_or_id: NodeIndentifier),

    // Add child node to parent node in the NodeManager
    addChild: proc(nm: ^NodeManager, parent_ptr: rawptr, child_ptr: rawptr),

    // Remove child node from parent node in the NodeManager
    removeChild: proc(nm: ^NodeManager, parent_ptr: rawptr, child_ptr: rawptr),

    // Lists of node indices for drawing
    nodesToDraw: [dynamic]NodeIndex,

    // Lists of node indices for processing
    nodesToProcess: [dynamic]NodeIndex,

    // Pointer to layer_manager
    layer_manager: ^LayerManager,

    // ------ Internal Use Only -----------

    // All nodes in the game object
    _nodes: [dynamic]rawptr,

    // Root node index. This is the node that will be used as the root for the scene graph.
    _root_node: NodeIndex,

    // Temporary storage for changing root node next frame
    _next_root_node: NodeIndentifier,

    // Flag to indicate root node change next frame
    _change_tree_next_frame: bool,

    // Queue for adding nodes. Proccessed internally at the start of each frame for safe addition.
    _nodeAddQueue: [dynamic]rawptr,

    // Queue for removing nodes. Processed internally at the start of each frame for safe removal.
    _nodeRemoveQueue: [dynamic]rawptr,

    // Counter for assigning unique node IDs
    _node_id_counter: NodeID,

    /* 
        Initialize nodes once at the loading of game.
    */
    _initializeNodes: proc(nm: ^NodeManager),

    // Assign a new unique ID to the node
    _newNodeId: proc(this: ^NodeManager, node: rawptr),

    // Queues for processing parent-child relationships
    _addChildQueue: [dynamic]ParentChild, // (parent_index, child_index)

    // Queue for removing parent-child relationships
    _removeChildQueue: [dynamic]ParentChild,

    // Process add/remove child queues
    _processRelationships: proc(nm: ^NodeManager),

    // Process node add/remove queues
    _processNodeQueues: proc(nm: ^NodeManager),

    // For available node slot indices
    _nodePool: [dynamic]NodeIndex,

    // Add the a removed node's index to the pool for reuse. this is internal use only.
    _addIndexToPool: proc(this: ^NodeManager, index: NodeIndex),

    // Get a free node index from the pool, or -1 if none are available.
    _getFreeNodeIndex: proc(this: ^NodeManager) -> NodeIndex,

    // Get count of free indices in the pool
    _getFreePoolCount: proc(this: ^NodeManager) -> int,

    // Clear all relationships for a node
    _clearNodeRelationships: proc(this: ^NodeManager, node_ptr: rawptr),

    // Remove node from NodeManager by index. Internal use only.
    _doNodeRemoval: proc(this: ^NodeManager, index: NodeIndex),

    // Add a node to the NodeManager and assign it a unique ID. This does not add it to any parent-child relationships.
    _doAddNode: proc(this: ^NodeManager, node: rawptr),

    // Add node to process list
    _addNodeToProcessList: proc(this: ^NodeManager, parent_index: NodeIndex, child_index: NodeIndex),

    // Remove node from process list
    _removeNodeFromProcessList: proc(this: ^NodeManager, index: NodeIndex),

    // Add node to draw list
    _addNodeToDrawList: proc(this: ^NodeManager, parent_index: NodeIndex, child_index: NodeIndex),

    // Remove node from draw list
    _removeNodeFromDrawList: proc(this: ^NodeManager, index: NodeIndex),

    // Process root tree. This runs each frame and calls the process proc on each node in the tree.
    _proccessRootTree: proc(nm: ^NodeManager, delta: f32),


    // Update the draw and process lists for the current root node
    _updateLists: proc (nm: ^NodeManager),

    // True is the node_manager is currently in game loop
    _is_in_game_loop: bool,

    // Update the node tree if there are changes
    updateTree: proc (nm: ^NodeManager),

    // Cache for name to index lookups
    _name_to_index_cache: map[string]NodeIndex,

}

// Constructs a new NodeManager with default values
constructNodeManager :: proc(layer_manager: ^LayerManager) -> ^NodeManager {
    manager := new(NodeManager)
    manager._nodes = make([dynamic]rawptr, 0)
    manager._node_id_counter = 0
    manager.addNode = addNode
    manager.removeNode = removeNode
    manager.addChild = addChild
    manager.removeChild = removeChild
    manager._newNodeId = getNewNodeId
    manager.getNodeIndex = getNodeIndex
    manager.getNodeById = getNodeById
    manager.getNodeByIndex = getNodeByIndex
    manager._processRelationships = _processRelationships
    manager._addIndexToPool = _addIndexToPool
    manager._clearNodeRelationships = _clearNodeRelationships
    manager._processNodeQueues = _processNodeQueues
    manager._doAddNode = _doAddNode
    manager._doNodeRemoval = _doNodeRemoval
    manager._getFreeNodeIndex = _getFreeNodeIndex
    manager._addNodeToDrawList = _addNodeToDrawList
    manager._removeNodeFromDrawList = _removeNodeFromDrawList
    manager._addNodeToProcessList = _addNodeToProcessList
    manager._removeNodeFromProcessList = _removeNodeFromProcessList
    manager._next_root_node = cast(NodeIndex)-1
    manager._change_tree_next_frame = false
    manager._updateLists = _updateLists
    manager.setRootNode = setRootNode
    manager.getNodeByName = getNodeByName
    manager._proccessRootTree = _proccessRootTree
    manager._initializeNodes = _initializeNodes
    manager._is_in_game_loop = false
    manager._getFreePoolCount = _getFreePoolCount
    manager.updateTree = updateTree
    manager.layer_manager = layer_manager
    return manager
}

// Adds a node to the queue to be added to the NodeManager. Returns the assigned NodeID.
addNode :: proc(this: ^NodeManager, node_ptr: rawptr) -> NodeID {
    this->_newNodeId(node_ptr)
    new_node := cast(^Node)node_ptr
    new_node.nodeManager = this
    new_node.parent = -1
    if new_node.name == "" {
        new_node.name = fmt.tprintf("Node_%d", new_node.id)
    }
    _, err := append(&this._nodeAddQueue, node_ptr)
    if err != nil {
        fmt.printfln("Error adding node to _nodeAddQueue: %s", err)
        return cast(NodeID)-1
    }

    this->_processNodeQueues()

    return new_node.id
}

// Remove node from the NodeManager and clean up relationships
removeNode :: proc(this: ^NodeManager, node_ptr: rawptr) {
    node := cast(^Node)node_ptr
    if node == nil {
        fmt.printfln("Cannot remove node. Node is nil")
        return
    }
    index := this->getNodeIndex(node.id)
    if index == -1 {
        fmt.printfln("Node not found in NodeManager")
        return
    }

    for child_index in node.children {
        child_ptr := this->getNodeByIndex(child_index)
        child_node := cast(^Node)child_ptr
        if child_node != nil {
            this->removeNode(cast(rawptr)child_node)
        }
    }

    append(&this._nodeRemoveQueue, node_ptr)
    
    if !this._is_in_game_loop {
        this->_processNodeQueues()
    }
}


// addChild: Add child node to parent node in the NodeManager
addChild :: proc(nm: ^NodeManager, parent_ptr: rawptr, child_ptr: rawptr) {
    parent := cast(^Node)parent_ptr
    child := cast(^Node)child_ptr

    if parent == nil {
        fmt.printfln("Cannot add child. Parent node is nil")
        return
    }

    child_index := nm->getNodeIndex(child.id)
    if child_index == -1 {
        fmt.printfln("Cannot add child. Child node not found in NodeManager")
        return
    }
    parent_index := nm->getNodeIndex(parent.id)
    if parent_index == -1 {
        fmt.printfln("Cannot add child. Parent node not found in NodeManager")
        return
    }
    
    if parent_index == child_index {
        fmt.printfln("Cannot add child. Parent and child nodes are the same: P: %d, C: %d", parent_index, child_index)
        return
    }

    append(&nm._addChildQueue, ParentChild{parent_index, child_index})
    if !nm._is_in_game_loop {
        nm->_processRelationships()
    }
    nm._change_tree_next_frame = true
}

/*
    Remove child -> parent node relationship in the NodeManager. Does not remove the child node itself
    This will trigger exit tree and other lifecycle callbacks as needed.
*/
removeChild :: proc(node_manager: ^NodeManager, parent_ptr: rawptr, child_ptr: rawptr) {
    parent := cast(^Node)parent_ptr
    child := cast(^Node)child_ptr
    if parent == nil {
        fmt.printfln("Cannot remove child. Parent node is nil")
        return
    }

    parent_index := node_manager->getNodeIndex(parent.id)
    if parent_index == -1 {
        fmt.printfln("Cannot remove child. Parent node not found in NodeManager")
        return
    }

    if child == nil {
        fmt.printfln("Cannot add child. Child node is nil")
        return
    }
    child_index := node_manager->getNodeIndex(child.id)
    if child_index == -1 {
        fmt.printfln("Cannot remove child. Child node not found in NodeManager")
        return
    }
    append(&node_manager._removeChildQueue, ParentChild{parent_index, child_index})
    if !node_manager._is_in_game_loop {
        node_manager->_processRelationships()
    }
}

setRootNode :: proc(nm: ^NodeManager, index_or_id: NodeIndentifier) {
    nm._next_root_node = index_or_id
    nm._change_tree_next_frame = true
}

updateTree :: proc (nm: ^NodeManager) {
    if nm._change_tree_next_frame {
        _updateLists(nm)
        nm._change_tree_next_frame = false
    }
}

// Set the root node for the NodeManager. Internal use only.
_doSetRootNode :: proc(nm: ^NodeManager, index_or_id: NodeIndentifier) {
    switch v in index_or_id {
    case NodeID:
        index := nm->getNodeIndex(v)
        if index == cast(NodeIndex)-1 {
            fmt.printfln("Cannot set root node. NodeID %d not found", v)
            nm._change_tree_next_frame = false
            nm._next_root_node = cast(NodeIndex)-1
            return
        }
        nm._root_node = index
        nm._next_root_node = cast(NodeIndex)-1

    case NodeIndex:
        if v < 0 || v >= cast(NodeIndex)len(nm._nodes) {
            fmt.printfln("Cannot set root node. NodeIndex %d out of bounds", v)
            nm._change_tree_next_frame = false
            nm._next_root_node = cast(NodeIndex)-1
            return
        }
        nm._root_node = v
        nm._next_root_node = cast(NodeIndex)-1
        
    }
}

// Update the draw and process lists for the current root node
_updateLists :: proc (nm: ^NodeManager) {
    nm.layer_manager->clearLayerNodes()
    clear(&nm.nodesToProcess)
    traverseForLists :: proc (nm: ^NodeManager, node_index: NodeIndex) {
        node_ptr := nm->getNodeByIndex(node_index)
        n := cast(^Node)node_ptr
        if n.draw != nil {
            nm.layer_manager->addLayerNode(n.layer, node_index)
        }
        if n.process != nil {
            append(&nm.nodesToProcess, node_index)
        }
        
        if n.enter_tree != nil && !n.is_in_tree {
            n.enter_tree(cast(rawptr)n)
            n.is_in_tree = true
        }

        if n.ready != nil && !n.is_ready {
            n.ready(cast(rawptr)n)
            n.is_ready = true
        }

        for child_index in n.children {
            traverseForLists(nm, child_index)
        }
    }
    traverseForLists(nm, nm._root_node)
}

// Clear all relationships for a node
_clearNodeRelationships :: proc(this: ^NodeManager, node_ptr: rawptr) {
    node := cast(^Node)node_ptr
    if node == nil {
        fmt.printfln("Cannot clear relationships. Node is nil")
        return
    }
    node_index := this->getNodeIndex(node.id)
    if node_index == -1 {
        fmt.printfln("Cannot clear relationships. Node not found in NodeManager")
        return
    }

    // Remove all children
    for &child_index in &node.children {
        child_node := cast(^Node)this._nodes[child_index]
        if child_node != nil {
            if node.exit_tree != nil {
                node.is_in_tree = false
                node.is_ready = false
                node.exit_tree(cast(rawptr)child_node)
            }
            child_node.parent = -1
            
        }
    }

    // Remove from parent
    if node.parent != -1 {
        parent_node := cast(^Node)this._nodes[node.parent]
        if parent_node != nil {
            for child_index, i in parent_node.children {
                if child_index == node_index {
                    child_node := cast(^Node)this._nodes[child_index]
                    if child_node != nil {
                        if child_node.exit_tree != nil {
                            child_node.exit_tree(cast(rawptr)child_node)
                        }
                    }
                    ordered_remove(&parent_node.children, i)
                    break
                }
            }
        }
        node.parent = -1
    }

    
    clear(&node.children)
}


// Add the a removed node's index to the pool for reuse. this is internal use only.
_addIndexToPool :: proc(this: ^NodeManager, index: NodeIndex) {
    for i in this._nodePool {
        if i == index {
            return
        }
    }
    append(&this._nodePool, index)
}

// Get index of node by its ID. Returns -1 if not found.
getNodeIndex :: proc(this: ^NodeManager, node_id: NodeID) -> NodeIndex {
    for node_ptr, index in &this._nodes {
        node := cast(^Node)node_ptr
        if node == nil {
            continue
        }
        if node.id == node_id {
            return cast(NodeIndex)index
        }
   }
   fmt.printfln("NodeID %d not found in NodeManager", node_id)
   return -1
}

// Get node by name. Returns the first match found, or nil if not found.
getNodeByName :: proc(this: ^NodeManager, name: string) -> rawptr {

    // Check cache first
    if index, found := this._name_to_index_cache[name]; found {
        node_ptr := this->getNodeByIndex(index)
        if node_ptr != nil {
            return node_ptr
        }
        // If cached index is invalid, remove from cache
        delete_key(&this._name_to_index_cache, name)
    }

    for node_ptr, index in &this._nodes {
        node := cast(^Node)node_ptr
        if node == nil {
            continue
        }
        if node.name == name {
            // Update cache
            this._name_to_index_cache[name] = cast(NodeIndex)index
            return node_ptr
        }
   }
   return nil
}

// Get node by its ID. Returns nil if not found.
getNodeById :: proc(this: ^NodeManager, node_id: NodeID) -> rawptr {
    index := this->getNodeIndex(node_id)
    if index == -1 {
        return nil
    }
    return &this._nodes[index]
}

getNodeByIndex :: proc(this: ^NodeManager, index: NodeIndex) -> rawptr {
    if index < 0 || index >= cast(NodeIndex)len(this._nodes) {
        return nil
    }
    return this._nodes[index]
}

// Assigns a new unique ID to the node
getNewNodeId :: proc(this: ^NodeManager, node_ptr: rawptr) {
    node := cast(^Node)node_ptr
    node.id = this._node_id_counter
    this._node_id_counter += 1
}

// Add node to process list
_addNodeToProcessList :: proc(this: ^NodeManager, parent_index: NodeIndex, child_index: NodeIndex) {
    append(&this.nodesToProcess, child_index)
}

// Remove node from process list
_removeNodeFromProcessList :: proc(this: ^NodeManager, index: NodeIndex) {
    for node_index, i in this.nodesToProcess {
        if node_index == index {
            ordered_remove(&this.nodesToProcess, i)
            return
        }
    }
}

// Add node to draw list
_addNodeToDrawList :: proc(this: ^NodeManager, parent_index: NodeIndex, child_index: NodeIndex) {
    for node_index in this.nodesToDraw {
        if node_index == child_index {
            return
        }
    }
    append(&this.nodesToDraw, child_index)
}

// Remove node from draw list
_removeNodeFromDrawList :: proc(this: ^NodeManager, index: NodeIndex) {
    for node_index, i in this.nodesToDraw {
        if node_index == index {
            ordered_remove(&this.nodesToDraw, i)
            return
        }
    }
}


_getFreePoolCount :: proc(this: ^NodeManager) -> int {
    return len(this._nodePool)
}
// Returns a free node index from the pool, or -1 if none are available.
_getFreeNodeIndex :: proc(this: ^NodeManager) -> NodeIndex {
    if len(this._nodePool) > 0 {
        index := this._nodePool[len(this._nodePool) - 1]
        ordered_remove(&this._nodePool, len(this._nodePool) - 1)
        return index
    }
    return cast(NodeIndex)len(this._nodes)
}

// Adds a node to the NodeManager and assigns it a unique ID. This does not add it to any parent-child relationships.
_doAddNode :: proc(this: ^NodeManager, node: rawptr) {
    new_node_index := this->_getFreeNodeIndex()
    if new_node_index != -1 && new_node_index < cast(NodeIndex)len(this._nodes) {
        this._nodes[new_node_index] = node
        this._name_to_index_cache[(cast(^Node)node).name] = new_node_index
    }
    else {
        _, err := append(&this._nodes, node)
        if err != nil {
            fmt.printfln("Error adding node: %s", err)
            return
        }
        new_node_index = cast(NodeIndex)(len(this._nodes) - 1)
        this._name_to_index_cache[(cast(^Node)node).name] = new_node_index
    }
}


_doNodeRemoval :: proc(this: ^NodeManager, index: NodeIndex) {
    node := cast(^Node)this._nodes[index]
    if node == nil {
        fmt.printfln("Cannot remove node. Node is nil")
        return
    }
    _clearNodeRelationships(this, cast(rawptr)node)

    this.layer_manager->removeLayerNode(index)


    // Remove from process list if present
    for node_index, i in this.nodesToProcess {
        if node_index == index {
            ordered_remove(&this.nodesToProcess, i)
            break
        }
    }

    // Set nodes[index] to nil or a placeholder'
    this._nodes[index] = nil
    
    // Add index to nodePool for reuse
    this->_addIndexToPool(index)

    // Free the node memory
    free(node)
}

_processRelationships :: proc(nm: ^NodeManager) {
    for pc in nm._addChildQueue {
        parent_index := pc[0]
        child_index := pc[1]
        parent_node := cast(^Node)nm._nodes[parent_index]
        if parent_node == nil {
            fmt.printfln("Parent node not found in add queue processing")
            continue
        }
        child_node := cast(^Node)nm._nodes[child_index]
        if child_node == nil {
            fmt.printfln("Child node not found in add queue processing")
            continue
        }
        append(&parent_node.children, child_index)
        child_node.parent =  parent_index
        // Lifecycle callbacks
        if !child_node.is_initialized {
            if child_node.initialize != nil {
                child_node.initialize(cast(rawptr)child_node)
            }
            child_node.is_initialized = true
        }
    }
    // Clear add queue after processing
    clear(&nm._addChildQueue)

    for &pc in &nm._removeChildQueue {
        parent_index := pc[0]
        child_index := pc[1]
        parent_node := cast(^Node)&nm._nodes[parent_index]
        if parent_node == nil {
            fmt.printfln("Parent node not found in add queue processing")
            continue
        }
        child_node := cast(^Node)&nm._nodes[child_index]
        if child_node == nil {
            fmt.printfln("Child node not found in add queue processing")
            continue
        }
        for child_node_index, i in parent_node.children {
            if child_node_index == child_index {
                ordered_remove(&parent_node.children, i)
                child_node.parent = -1
                // Do lifecycle callbacks here.
                if child_node.exit_tree != nil {
                    child_node.exit_tree(cast(rawptr)child_node)
                }
                nm->_removeNodeFromProcessList(child_index)
                nm->_removeNodeFromDrawList(child_index)
                break
            }
        }
    }
    // Clear remove queue after processing
    clear(&nm._removeChildQueue)
    
}

isNodeInTree :: proc(nm: ^NodeManager, index: NodeIndex) -> bool {
    root := nm->getNodeByIndex(nm._root_node)
    root_node := cast(^Node)root
    if root == nil {
        return false
    }
    if nm._root_node == index {
        return true
    }
    
    isNodeIndChilren :: proc(nm: ^NodeManager, current: ^Node, target_index: NodeIndex) -> bool {
        for child_index in current.children {
            if child_index == target_index {
                return true
            }
            child_node := cast(^Node)nm->getNodeByIndex(child_index)
            if child_node != nil {
                return isNodeIndChilren(nm, child_node, target_index)
            }
        }
        return false
    }

    return isNodeIndChilren(nm,root_node, index)
}
// Process node add/remove queues. Happens at the start of each frame.
_processNodeQueues :: proc(nm: ^NodeManager) {

    // Process remove queue
    for node_ptr in &nm._nodeRemoveQueue {
        node := cast(^Node)node_ptr
        index := nm->getNodeIndex(node.id)
        if index == -1 {
            fmt.printfln("Node not found in remove queue processing")
            continue
        }
        nm->_doNodeRemoval(index)
    }
    clear(&nm._nodeRemoveQueue)

    // Process add queue
    for node_ptr in &nm._nodeAddQueue {
        nm->_doAddNode(node_ptr)
        // _, err := append(&nm._nodes, node_ptr)
        // if err != nil {
        //     fmt.printfln("Error adding node from add queue: %s", err)
        //     continue
        // }
    }
    clear(&nm._nodeAddQueue)
}


 _initializeNodes :: proc(nm: ^NodeManager) {
    for node_ptr in &nm._nodes {
        node := cast(^Node)node_ptr
        if node != nil && !node.is_initialized && node.initialize != nil {
            node.initialize(cast(rawptr)node)
            node.is_initialized = true
        }
    }
 }


_proccessRootTree :: proc(nm: ^NodeManager, delta: f32) {
   
    for node_index in &nm.nodesToProcess {
        node_ptr := nm->getNodeByIndex(node_index)
        node := cast(^Node)node_ptr

        // Update global transform
        node->globalTransform()
        if node != nil && node.process != nil {
            node.process(cast(rawptr)node, delta)
        }
    }
}
