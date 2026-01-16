package main

import rl "vendor:raylib"
import fmt "core:fmt"

CharacterMover :: struct {
    using node: Node,
    physics: CharacterMoverComponent,
}

createCharacterMover :: proc(name: string = "CharacterMover") -> ^CharacterMover {
    cm := new(CharacterMover)
    setNodeDefaults(cast(^Node)cm, name)
    cm.type = NodeType.CharacterMover
    cm.physics = CharacterMoverComponent{
        speed = 200.0,
        max_speed = 500.0,
        acceleration = 2000.0,
        deceleration = 2000.0,
        gravity = rl.Vector2{0.0, 980.0},
        falling_gravity = rl.Vector2{0.0, 1500.0},
        jump_force = 550.0,
        velocity = rl.Vector2{0.0, 0.0},
    }
    cm.process = processCharacterMover
    return cm
}

determineFacingDirection :: proc(cm: ^CharacterMover) {
    if cm.physics.direction > 0.0 {
        cm.physics.facing_direction = true
    } else if cm.physics.direction < 0.0 {
        cm.physics.facing_direction = false
    }
    as2d := cast(^AnimatedSprite2D)cm.getNode(cm, "./BoarWarrior")
    if as2d != nil {
        setFlipH(as2d, cm.physics.facing_direction)
    }
}

processCharacterMover :: proc(cm_ptr: rawptr, delta: f32) {
    cm := cast(^CharacterMover)cm_ptr
    if !cm.enabled {
        return
    }

    cm.physics.direction = GAME.actions_manager->getAxis(
        GAME.actions_manager.actions["DIR_RIGHT"]->down_value(),
        GAME.actions_manager.actions["DIR_LEFT"]->down_value()
    )

    if cm.physics.direction != 0.0 {
        determineFacingDirection(cm)
        cm.physics.velocity.x += cm.physics.direction * cm.physics.acceleration * delta

    }
    else {
        // Deceleration
        if cm.physics.velocity.x > 0.0 {
            cm.physics.velocity.x -= cm.physics.deceleration * delta
            if cm.physics.velocity.x < 0.0 {
                cm.physics.velocity.x = 0.0
            }
        } else if cm.physics.velocity.x < 0.0 {
            cm.physics.velocity.x += cm.physics.deceleration * delta
            if cm.physics.velocity.x > 0.0 {
                cm.physics.velocity.x = 0.0
            }
        }
    }


    // Clamp horizontal speed
    if cm.physics.velocity.x > cm.physics.max_speed {
        cm.physics.velocity.x = cm.physics.max_speed
    } else if cm.physics.velocity.x < -cm.physics.max_speed {
        cm.physics.velocity.x = -cm.physics.max_speed
    }

    // Apply gravity
    if cm.physics.velocity.y >= 0.0 {
        cm.physics.velocity.y += cm.physics.gravity.y * delta
    } else {
        cm.physics.velocity.y += cm.physics.falling_gravity.y * delta

    }

    // Jumping
    if GAME.actions_manager->getAction("ACTION_JUMP")->pressed() && isOnGround(cm) {
        cm.physics.velocity.y = -cm.physics.jump_force
    }

    // Update position
    cm.transform.position.x += cm.physics.velocity.x * delta
    cm.transform.position.y += cm.physics.velocity.y * delta

    // Ground collision  On floor logic
    if isOnGround(cm) {
        cm.physics.velocity.y = 0.0
        cm.transform.position.y = GAME.window_size.y - 100.0 // Assuming ground is at y = GAME.window_size.y - 100
    }

}

isOnGround :: proc(cm: ^CharacterMover) -> bool {
    return cm.transform.position.y >= GAME.window_size.y - 100.0 // Assuming ground is at y = GAME.window_size.y - 100
}