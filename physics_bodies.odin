package main

import "core:c"
import rl "vendor:raylib"
import box2d "vendor:box2d"
import fmt "core:fmt"
import math "core:math"

PhysicsBody :: union {
    DynamicBody,
    KinematicBody,
    StaticBody,
}

StaticBody :: struct {
    using node: Node,
    world_id: box2d.WorldId,
    body_id: box2d.BodyId,
}

createStaticBody :: proc(world_id: box2d.WorldId, name: string = "StaticBody", position: rl.Vector2 = rl.Vector2{0, 0}) -> ^StaticBody {
    using box2d
    sb := new(StaticBody)
    setNodeDefaults(cast(^Node)sb, name)
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.staticBody
    sb.transform.position = position
    bodyDef.position = sb.transform.position * METERTOPIXEL_SCALE
    body := CreateBody(world_id, bodyDef)

    
    sb.world_id = world_id
    sb.body_id = body
    return sb
}

addCollisionShape :: proc(pb: ^PhysicsBody, cs: ^CollisionShape) {
    node := cast(^Node)pb
    addChildNode(node, cast(^Node)cs)
}


DynamicBody :: struct {
    using node: Node,
    world_id: box2d.WorldId,
    body_id: box2d.BodyId,
}

createDynamicBody :: proc(world_id: box2d.WorldId, name: string = "DynamicBody", position: rl.Vector2 = rl.Vector2{0, 0}) -> ^DynamicBody {
    using box2d
    db := new(DynamicBody)
    setNodeDefaults(cast(^Node)db, name)
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.dynamicBody
    db.transform.position = position
    bodyDef.position = db.transform.position * METERTOPIXEL_SCALE
    body := CreateBody(world_id, bodyDef)
    db.world_id = world_id
    db.body_id = body
    return db
}


KinematicBody :: struct {
    using node: Node,
    world_id: box2d.WorldId,
    body_id: box2d.BodyId,
}
createKinematicBody :: proc(world_id: box2d.WorldId, name: string = "KinematicBody") -> ^KinematicBody {
    using box2d
    kb := new(KinematicBody)
    setNodeDefaults(cast(^Node)kb, name)
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.kinematicBody
    bodyDef.position = kb.transform.position * PIXELTOMETER_SCALE
    body := CreateBody(world_id, bodyDef)
    kb.world_id = world_id
    kb.body_id = body
    return kb
}