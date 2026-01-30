package main 

import "core:c"
import rl "vendor:raylib"
import math "core:math"

CameraNode :: struct {
    using node: Node,
    camera2d: ^rl.Camera2D,
    limits: rl.Vector4, // x: minX, y: minY, z: maxX, w: maxY

}

createCameraNode :: proc(name: string, target: rl.Vector2 = rl.Vector2{0, 0}, offset: rl.Vector2 = rl.Vector2{0, 0}, zoom: f32 = 1.0, rotation: f32 = 0.0, limits: rl.Vector4 = rl.Vector4{-math.F32_MAX, -math.F32_MAX, math.F32_MAX, math.F32_MAX}) -> ^CameraNode {
    cam_node := new(CameraNode)
    setNodeDefaults(cast(^Node)cam_node, name)
    cam_node.camera2d = new(rl.Camera2D)
    cam_node.type = .CameraNode
    if rl.Vector2Equals(offset, rl.Vector2{0, 0}) {
        cam_node.camera2d.offset = rl.Vector2{GAME.window_size.x / 2, GAME.window_size.y / 2}
    }
    else {
        cam_node.camera2d.offset = offset
    }
    cam_node.camera2d.zoom = zoom
    cam_node.camera2d.rotation = rotation
    cam_node.limits = limits
    GAME.camera = cam_node.camera2d
    cam_node.process = updateCameraNode

    return cam_node
}


updateCameraNode :: proc(camera_node__ptr: rawptr, delta: f32) {
    // Smoothly interpolate zoom towards target zoom
    camera_node := cast(^CameraNode)camera_node__ptr
    

    // Update camera target position if needed (e.g., follow a player)
    // For now, we keep it static

    // Update camera transform

    camera_node.camera2d.target = camera_node.transform.global_pos
    camera_node.camera2d.target.x = clamp(
        camera_node.camera2d.target.x,
        camera_node.limits.x + (GAME.window_size.x / 2) * camera_node.camera2d.zoom,
        camera_node.limits.z - (GAME.window_size.x / 2) * camera_node.camera2d.zoom
    )
    camera_node.camera2d.target.x = clamp(
        camera_node.camera2d.target.x,
        camera_node.limits[0],
        camera_node.limits[2]
    )
    camera_node.camera2d.target.y = clamp(
        camera_node.camera2d.target.y,
        camera_node.limits[1],
        camera_node.limits[3]
    )
}