package main

import rl "vendor:raylib"
import fmt "core:fmt"

Animation :: struct {
    name: string,
    fps: f32,
    repeat: bool,
    start_frame: u32,
    end_frame: u32,
    autoplay_on_load: bool,
    image_path: string,
    texture: TextureComponent,
}

getTotalFrames :: proc(anim: ^Animation) -> u32 {
    total_spritesheet_frames := anim.texture.h_frames * anim.texture.v_frames
    if anim.end_frame >= 0 && anim.end_frame < total_spritesheet_frames && anim.end_frame > anim.start_frame{
        return anim.end_frame - anim.start_frame + 1
    }
    else{
        return total_spritesheet_frames - anim.start_frame
    }
}

AnimatedSprite2D :: struct {
    using node: Node,
    resource_manager: ^ResourceManager,
    animations: map[string]Animation,
    playing: bool,
    elapsed_time: f32,
    speed_scale: f32,
    current_animation: ^Animation,
    current_frame: u32,
    setAnimation: proc(as2d: ^AnimatedSprite2D, name: string),
}

createAnimatedSprite2D :: proc(rm: ^ResourceManager, name: string = "AnimatedSprite2D") -> ^AnimatedSprite2D {
    sprite2d := new(AnimatedSprite2D)
    setNodeDefaults(cast(^Node)sprite2d, name)
    sprite2d.animations = map[string]Animation{}
    sprite2d.resource_manager = rm
    sprite2d.playing = false
    sprite2d.elapsed_time = 0.0
    sprite2d.speed_scale = 1.0
    sprite2d.initialize = initAnimatedSprite2D
    sprite2d.draw = drawAnimatedSprite2D
    sprite2d.setAnimation = setAnimatedSprite2DAnimation
    return sprite2d
}

createAnimation :: proc(as2d: ^AnimatedSprite2D, name: string, file_path: string, h_frames: u32 = 1, v_frames: u32 = 1, fps: f32 = 12.0, repeat: bool = true, autoplay_on_load: bool = true) {
    anim := Animation{}
    anim.name = name
    anim.image_path = file_path
    anim.fps = fps
    anim.repeat = repeat
    anim.start_frame = 0
    anim.end_frame = h_frames * v_frames - 1
    anim.autoplay_on_load = autoplay_on_load
    anim.texture.h_frames = h_frames
    anim.texture.v_frames = v_frames
    anim.texture.color = rl.WHITE
    as2d.animations[name] = anim
    if autoplay_on_load {
        as2d.current_animation = &as2d.animations[name]
        as2d.playing = true
    }
    as2d.process = processAnimatedSprite2D
}

setAnimatedSprite2DAnimation :: proc(as2d: ^AnimatedSprite2D, name: string) {
    if as2d.current_animation != nil && as2d.current_animation.name == name {
        return
    }
    if anim, exists := &as2d.animations[name]; exists {
        as2d.current_animation = anim
        as2d.current_frame = anim.start_frame
        as2d.elapsed_time = 0.0
        as2d.playing = true
    }
    else {
        fmt.printfln("Animation '%s' not found in AnimatedSprite2D '%s'", name, as2d.name)
    }
}

initAnimatedSprite2D :: proc(node : rawptr) {
    as2d := cast(^AnimatedSprite2D)node
    for anim_name, &anim in as2d.animations {
        anim.texture.texture = as2d.resource_manager->loadTexture(anim.image_path)
        anim.texture.org_source_region = rl.Rectangle{0, 0, f32(anim.texture.texture.width), f32(anim.texture.texture.height)}
        anim.texture.source_region = rl.Rectangle{0, 0, f32(anim.texture.texture.width), f32(anim.texture.texture.height)}
        centerAnimatedSprite2DOffset(&anim)
    }
}

centerAnimatedSprite2DOffset :: proc(animation: ^Animation) {
    animation.texture.offset.x = f32(-animation.texture.texture.width ) / f32(animation.texture.h_frames) / 2.0
    animation.texture.offset.y = f32(-animation.texture.texture.height) / f32(animation.texture.v_frames) / 2.0
}

getFlipH :: proc(as2d: ^AnimatedSprite2D) -> bool {
    if as2d.current_animation != nil {
        return as2d.current_animation.texture.flip_h
    }
    return false
}

setFlipH :: proc(as2d: ^AnimatedSprite2D, flip: bool) {
    if as2d.current_animation != nil {
        as2d.current_animation.texture.flip_h = flip
    }
}

getFlipV :: proc(as2d: ^AnimatedSprite2D) -> bool {
    if as2d.current_animation != nil {
        return as2d.current_animation.texture.flip_v
    }
    return false
}

setFlipV :: proc(as2d: ^AnimatedSprite2D, flip: bool) {
    if as2d.current_animation != nil {
        as2d.current_animation.texture.flip_v = flip
    }
}

getA2DSourceRect :: proc(as2d: ^AnimatedSprite2D) -> rl.Rectangle {
    animation := as2d.current_animation
    frame_width := animation.texture.org_source_region.width / f32(animation.texture.h_frames)
    if animation.texture.flip_h {
        frame_width = -frame_width
    }

    frame_height := animation.texture.org_source_region.height / f32(animation.texture.v_frames)

    if animation.texture.flip_v {
        frame_height = -frame_height
    }

    frame_x := f32(as2d.current_frame % animation.texture.h_frames) * frame_width
    frame_y := f32(as2d.current_frame / animation.texture.h_frames) * frame_height

    return rl.Rectangle{frame_x, frame_y, frame_width, frame_height}
}

getAnimatedSpriteDestRect :: proc(as2d: ^AnimatedSprite2D, source_rect: rl.Rectangle) -> rl.Rectangle {
    anim := as2d.current_animation
    return rl.Rectangle{
        as2d.transform.global_pos.x + anim.texture.offset.x,
        as2d.transform.global_pos.y + anim.texture.offset.y,
        source_rect.width * as2d.transform.global_scale.x,
        source_rect.height * as2d.transform.global_scale.y,
    }
}

drawAnimatedSprite2D :: proc(node_ptr: rawptr) {
    as2d := cast(^AnimatedSprite2D)node_ptr
    source_rect := getA2DSourceRect(as2d)
    dest_rect := getAnimatedSpriteDestRect(as2d, source_rect)
    rl.DrawTexturePro(
        as2d.current_animation.texture.texture,
        source_rect,
        dest_rect,
        as2d.transform.origin,
        as2d.transform.rotation,
        as2d.current_animation.texture.color,
    )
}

processAnimatedSprite2D :: proc(as2d_ptr: rawptr, delta: f32) {
    as2d := cast(^AnimatedSprite2D)as2d_ptr
    if as2d.playing && as2d.current_animation != nil {
        as2d.elapsed_time += delta
        frame_duration := 1.0 / as2d.current_animation.fps / as2d.speed_scale
        total_frames := getTotalFrames(as2d.current_animation)
        if as2d.elapsed_time >= frame_duration {
            as2d.current_frame += 1
            as2d.elapsed_time = 0.0
            if as2d.current_frame >= total_frames {
                if as2d.current_animation.repeat {
                    as2d.current_frame = as2d.current_animation.start_frame
                } else {
                    as2d.current_frame = total_frames - 1
                    as2d.playing = false
                }
            }
        }
    }
    
}
