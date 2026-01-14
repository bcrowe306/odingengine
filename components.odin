package main

import rl "vendor:raylib"

TransformComponent :: struct {
    position: rl.Vector2,
    global_pos: rl.Vector2,
    scale: rl.Vector2,
    global_scale: rl.Vector2,
    origin: rl.Vector2,
    rotation: f32,
    global_rotation: f32,
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

MoverComponent :: struct {
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
    deceleration: rl.Vector2,
    max_speed: f32,
    gravity_scale: f32,
    jump_force: f32,
    on_ground: bool,
}

TimerComponent :: struct {
    duration: f32,
    elapsed: f32,
    repeat: bool,
    active: bool,
}


