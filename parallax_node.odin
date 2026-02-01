package main

import rl "vendor:raylib"

ParallaxNode :: struct {
    using node: Node,
    resource_manager: ^ResourceManager,
    texture: rl.Texture2D,
    file_path: string,
    horizontal_scroll_scale: f32,
    vertical_scroll_scale: f32,
    source_rect: rl.Rectangle,
    old_camera_pos: rl.Vector2,
    offset: rl.Vector2,
}

createParallaxNode :: proc(resource_manager: ^ResourceManager, name: string, file_path: string) -> ^ParallaxNode {
    parallax_node := new(ParallaxNode)
    setNodeDefaults(cast(^Node)parallax_node, name)
    parallax_node.resource_manager = resource_manager
    parallax_node.file_path = file_path
    parallax_node.horizontal_scroll_scale = 1.0
    parallax_node.vertical_scroll_scale = 1.0
    parallax_node.initialize = initializeParallaxNode
    parallax_node.process = processParallaxNode
    parallax_node.draw = drawParallaxNode
    parallax_node.layer = BACKGROUND_LAYER
    return parallax_node
}

initializeParallaxNode :: proc(parallax_node_ptr: rawptr) {
    parallax_node := cast(^ParallaxNode)parallax_node_ptr
    using parallax_node
    texture = parallax_node.resource_manager->loadTexture(file_path)
    source_rect = rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
}

processParallaxNode :: proc(parallax_node_ptr: rawptr, delta_time: f32) {
    parallax_node := cast(^ParallaxNode)parallax_node_ptr
    using parallax_node
    cam := GAME.camera
    if cam != nil {
        if rl.Vector2Equals(old_camera_pos, rl.Vector2{0,0}) {
            old_camera_pos = cam.target
        }
        dif := cam.target - old_camera_pos
        offset.x += dif.x * horizontal_scroll_scale
        offset.y += dif.y * vertical_scroll_scale
        old_camera_pos = cam.target
    }
    // Example parallax effect: move texture based on some factor (e.g., camera position)
    // This is a placeholder; actual implementation would depend on camera position and speed
    // transform.position.x *= horizontal_scroll_scale
    // transform.position.y *= vertical_scroll_scale
}

drawParallaxNode :: proc(parallax_node_ptr: rawptr) {
    parallax_node := cast(^ParallaxNode)parallax_node_ptr
    using parallax_node
    dest_rect := rl.Rectangle{transform.global_pos.x + offset.x, transform.global_pos.y + offset.y, f32(texture.width), f32(texture.height)}
    
    rl.DrawTexturePro(
        texture,
        source_rect,
        rl.Rectangle{transform.global_pos.x + offset.x, transform.global_pos.y + offset.y, f32(texture.width), f32(texture.height)},
        rl.Vector2{0, 0},
        0.0,
        rl.WHITE
    )
    if dest_rect.x + dest_rect.width < old_camera_pos.x + GAME.window_size.x {
        // Draw additional tile to the right
        rl.DrawTexturePro(
            texture,
            source_rect,
            rl.Rectangle{transform.global_pos.x + offset.x + f32(texture.width), transform.global_pos.y + offset.y, f32(texture.width), f32(texture.height)},
            rl.Vector2{0, 0},
            0.0,
            rl.WHITE
        )
    }
}