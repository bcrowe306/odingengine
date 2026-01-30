package main

import rl "vendor:raylib"
import "vendor:box2d"
import fmt "core:fmt"
import runtime "base:runtime"


Raycast2D :: struct {
    using node: Node,
    origin: box2d.Vec2,
    translation: box2d.Vec2,
    filter: box2d.QueryFilter,
    hit: bool,
    on_hit: Signal(CastResult),
}

createRaycast2D :: proc(name: string = "Raycast2D", position: rl.Vector2, translation: rl.Vector2) -> ^Raycast2D {
    rc := new(Raycast2D)
    setNodeDefaults(cast(^Node)rc, name)
    rc.transform.position = position
    rc.origin = pixelToMeterVec2(rc.transform.position)
    rc.translation = pixelToMeterVec2(translation)
    rc.filter = box2d.DefaultQueryFilter()
    rc.hit = false
    rc.process = raycastProcess
    rc.draw = drawRaycast
    return rc
}

raycastProcess :: proc(node_ptr: rawptr, delta: f32) {
    rc := cast(^Raycast2D)node_ptr
    using box2d
    world_id := GAME.world_id
    rc.hit = false
    cr: CastResult
    start_point := getRayCastStartPoint(rc)
    treeStats := box2d.World_CastRay(world_id, start_point, rc.translation, rc.filter, castCallback, &cr)

    if cr.hit {
        if rc.hit == false {
            signalEmit(&rc.on_hit, cr)
        }
        rc.hit = true
    }
}

getRayCastStartPoint :: proc (rc: ^Raycast2D) -> box2d.Vec2 {
    return pixelToMeterVec2(rc.transform.global_pos) + rc.origin
}

getRayCastEndPoint :: proc (rc: ^Raycast2D) -> box2d.Vec2 {
    return getRayCastStartPoint(rc) + rc.translation
}

drawRaycast :: proc (node_ptr: rawptr) {
    rc := cast(^Raycast2D)node_ptr
    if rc.debug == false {
        return
    }

    start_pos :=  meterToPixelVec2(getRayCastStartPoint(rc))
    end_pos := meterToPixelVec2(getRayCastEndPoint(rc))
    line_color := rl.YELLOW
    if rc.hit {
        line_color = rl.RED
    }
    rl.DrawCircleV(start_pos, 3.0, rl.RED)
    rl.DrawCircleV(end_pos, 3.0, rl.GREEN)
    rl.DrawLineV(start_pos, end_pos, line_color)
}



 castCallback :: proc "c" ( shapeId: box2d.ShapeId, point: box2d.Vec2, normal: box2d.Vec2, fraction: f32, ctx: rawptr ) -> f32 {
    context = runtime.default_context()
    result := cast(^CastResult)ctx
	result.point = point
	result.normal = normal
	result.bodyId = box2d.Shape_GetBody( shapeId )
	result.fraction = fraction
	result.hit = true
	return fraction
}

CastResult :: struct {
    point: box2d.Vec2,
	normal: box2d.Vec2,
	bodyId: box2d.BodyId,
	fraction: f32,
	hit: bool,
};