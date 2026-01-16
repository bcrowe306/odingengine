package main

import "core:c"
import rl "vendor:raylib"
import box2d "vendor:box2d"
import fmt "core:fmt"
import math "core:math"

CollisionShape :: union {
    RectangleCollisionShape,
    CircleCollisionShape,
}


RectangleCollisionShape :: struct {
    using node: Node,
    world_id: box2d.WorldId,
    body_id: box2d.BodyId,
    shape_id: box2d.ShapeId,
    size: rl.Vector2,
    color: rl.Color,
    definition: box2d.ShapeDef,
  
}

createRectangleCollisionShape :: proc(world_id: box2d.WorldId, body_id: box2d.BodyId, size: rl.Vector2, color: rl.Color = rl.BLUE) -> ^RectangleCollisionShape {
    using box2d
    shapeDef := DefaultShapeDef()
    shapeDef.isSensor = false
    polygon := MakeBox(pixelToMeter(size.x) / 2.0, pixelToMeter(size.y) / 2.0)
    cs := new(RectangleCollisionShape)
    setNodeDefaults(cast(^Node)cs, "RectangleCollisionShape")
    cs.world_id = world_id
    cs.body_id = body_id
    cs.shape_id = CreatePolygonShape(body_id, shapeDef, polygon)
    cs.size = size
    cs.color = color
    cs.definition = shapeDef
    cs.draw = drawRectangleCollisionShape
    return cs
}

drawRectangleCollisionShape :: proc(cs_ptr: rawptr) {
    cs := cast(^RectangleCollisionShape)cs_ptr
    polygon := box2d.Shape_GetPolygon(cs.shape_id)
    for vert, index in 0..<polygon.count {
        p1 := box2d.Body_GetWorldPoint(cs.body_id, polygon.vertices[index])
        p2 := box2d.Body_GetWorldPoint(cs.body_id, polygon.vertices[i32(index + 1) % polygon.count])
        rl.DrawText(fmt.ctprintf("World points: (%.2f, %.2f)", meterToPixel(p1.x), meterToPixel(p1.y)), 500, 10 + i32(index) * 20, 10, rl.WHITE)
        rl.DrawLineV(rl.Vector2{meterToPixel(p1.x), meterToPixel(p1.y)}, rl.Vector2{meterToPixel(p2.x), meterToPixel(p2.y)}, cs.color)
    }
            
}

CircleCollisionShape :: struct {
    using node: Node,
    world_id: box2d.WorldId,
    body_id: box2d.BodyId,
    shape_id: box2d.ShapeId,
    radius: f32,
    color: rl.Color,
    definition: box2d.ShapeDef,
}
createCircleCollisionShape :: proc(world_id: box2d.WorldId, body_id: box2d.BodyId, radius: f32, color: rl.Color = rl.RED) -> ^CircleCollisionShape {
    using box2d
    shapeDef := DefaultShapeDef()
    shapeDef.isSensor = false
    circle := box2d.Circle{ radius = pixelToMeter(radius), center = box2d.Vec2{0,0} }
    cs := new(CircleCollisionShape)
    setNodeDefaults(cast(^Node)cs, "CircleCollisionShape")
    cs.world_id = world_id
    cs.body_id = body_id
    cs.shape_id = CreateCircleShape(body_id, shapeDef, circle)
    cs.radius = radius
    cs.color = color
    cs.definition = shapeDef
    cs.draw = drawCircleCollisionShape
    return cs
}


drawCircleCollisionShape :: proc(cs_ptr: rawptr) {
    cs := cast(^CircleCollisionShape)cs_ptr
    position := box2d.Body_GetPosition(cs.body_id)
    rl.DrawCircleV(rl.Vector2{meterToPixel(position.x), meterToPixel(position.y)}, cs.radius, cs.color)
}