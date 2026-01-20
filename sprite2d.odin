package main

import "core:c"
import rl "vendor:raylib"
import fmt "core:fmt"


Sprite2D :: struct {
    using node: Node,
    image_path: string,
    resource_manager: ^ResourceManager,
    texture: TextureComponent,
    current_frame: u32,
}

createSprite2D :: proc(rm: ^ResourceManager, name: string = "", file_path: string, color: rl.Color = rl.WHITE) -> ^Sprite2D {
    sprite2d := new(Sprite2D)
    setNodeDefaults(cast(^Node)sprite2d, name)
    sprite2d.texture.texture = rm->loadTexture(file_path)
    sprite2d.image_path = file_path
    sprite2d.resource_manager = rm
    sprite2d.texture.offset = rl.Vector2{0, 0}
    sprite2d.texture.h_frames = 1
    sprite2d.texture.v_frames = 1
    sprite2d.texture.flip_h = false
    sprite2d.texture.flip_v = false
    sprite2d.texture.color = color
    sprite2d.current_frame = 0
    sprite2d.initialize = initSprite2D
    sprite2d.draw = drawSprite2D
    return sprite2d
}

initSprite2D :: proc(node : rawptr) {
    sprite2d := cast(^Sprite2D)node
    sprite2d.texture.texture = sprite2d.resource_manager->loadTexture(sprite2d.image_path)
    centerSprite2DOffset(sprite2d)
    sprite2d.texture.org_source_region = rl.Rectangle{0, 0, f32(sprite2d.texture.texture.width), f32(sprite2d.texture.texture.height)}
    sprite2d.texture.source_region = rl.Rectangle{0, 0, f32(sprite2d.texture.texture.width), f32(sprite2d.texture.texture.height)}
}

setSprite2DTexture :: proc(sprite2d: ^Sprite2D, file_path: string) {
    sprite2d.image_path = file_path
    sprite2d.is_initialized = false
}

centerSprite2DOffset :: proc(sprite2d: ^Sprite2D) {
    sprite2d.texture.offset.x = f32(-sprite2d.texture.texture.width ) / f32(sprite2d.texture.h_frames) / 2.0
    sprite2d.texture.offset.y = f32(-sprite2d.texture.texture.height) / f32(sprite2d.texture.v_frames) / 2.0
}

getSourceRect :: proc(sprite2d: ^Sprite2D) -> rl.Rectangle {
    frame_width := sprite2d.texture.org_source_region.width / f32(sprite2d.texture.h_frames)
    if sprite2d.texture.flip_h {
        frame_width = -frame_width
    }

    frame_height := sprite2d.texture.org_source_region.height / f32(sprite2d.texture.v_frames)
    if sprite2d.texture.flip_v {
        frame_height = -frame_height
    }

    frame_x := f32(sprite2d.current_frame % sprite2d.texture.h_frames) * frame_width
    frame_y := f32(sprite2d.current_frame / sprite2d.texture.h_frames) * frame_height

    return rl.Rectangle{frame_x, frame_y, frame_width, frame_height}
}


getDestRect :: proc(sprite2d: ^Sprite2D, source_rect: rl.Rectangle) -> rl.Rectangle {
    return rl.Rectangle{
        sprite2d.transform.global_pos.x + sprite2d.texture.offset.x,
        sprite2d.transform.global_pos.y + sprite2d.texture.offset.y,
        source_rect.width * sprite2d.transform.global_scale.x,
        source_rect.height * sprite2d.transform.global_scale.y,
    }
}

drawSprite2D :: proc(node_ptr: rawptr) {
    sprite2d := cast(^Sprite2D)node_ptr
    source_rect := getSourceRect(sprite2d)
    dest_rect := getDestRect(sprite2d, source_rect)
    rl.DrawTexturePro(
        sprite2d.texture.texture,
        source_rect,
        dest_rect,
        sprite2d.transform.origin,
        sprite2d.transform.rotation,
        sprite2d.texture.color,
    )
}

