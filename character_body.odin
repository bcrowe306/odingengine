package main

import rl "vendor:raylib"
import box2d "vendor:box2d"
import math "core:math"
import fmt "core:fmt"
import runtime "base:runtime"


CHARACTER_MOVER_PLANE_CAPACITY : int : 8

CharacterBody :: struct {
    using node: Node,
    ch_transform: box2d.Transform,
    max_speed: f32,
    min_speed: f32,
    stop_speed: f32,
    jump_force: f32,
    velocity: rl.Vector2,
    facing_direction: bool,
    is_on_ground: bool,
    friendly_shape_max_push: f32,
    friendly_shape_clip_velocity: bool,
    capsule: box2d.Capsule,
    gravity: f32,
    downward_gravity: f32,
    friction: f32,
    acceleration: f32,
    air_steer: f32,
    plane_count: int,
    time: f32,
    total_iterations: int,
    collide_filter: box2d.QueryFilter,
    cast_filter: box2d.QueryFilter,
    raycast_length: f32,
    planes: []box2d.CollisionPlane,
}

createCharacterBody :: proc(name: string = "CharacterBody", position: rl.Vector2 = rl.Vector2{0.0, 0.0}, radius: f32 = 0.5, height: f32 = 1.8) -> ^CharacterBody {
    character := new(CharacterBody)
    setNodeDefaults(cast(^Node)character, name)
    character.transform.position = position
    character.ch_transform = {{pixelToMeter(position.x), pixelToMeter(position.y)}, box2d.Rot_identity}
    character.type = NodeType.CharacterBody
    character.max_speed = 14.0
    character.min_speed = 0.1
    character.stop_speed = 3.0
    character.jump_force = 16.0
    character.gravity = 40.0 // Gravity in m/s^2
    character.downward_gravity = 60.0 // Increased gravity when falling
    character.friction = 8.0
    character.velocity = rl.Vector2{0.0, 0.0}
    character.facing_direction = true
    character.acceleration = 12.0
    character.air_steer = 1.0
    character.is_on_ground = true
    character.planes = make([]box2d.CollisionPlane, CHARACTER_MOVER_PLANE_CAPACITY)
    character.collide_filter = { u64(FilterCategory.Movers),  u64(FilterCategory.StaticBody) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody) };
    character.cast_filter = { u64(FilterCategory.Movers),  u64(FilterCategory.StaticBody) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody) };
    character.debug = false

    
    // Define capsule shape in meter units
    character.capsule.center1 = box2d.Vec2{0.0, height / 2.0}
    character.capsule.center2 = box2d.Vec2{0.0, -height / 2.0}
    character.capsule.radius = radius
    
    character.friendly_shape_clip_velocity = false
    character.friendly_shape_max_push = 0.025


    // Set up character mover methods
    character.process = characterBodyProcess
    character.draw = characterMover2Draw
	
    return character

}


characterMover2Draw :: proc(node_ptr: rawptr) {
    using box2d
    character := cast(^CharacterBody)node_ptr
    if !character.debug {
        return
    }
    // Draw character representation (for debugging)
    capsuleShape := character.capsule
    body_position := character.ch_transform.p
    top_point := (body_position + capsuleShape.center1) * PIXELTOMETER_SCALE
    bottom_point := (body_position + capsuleShape.center2) * PIXELTOMETER_SCALE
    radius := capsuleShape.radius * PIXELTOMETER_SCALE
    rl.DrawCircleV(top_point, radius, rl.Fade(rl.BLUE, 0.5))
    rl.DrawCircleV(bottom_point, radius, rl.Fade(rl.BLUE, 0.5))

    // Debug drawing raycast
    rayLength :f32 = character.capsule.center1.y - character.capsule.center2.y + character.capsule.radius + character.raycast_length
    origin :Vec2 = TransformPoint( character.ch_transform, character.capsule.center2 )
    ray_start_point := Vec2{meterToPixel(origin.x), meterToPixel(origin.y)}
    ray_endpoint := Vec2{meterToPixel(origin.x), meterToPixel(origin.y + rayLength)}
    rl.DrawCircleV({meterToPixel(origin.x), meterToPixel(origin.y)}, 5.0, rl.RED)
    rl.DrawLineV(ray_start_point, ray_endpoint, rl.GREEN)
    
    rl.DrawText(fmt.ctprintf("Vel X: %f, Vel Y: %f", character.velocity.x, character.velocity.y), 500, 170, 15, rl.RED)
    
}

characterBodyProcess :: proc(node_ptr: rawptr, delta: f32) {
    character := cast(^CharacterBody)node_ptr

    // Process input for movement
    input_direction :f32 = 0.0
    if rl.IsKeyDown(rl.KeyboardKey.A) {
        character.facing_direction = false
        input_direction -= 1.0
    }
    if rl.IsKeyDown(rl.KeyboardKey.D) {
        character.facing_direction = true
        input_direction += 1.0
    }

    // Jumping logic
    if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
        character.velocity.y = -character.jump_force
        character.is_on_ground = false
    }
    using box2d
    speed := Length(character.velocity)

    if speed < character.min_speed {
        character.velocity.x = 0
    }
    else if character.is_on_ground {

        // Linear damping above stopSpeed and fixed reduction below stopSpeed
        control: f32 = speed
        if speed < character.stop_speed {
            control = character.stop_speed
        } 

        // friction has units of 1/time
        drop: f32 = control * character.friction * delta
        newSpeed :f32 = max(0.0, speed - drop)
        character.velocity.x *= newSpeed / speed
    }

    desiredVelocity: Vec2 = { character.max_speed * input_direction, 0.0 }
    desiredSpeed, desiredDirection := GetLengthAndNormalize(desiredVelocity )

    if ( desiredSpeed > character.max_speed )
    {
        desiredSpeed = character.max_speed;
    }

    if ( character.is_on_ground )
    {
        character.velocity.y = 0.0
    }

    // Accelerate
    currentSpeed := box2d.Dot( character.velocity, desiredDirection );
    addSpeed := desiredSpeed - currentSpeed;
    if ( addSpeed > 0.0 )
    {
        steer :f32 = character.air_steer
        if ( character.is_on_ground )
        {
            steer = 1.0
        }

        accelSpeed :f32 = steer * character.acceleration * character.max_speed * delta;
        if ( accelSpeed > addSpeed )
        {
            accelSpeed = addSpeed
        }

        character.velocity += accelSpeed * desiredDirection
    }

    // Apply gravity

    if character.is_on_ground == false {
        if character.velocity.y >= 0.0 {
            // Falling
            character.velocity.y += character.downward_gravity * delta
        } else {
            // Rising
            character.velocity.y += character.gravity * delta
        }
    }
    

    solveCharacterOnGround(character)
    target: Vec2 = character.ch_transform.p + delta * character.velocity
    moveAndCollide(character, target, delta)
    character.transform.position = rl.Vector2{meterToPixel(character.ch_transform.p.x), meterToPixel(character.ch_transform.p.y)}
    character.transform.rotation = math.to_degrees_f32(box2d.Rot_GetAngle(character.ch_transform.q))

}

defaultCharacterBodyProcess :: proc(node_ptr: rawptr, delta: f32) {
    character := cast(^CharacterBody)node_ptr

    // Process input for movement
    input_direction :f32 = 0.0
    if rl.IsKeyDown(rl.KeyboardKey.A) {
        input_direction -= 1.0
    }
    if rl.IsKeyDown(rl.KeyboardKey.D) {
        input_direction += 1.0
    }

    // Jumping logic
    if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
        character.velocity.y = -character.jump_force
        character.is_on_ground = false
    }
    using box2d
    speed := Length(character.velocity)

    if speed < character.min_speed {
        character.velocity.x = 0
    }
    else if character.is_on_ground {

        // Linear damping above stopSpeed and fixed reduction below stopSpeed
        control: f32 = speed
        if speed < character.stop_speed {
            control = character.stop_speed
        } 

        // friction has units of 1/time
        drop: f32 = control * character.friction * delta
        newSpeed :f32 = max(0.0, speed - drop)
        character.velocity.x *= newSpeed / speed
    }

    desiredVelocity: Vec2 = { character.max_speed * input_direction, 0.0 }
    desiredSpeed, desiredDirection := GetLengthAndNormalize(desiredVelocity )

    if ( desiredSpeed > character.max_speed )
    {
        desiredSpeed = character.max_speed;
    }

    if ( character.is_on_ground )
    {
        character.velocity.y = 0.0
    }

    // Accelerate
    currentSpeed := box2d.Dot( character.velocity, desiredDirection );
    addSpeed := desiredSpeed - currentSpeed;
    if ( addSpeed > 0.0 )
    {
        steer :f32 = character.air_steer
        if ( character.is_on_ground )
        {
            steer = 1.0
        }

        accelSpeed :f32 = steer * character.acceleration * character.max_speed * delta;
        if ( accelSpeed > addSpeed )
        {
            accelSpeed = addSpeed
        }

        character.velocity += accelSpeed * desiredDirection
    }

    // Apply gravity

    if character.velocity.y >= 0.0 {
        // Falling
        character.velocity.y += character.downward_gravity * delta
    } else {
        // Rising
        character.velocity.y += character.gravity * delta
    }

    solveCharacterOnGround(character)
    target: Vec2 = character.ch_transform.p + delta * character.velocity
    moveAndCollide(character, target, delta)
    character.transform.position = rl.Vector2{meterToPixel(character.ch_transform.p.x), meterToPixel(character.ch_transform.p.y)}
    character.transform.rotation = math.to_degrees_f32(box2d.Rot_GetAngle(character.ch_transform.q))
}


solveCharacterOnGround :: proc (character: ^CharacterBody) {

    using box2d
    // Figure out if on ground
    rayLength :f32 = character.capsule.center1.y - character.capsule.center2.y + character.capsule.radius + character.raycast_length
    origin :Vec2 = TransformPoint( character.ch_transform, character.capsule.center2 )
    circle :Circle = { origin, 0.5 *character.capsule.radius }
    segmentOffset :Vec2 = { 0.75 * character.capsule.radius, 0.0 }
    segment :Segment = {
        point1 = origin - segmentOffset,
        point2 = origin + segmentOffset,
    };

    proxy: ShapeProxy
    translation: Vec2 
    pogoFilter :QueryFilter = { u64(FilterCategory.Movers),  u64(FilterCategory.StaticBody) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody) };
    castResult :CastResult

    proxy = MakeProxy( {segment.point1}, 0.0 )
	translation = { 0.0, +rayLength }

    treeStats := World_CastShape( GAME.world_id, proxy, translation, pogoFilter, castCallback, &castResult )

    // Avoid snapping to ground if still going up
    if ( character.is_on_ground == false )
    {
        character.is_on_ground = castResult.hit && character.velocity.y >= 0.0;
    }
    else
    {
        character.is_on_ground = castResult.hit;
    }

    
}


planeResultFcn :: proc "c" (shapeId: box2d.ShapeId, planeResult: ^box2d.PlaneResult, ctx: rawptr) -> bool {
        self := cast(^CharacterBody)ctx
        context = runtime.default_context() 
		assert( planeResult.hit == true );

		maxPush: f32 = math.F32_MAX
		clipVelocity := true
		

		if ( self.plane_count < CHARACTER_MOVER_PLANE_CAPACITY )
		{
			// assert( box2d.IsValidPlane( planeResult.plane ) )
            if box2d.IsValidPlane( planeResult.plane ) {
                self.planes[self.plane_count] = {planeResult.plane, maxPush, 0.0, clipVelocity}
			    self.plane_count += 1
            }
            
		}

		return true
	}




moveAndCollide :: proc (character: ^CharacterBody, target: box2d.Vec2, delta: f32) {
    
    using box2d

    character.total_iterations = 0
    tolerance :f32= 0.01

    for iteration in 0..<5 {
        character.plane_count = 0

        mover: Capsule

        mover.center1 = TransformPoint( character.ch_transform, character.capsule.center1 )
        mover.center2 = TransformPoint( character.ch_transform, character.capsule.center2 )
        mover.radius = character.capsule.radius

        box2d.World_CollideMover( GAME.world_id, mover, character.collide_filter, planeResultFcn, character )
        result := SolvePlanes( target - character.ch_transform.p, character.planes );

        character.total_iterations += int(result.iterationCount)

        fraction := box2d.World_CastMover( GAME.world_id, mover, result.position, character.cast_filter );

        delta_ :Vec2 = fraction * result.position;
        character.ch_transform.p += delta_;

        if ( LengthSquared( delta_ ) < tolerance * tolerance )
        {
            break;
        }
    }
    
    if character.plane_count > 0 {
        // Adjust velocity based on planes
        planes := character.planes[0:character.plane_count]
        character.velocity = ClipVector( character.velocity, planes);
    }
}
