package main

import "core:c"
import rl "vendor:raylib"
import fmt "core:fmt"

NODE_ID_COUNTER : u64 = 1
NodeType:: enum {
    Node,
    Rectangle,
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
    initialized: bool,
    ready: nodeReadySignature,
    process: nodeProcessSignature,
    draw: nodeDrawSignature,
    on_ready: Signal(^Node),
    
    
}

getNewNodeID :: proc() -> u64 {
    id := NODE_ID_COUNTER
    NODE_ID_COUNTER += 1
    return id
}

setGenericName :: proc(node: ^Node) {
    node.name = fmt.tprintf("Node_%d", node.id)
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
    node.initialized = false
    node.ready = nodeReady
    node.on_ready.name = "on_ready"
}

createNode :: proc(name: string = "") -> ^Node {
    node := new(Node)
    node.type = NodeType.Node
    setNodeDefaults(node, name)
    node.draw = drawNode
    return node
}

addChildNode :: proc(parent: ^Node, child: ^Node) {
    append(&parent.add_queue, cast(rawptr)child)
}

removeChildNode :: proc(parent: ^Node, child_id: u64) {
    append(&parent.remove_queue, child_id)
}

processQueues :: proc(node: ^Node) {

    // Process remove queue
    for child_id in node.remove_queue {
        for child_ptr, index in node.children {
            child_node := cast(^Node)child_ptr
            if child_node.id == child_id {
                // Remove child
                child_node.parent = nil
                child_node.initialized = false
                ordered_remove(&node.children, index)
                
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
        if !child.initialized {
            if child.ready != nil {
                child.ready(cast(rawptr)child)
            }
            child.initialized = true
        }
    }
    clear(&node.add_queue)

    // Process children queues
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        processQueues(child_node)
    }

    if !node.initialized {
        if node.ready != nil {
            node.ready(cast(rawptr)node)
        }
        node.initialized = true
    }
    
}

updateNodes :: proc(node: ^Node, delta: f32) {
    if !node.enabled {
        return
    }

    // Update this node
    if node.parent == nil {
        node.transform.global_pos = node.transform.position
    }

    if node.process != nil {
        node.process(cast(rawptr)node, delta)
    }
    

    // Update children
    for &child_ptr in node.children {
        child_node := cast(^Node)child_ptr
        child_node.transform.global_pos = node.transform.position + child_node.transform.position
        child_node.transform.rotation = node.transform.rotation + child_node.transform.rotation
        child_node.transform.scale = node.transform.scale * child_node.transform.scale
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

drawNode :: proc(node_ptr: rawptr) {
    node := cast(^Node)node_ptr
    // Draw this node
    if node.draw != nil {
        rl.DrawText(fmt.ctprintf(node.name), i32(node.transform.global_pos.x) + 10, i32(node.transform.global_pos.y) + 20 * i32(node.id), 20, rl.WHITE)
    }
}

nodeReady :: proc(node_ptr: rawptr) {
    node := cast(^Node)node_ptr
    fmt.printfln("Node %s (ID: %d) is ready.", node.name, node.id)
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


