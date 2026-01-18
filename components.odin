package main

import rl "vendor:raylib"
import math "core:math"

// draw capsule between two points using rounded rectangle 
drawCapsule :: proc(center_1: rl.Vector2, center_2: rl.Vector2, radius: f32, color: rl.Color) {
    dir := center_2 - center_1
    rect_width := radius * 2
    rect_height := math.abs(rl.Vector2Length(dir))
    rect_roundness := radius
    rect_x := center_1.x - radius
    rect_y := center_1.y - radius
    rl.DrawRectangleRounded(rl.Rectangle{rect_x, rect_y, rect_width, rect_height}, rect_roundness, 16, color)
    
    
}

TransformComponent :: struct {
    position: rl.Vector2,
    global_pos: rl.Vector2,
    scale: rl.Vector2,
    global_scale: rl.Vector2,
    origin: rl.Vector2,
    rotation: f32,
    global_rotation: f32,
}

CharacterMoverComponent :: struct {
    speed: f32,
    max_speed: f32,
    acceleration: f32,
    deceleration: f32,
    gravity: rl.Vector2,
    falling_gravity: rl.Vector2,
    jump_force: f32,
    velocity: rl.Vector2,
    direction: f32,
    on_ground: bool,
    facing_direction: bool,
}


TextureComponent :: struct {
    org_source_region: rl.Rectangle,
    source_region: rl.Rectangle,
    offset: rl.Vector2,
    h_frames: u32,
    v_frames: u32,
    flip_h: bool,
    flip_v: bool,
    texture: rl.Texture2D,
    color: rl.Color,
}

Rectangle2D :: struct {
    size: rl.Vector2,
    color: rl.Color,
}

TimerComponent :: struct {
    duration: f32,
    elapsed: f32,
    repeat: bool,
    active: bool,
}


