package main

import rl "vendor:raylib"
import "vendor:box2d"



Area2DRect :: struct {
    using node: Node,
    size: rl.Vector2,
    body_id: box2d.BodyId,
    shape_id: box2d.ShapeId,
    filter: box2d.Filter

}

createArea2DRect :: proc(name: string = "Area2DRect", position: rl.Vector2 = rl.Vector2{0,0}, size: rl.Vector2 = rl.Vector2{64,64}) -> ^Area2DRect {
    using box2d
    area := new(Area2DRect)
    setNodeDefaults(cast(^Node)area, name)
    area.transform.position = position
    area.size = size

    bodyDef := DefaultBodyDef()
    bodyDef.type = BodyType.dynamicBody
    bodyDef.position = pixelToMeterVec2(area.transform.position)
    area.body_id = CreateBody(GAME.world_id, bodyDef)

    shapeDef := DefaultShapeDef()
    shapeDef.isSensor = true
    shapeDef.filter = area.filter
    polyg := MakeBox(pixelToMeter(size.x) / 2.0, pixelToMeter(size.y) / 2.0)
    area.shape_id = CreatePolygonShape(area.body_id, shapeDef, polyg)

    return area
}