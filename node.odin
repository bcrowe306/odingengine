package main

import rl "vendor:raylib"
import uuid "core:encoding/uuid"
import crypto "core:crypto"

NodeDrawDef :: proc(node: ^Node)
NodeProcessDef :: proc(node: ^Node, delta: f32)

Node :: struct {
    id: uuid.Identifier,
    position: rl.Vector2,
    scale: rl.Vector2,
    rotation: f32,
    parent: ^Node,
    children: [dynamic]Node,
    add_queue: [dynamic]Node,
    remove_queue: [dynamic]uuid.Identifier,
    draw: NodeDrawDef,
    process: NodeProcessDef,
}


nodeConstruct :: proc(position: rl.Vector2, scale: rl.Vector2, rotation: f32) -> Node {
    context.random_generator = crypto.random_generator()
    node: Node
    node.id = uuid.generate_v4()
    node.position = position
    node.scale = scale
    node.rotation = rotation
    node.draw = nodeDraw
    node.process = nodeProcess
    return node
}
nodeAddChild :: proc(node: ^Node, child: Node) {
    append(&node.add_queue, child)
}

nodeRemoveChild :: proc(node: ^Node, child_id: uuid.Identifier) {
    append(&node.remove_queue, child_id)
}

nodeProcessQueues :: proc(node: ^Node) {
    // Process removals
    for child_id in node.remove_queue {
        for child, index in node.children {
            if child.id == child_id {
                ordered_remove(&node.children, index)
                break
            }
        }
    }
    clear(&node.remove_queue)
    
    // Process additions
    for &child in node.add_queue {
        append(&node.children, child)
        child.parent = node
    }
    clear(&node.add_queue)

    for &child in node.children {
        nodeProcessQueues(&child)
    }
    
}

nodeUpdate :: proc(node: ^Node, delta: f32) {
    // Placeholder for update logic
    for &child in node.children {
        nodeUpdate(&child, delta)
    }
    node.process(node, delta)
}

nodeRender :: proc(node: ^Node) {
    // Placeholder for render logic
    for &child in node.children {
        nodeRender(&child)
    }
    node.draw(node)
}


nodeProcess :: proc(node: ^Node, delta: f32) {
    // Placeholder for processing logic
    
}


nodeDraw :: proc(node: ^Node) {
    // Placeholder for drawing logic
    for &child in node.children {
        nodeDraw(&child)
    }
    rl.DrawCircleV(node.position, 10, rl.BLUE)   
}
