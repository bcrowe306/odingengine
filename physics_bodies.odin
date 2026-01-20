package main

import "core:c"
import rl "vendor:raylib"
import box2d "vendor:box2d"
import fmt "core:fmt"
import math "core:math"

FilterCategory :: enum u64 {
    StaticBody = 1 << 30,
    Movers = 1 << 31,
    DynamicBody = 1 << 32,
    KinematicBody = 1 << 33,
}


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

getWorldPosition :: proc (pb: ^PhysicsBody) -> rl.Vector2 {
    world_pos := rl.Vector2{0, 0}
    switch v in pb^ {
        case DynamicBody:
            bodyPos := box2d.Body_GetPosition(v.body_id)
            world_pos = rl.Vector2{meterToPixel(bodyPos.x), meterToPixel(bodyPos.y)}
        case KinematicBody:
            bodyPos := box2d.Body_GetPosition(v.body_id)
            world_pos = rl.Vector2{meterToPixel(bodyPos.x), meterToPixel(bodyPos.y)}
        case StaticBody:
            bodyPos := box2d.Body_GetPosition(v.body_id)
            world_pos = rl.Vector2{meterToPixel(bodyPos.x), meterToPixel(bodyPos.y)}
    }
    return world_pos
}

createStaticBody :: proc(world_id: box2d.WorldId, name: string = "StaticBody", position: rl.Vector2 = rl.Vector2{0, 0}, rotation: f32 = 0.0) -> ^StaticBody {
    using box2d
    sb := new(StaticBody)
    setNodeDefaults(cast(^Node)sb, name)
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.staticBody
    bodyDef.rotation = box2d.MakeRot(math.to_radians_f32(rotation))
    sb.transform.position = position
    bodyDef.position = sb.transform.position * METERTOPIXEL_SCALE
    body := CreateBody(world_id, bodyDef)

    
    sb.world_id = world_id
    sb.body_id = body
    return sb
}

addCollisionShape :: proc(pb: ^PhysicsBody, cs: ^CollisionShape) {
    node := cast(^Node)pb
    GAME.node_manager->addChild(node, cast(rawptr)cs)
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
    db.exit_tree = on_rock_exit_tree
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.dynamicBody
    db.transform.position = position
    bodyDef.position = db.transform.position * METERTOPIXEL_SCALE
    body := CreateBody(world_id, bodyDef)
    db.world_id = world_id
    db.body_id = body
    return db
}

on_rock_exit_tree :: proc(rock_ptr: rawptr) {
    rock := cast(^DynamicBody)rock_ptr
    // box2d.DestroyBody(rock.body_id)
    box2d.Body_Disable(rock.body_id)
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


createFloorBody :: proc(world_id: box2d.WorldId, name: string = "FloorBody", position: rl.Vector2 = rl.Vector2{0, 0}, size: rl.Vector2 = rl.Vector2{200, 40}, rotation: f32 = 0.0) {
    floorBody := createStaticBody(GAME.world_id, "FloorBody", position, rotation)
    GAME.node_manager->addNode(cast(rawptr)floorBody)
    floorShape := createRectangleCollisionShape(GAME.world_id, floorBody.body_id, size)
    GAME.node_manager->addNode(cast(rawptr)floorShape)
    addCollisionShape(cast(^PhysicsBody)floorBody, cast(^CollisionShape)floorShape)
    GAME.node_manager->addChild(getRoot(GAME), cast(rawptr)floorBody)
}


createStaticBodyBox2d :: proc(world_id: box2d.WorldId, position: rl.Vector2, size: rl.Vector2, rotation: f32 = 0.0) -> box2d.BodyId {
    using box2d
    act_pos := box2d.Vec2{pixelToMeter(position.x + (size.x / 2.0)), pixelToMeter(position.y + (size.y / 2.0))}
    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.staticBody
    bodyDef.position = act_pos
    bodyDef.rotation = box2d.MakeRot(math.to_radians_f32(rotation))
    body_id := CreateBody(world_id, bodyDef)

    shapeDef := box2d.DefaultShapeDef()
    shapeDef.filter = box2d.Filter{
        categoryBits = u64(FilterCategory.StaticBody),
        maskBits = u64(FilterCategory.Movers) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody),
    }
    shapeDef.isSensor = false
    halfWidth := pixelToMeter(size.x / 2.0)
    halfHeight := pixelToMeter(size.y / 2.0)
    poly := MakeBox(halfWidth, halfHeight)

    shape_id := box2d.CreatePolygonShape(body_id, shapeDef, poly)
    return body_id
}