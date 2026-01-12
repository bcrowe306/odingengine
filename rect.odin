package main

import rl "vendor:raylib"
import uuid "core:encoding/uuid"
import crypto "core:crypto"

drawRect :: proc(node: ^Node) {
    rl.DrawRectangleV(node.position, rl.Vector2{20 * node.scale.x, 20 * node.scale.y}, rl.RED)
}

RectangleNode :: struct {
    base: Node,
    size: rl.Vector2,
}

rectangleNodeConstruct :: proc(position: rl.Vector2, scale: rl.Vector2, rotation: f32, size: rl.Vector2) -> RectangleNode {
    rectNode: RectangleNode
    rectNode.base = nodeConstruct(position, scale, rotation)
    rectNode.base.draw = drawRect
    rectNode.size = size
    return rectNode
}