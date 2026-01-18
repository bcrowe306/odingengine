package main

import "core:strings"
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
    CharacterMover,
}
nodeDrawSignature :: proc(node_ptr: rawptr)
nodeProcessSignature :: proc(node_ptr: rawptr, delta: f32)
nodeReadySignature :: proc(node_ptr: rawptr)
nodeInitializeSignature :: proc(node_ptr: rawptr)
// Base Node -----------------------

Node :: struct {
    id: NodeID,
    name: string,
    type: NodeType,
    parent: NodeIndex,
    children: [dynamic]NodeIndex,
    nodeManager: ^NodeManager,
    layer: string,
    initialize: nodeInitializeSignature,
    enter_tree: proc(node: rawptr),
    ready: nodeReadySignature,
    process: nodeProcessSignature,
    draw: nodeDrawSignature,
    exit_tree: proc(node: rawptr),
    is_initialized: bool,
    globalTransform: proc(node: ^Node) -> TransformComponent,

    transform: TransformComponent,
    visible: bool,
    enabled: bool,
    on_ready: Signal(^Node),
    getPath: proc(node: ^Node) -> string,
    getNode: proc(node: ^Node, path: string) -> rawptr,
    getNodeCount: proc(node: ^Node) -> i32,
}

setNodeDefaults :: proc(node: ^Node, name: string = "") {
    node.layer = BACKGROUND_LAYER
    node.visible = true
    node.enabled = true
    node.is_initialized = false
    node.on_ready.name = "on_ready"
    node.transform.position = rl.Vector2{0.0, 0.0}
    node.transform.scale = rl.Vector2{1.0, 1.0}
    node.transform.rotation = 0.0
    node.transform.origin = rl.Vector2{0.0, 0.0}
    node.getPath = getNodePath
    node.getNode = getNode
    node.globalTransform = getGlobalTransform
    node.getNodeCount = getNodeCount

}
getNewNodeID :: proc() -> u64 {
    id := NODE_ID_COUNTER
    NODE_ID_COUNTER += 1
    return id
}

setGenericName :: proc(node: ^Node) {
    node.name = fmt.tprintf("Node_%d", node.id)
}

// Get total nodes in tree starting from this node
getNodeCount :: proc(node: ^Node) -> i32 {
    count: i32 = 0
    countChildren :: proc (n: ^Node, c: ^i32) {
        for child_index in n.children {
            child_ptr := n.nodeManager->getNodeByIndex(child_index)
            child_node := cast(^Node)child_ptr
            if child_node != nil {
                c^ += 1
                countChildren(child_node, c)
            }
        }
    }
    countChildren(node, &count)
    return count
}

getRootNode :: proc(node: ^Node) -> ^Node {
    current := node
    for current.parent != cast(NodeIndex)-1 {
        parent_ptr := node.nodeManager->getNodeByIndex(current.parent)
        current = cast(^Node)parent_ptr
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
            if n.parent == cast(NodeIndex)-1 {
                return nil
            }
            parent_ptr := node.nodeManager->getNodeByIndex(n.parent)
            n = cast(^Node)parent_ptr
            if n == nil {
                return nil
            }
        } 
        else {
            // Search children for matching name
            found := false
            for child_index in n.children {
                child_ptr := node.nodeManager->getNodeByIndex(child_index)

                child_node := cast(^Node)child_ptr
                if child_node == nil {
                    continue
                }

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

nodeEnterTree :: proc(node: rawptr) {
    
    
}

nodeExitTree :: proc(node: ^Node) {
    
}


getNodePath :: proc(node: ^Node) -> string {
    path_parts := [dynamic]string{}
    current := node
    for current != nil {
        inject_at(&path_parts, 0, current.name)
        if current.parent == cast(NodeIndex)-1 {
            break
        }
        parent_ptr := node.nodeManager->getNodeByIndex(current.parent)
        current = cast(^Node)parent_ptr
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




// TODO: Implement transform hierarchy properly
getGlobalTransform :: proc(node: ^Node) -> TransformComponent {
    transform := node.transform
    current := node.parent
    for current != cast(NodeIndex)-1 {
        parent_node_ptr := node.nodeManager->getNodeByIndex(current)
        parent_node := cast(^Node)parent_node_ptr
        if parent_node == nil {
            break
        }
        transform.position += parent_node.transform.position
        transform.rotation += parent_node.transform.rotation
        transform.scale.x *= parent_node.transform.scale.x
        transform.scale.y *= parent_node.transform.scale.y
        current = parent_node.parent
    }
    node.transform.global_pos = transform.position
    node.transform.global_rotation = transform.rotation
    node.transform.global_scale = transform.scale
    return transform
}

updateNodes :: proc(node: ^Node, delta: f32) {
    
    
}


renderNodes :: proc(node: ^Node, layer_name: string) {
    
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
    rl.DrawRectangleV(node.transform.global_pos , node.size, node.color)

}


