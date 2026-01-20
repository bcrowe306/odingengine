package main

import rl "vendor:raylib"


RectangleNode :: struct {
    using node: Node,
    position: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color,
}

createRectNode :: proc(name: string = "", position: rl.Vector2 = rl.Vector2{0.0, 0.0}, layer: LayerZIndex = 0) -> ^RectangleNode {
    node := new(RectangleNode)
    setNodeDefaults(cast(^Node)node, name)
    node.layer = layer
    node.transform.position = position
    node.type = NodeType.Rectangle
    node.size = rl.Vector2{50.0, 50.0}
    node.color = rl.RED
    node.draw = drawRectNode
    node.ready = rectReady
    return node
}
rectReady :: proc(node_ptr: rawptr) {
    node := cast(^RectangleNode)node_ptr
    signalEmit(&node.on_ready, cast(^Node)node)
}
drawRectNode :: proc(node_ptr: rawptr) {
    node := cast(^RectangleNode)node_ptr
    // Draw rectangle
    rl.DrawRectangleV(node.transform.global_pos , node.size, node.color)

}
