package main

import "core:crypto/blake2b"
import "vendor:box2d"
import rl "vendor:raylib"
import fmt "core:fmt"



createRock :: proc(position: rl.Vector2, color: rl.Color)  {
    using GAME
    newBody := createDynamicBody(GAME.world_id, "RockBody", rl.GetMousePosition())
    box2d.Body_ApplyForceToCenter(newBody.body_id, box2d.Vec2{3000.0, 0}, true)
    newBody.process = rockProcess
    node_manager->addNode(cast(rawptr)newBody)
    node_manager->addChild(getRoot(GAME), cast(rawptr)newBody)
    newShape := createCircleCollisionShape(GAME.world_id, newBody.body_id, 10.0, color)
    node_manager->addNode(cast(rawptr)newShape)
    addCollisionShape(cast(^PhysicsBody)newBody, cast(^CollisionShape)newShape)
}


rockProcess :: proc(rock_ptr: rawptr, delta: f32) {
    rock := cast(^DynamicBody)rock_ptr
    world_pos := box2d.Body_GetPosition(rock.body_id) * PIXELTOMETER_SCALE
    if world_pos.y > 800.0 {
        rock.nodeManager->removeNode(cast(rawptr)rock)
    }
}