package main

import "core:c"
import "core:crypto/_aes/hw_intel"
import "core:slice"
import fmt "core:fmt"
import rl "vendor:raylib"
import sort "core:sort"
import hash "core:hash"
import bytes "core:bytes"



TransformComponent :: struct {
    position: rl.Vector2,
    global_pos: rl.Vector2,
    scale: rl.Vector2,
    origin: rl.Vector2,
    rotation: f32,
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


