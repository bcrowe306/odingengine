package main

import "core:container/queue"
import "core:strings"
import "core:c"
import rl "vendor:raylib"
import fmt "core:fmt"

// TODO: Clean up node methods, signals, and function pointers

NODE_ID_COUNTER : u64 = 1
NodeType:: enum {
    Node,
    Rectangle,
    Sprite2D,
    AnimatedSprite2D,
    Text2D,
    AudioPlayer,
}
nodeDrawSignature :: proc(node_ptr: rawptr)
nodeProcessSignature :: proc(node_ptr: rawptr, delta: f32)
nodeReadySignature :: proc(node_ptr: rawptr)
// Base Node -----------------------

Node :: struct {
    id: u64,
    name: string,
    type: NodeType,
    children: [dynamic]rawptr,
    add_queue: [dynamic]rawptr,
    remove_queue: [dynamic]u64,
    parent: rawptr,
    transform: TransformComponent,
    layer: string,
    visible: bool,
    enabled: bool,
    is_ready: bool,
    is_initialized: bool,
    initialize: proc(rawptr),
    ready: nodeReadySignature,
    process: nodeProcessSignature,
    draw: nodeDrawSignature,
    nodeEnterTree: proc(node: ^Node),
    on_ready: Signal(^Node),
    getPath: proc(node: ^Node) -> string,
    getNode: proc(node: ^Node, path: string) -> rawptr,
    addChild: proc(parent: ^Node, child: ^Node),
    removeChild: proc(parent: ^Node, child_id: u64),
    queueFree: proc(node: ^Node),
}

setNodeDefaults :: proc(node: ^Node, name: string = "") {
    node.id = getNewNodeID()
    if name != "" {
        node.name = name
    } else {
        setGenericName(node)
    }
    node.layer = BACKGROUND_LAYER
    node.visible = true
    node.enabled = true
    node.is_ready = false
    node.on_ready.name = "on_ready"
    node.transform.position = rl.Vector2{0.0, 0.0}
    node.transform.scale = rl.Vector2{1.0, 1.0}
    node.transform.rotation = 0.0
    node.transform.origin = rl.Vector2{0.0, 0.0}
    node.getPath = getNodePath
    node.getNode = getNode
    node.addChild = addChildNode
    node.removeChild = removeChildNode
    node.queueFree = queueRemove
}
getNewNodeID :: proc() -> u64 {
    id := NODE_ID_COUNTER
    NODE_ID_COUNTER += 1
    return id
}

setGenericName :: proc(node: ^Node) {
    node.name = fmt.tprintf("Node_%d", node.id)
}

getRootNode :: proc(node: ^Node) -> ^Node {
    current := node
    for current.parent != nil {
        current = cast(^Node)current.parent
    }
    return current
}

getNode :: proc(node: ^Node, path: string) -> rawptr {
        // Get a node by path, supporting Unix-like path notation.
        
        // Supports:
        // - Absolute paths from root: "child/grandchild/node"
        // - Relative paths: "./sibling" or "../parent/sibling"
        // - Current node: "."
        // - Parent node: ".."
        
        // Args:
        //     path: The path to the node
            
        // Returns:
        //     The node if found, None otherwise
            
        // Examples:
        //     node.get_node("player/sprite")  # Get child's child
        //     node.get_node("./other_child")  # Get sibling
        //     node.get_node("../sibling")     # Get parent's other child
        //     node.get_node("..")             # Get parent

    // Determine starting point by dots and slashes
    n: ^Node = node
    if path == "" || path == "."{
        return n
    }

    // Split path into parts
    parts := strings.split(path, "/")
    for part in parts {
        if part == "" || part == "." {
            // Current node, do nothing
            continue
        } 
        else if part == ".." {
            // Move to parent
            if n.parent == nil {
                return nil
            }
            n = cast(^Node)n.parent
        } 
        else {
            // Search children for matching name
            found := false
            for &child_ptr in n.children {
                child_node := cast(^Node)child_ptr
                if child_node.name == part {
                    n = child_node
                    found = true
                    break
                }
            }
            if !found {
                return nil
            }
            
        }
    }
    return cast(rawptr)n
}

nodeEnterTree :: proc(node: ^Node) {
    
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        nodeEnterTree(child_node)
    }
}

nodeExitTree :: proc(node: ^Node) {
    
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        nodeExitTree(child_node)
    }
    node.is_ready = false
}


getNodePath :: proc(node: ^Node) -> string {
    path_parts := [dynamic]string{}
    current := node
    for current != nil {
        inject_at(&path_parts, 0, current.name)
        if current.parent == nil {
            break
        }
        current = cast(^Node)current.parent
    }
    
    result, err := strings.join(path_parts[:], "/")
    if err != nil {
        fmt.printfln("Error joining node path parts: %s", err)
        return ""
    }
    return result
}


createNode :: proc(name: string = "") -> ^Node {
    node := new(Node)
    node.type = NodeType.Node
    setNodeDefaults(node, name)
    return node
}

addChildNode :: proc(parent: ^Node, child: ^Node) {
    append(&parent.add_queue, cast(rawptr)child)
}

removeChildNode :: proc(parent: ^Node, child_id: u64) {
    append(&parent.remove_queue, child_id)
}

queueRemove :: proc(node: ^Node) {
    parent: ^Node = cast(^Node)node.parent
    parent->removeChild(node.id)
}

init :: proc (parent: ^Node) {
    for &child_ptr in parent.children {
        child_node := cast(^Node)child_ptr
        init(child_node)
    }
    if parent.initialize != nil {
        parent.initialize(cast(rawptr)parent)
    }
    parent.is_initialized = true
}

processQueues :: proc(node: ^Node) {

    // Process remove queue
    for child_id in node.remove_queue {
        for child_ptr, index in node.children {
            child_node := cast(^Node)child_ptr
            if child_node.id == child_id {
                // Remove child
                child_node.parent = nil
                child_node.is_ready = false
                ordered_remove(&node.children, index)
                nodeExitTree(child_node)
                break
            }
        }
    }
    clear(&node.remove_queue)

    // Process add queue
    for &child_ptr in node.add_queue {
        append(&node.children, child_ptr)
        child:= cast(^Node)child_ptr
        child.parent = cast(rawptr)node
        if !child.is_ready {
            if child.ready != nil {
                child.ready(cast(rawptr)child)
            }
            child.is_ready = true
        }
    }
    clear(&node.add_queue)

    // Process children queues
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        processQueues(child_node)
    }

    // Call initialize if not yet called
    if !node.is_initialized {
        if node.initialize != nil {
            node.initialize(cast(rawptr)node)
        }
        node.is_initialized = true
    }

    // Call ready if not yet called
    if !node.is_ready {
        if node.ready != nil {
            node.ready(cast(rawptr)node)
        }
        node.is_ready = true
    }
    
}

updateNodes :: proc(node: ^Node, delta: f32) {
    if !node.enabled {
        return
    }

    // Update this node's transform
    if node.parent == nil {
        node.transform.global_pos = node.transform.position
        node.transform.global_scale = node.transform.scale
        node.transform.global_rotation = node.transform.rotation
    }

    if node.process != nil {
        node.process(cast(rawptr)node, delta)
    }
    

    // Update children
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        child_node.transform.global_pos = node.transform.position + child_node.transform.position
        child_node.transform.global_rotation = node.transform.rotation + child_node.transform.rotation
        child_node.transform.global_scale = node.transform.scale * child_node.transform.scale
        updateNodes(child_node, delta)
    }
}


renderNodes :: proc(node: ^Node, layer_name: string) {
    // Render this node
    if node.layer != layer_name || !node.visible {
        return
    }
    if node.draw != nil {
        node.draw(cast(rawptr)node)
    }

    // Render children
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        renderNodes(child_node, layer_name)
    }
}



RectNode :: struct {
    using node: Node,
    position: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color,
}

createRectNode :: proc(name: string = "") -> ^RectNode {
    node := new(RectNode)
    setNodeDefaults(cast(^Node)node, name)
    node.type = NodeType.Rectangle
    node.size = rl.Vector2{50.0, 50.0}
    node.color = rl.RED
    node.draw = drawRectNode
    node.ready = rectReady
    return node
}
rectReady :: proc(node_ptr: rawptr) {
    node := cast(^RectNode)node_ptr
    signalEmit(&node.on_ready, cast(^Node)node)
}
drawRectNode :: proc(node_ptr: rawptr) {
    node := cast(^RectNode)node_ptr
    // Draw rectangle
    rl.DrawRectangleV(node.transform.global_pos + 50 * f32(node.id) , node.size, node.color)

}


