package main

import "base:runtime"
import "core:c"
import "vendor:box2d"
import "core:math/rand"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:mem"
import "core:math"


// TODO: Camera2D Node implementation
// TODO: Implement parallax backgrounds
// TODO: Implement game states (menu, pause, gameplay, etc.)
// TODO: Add more node types (ParticleSystem, Light2D, etc.)
// TODO: StateMachine 
// TODO: Add UI nodes to system (buttons, panels, etc.)

// Create the main game object as a global variable
GAME := createGameObject("Oding Engine Test Game", target_fps=120)
TRACK: mem.Tracking_Allocator

testNode :: proc(name: string = "TestNode") -> ^Node {
    test_node := createNode(name)
    test_node.initialize = proc(node_ptr: rawptr) {
        node := cast(^Node)node_ptr
        fmt.println("Initializing node: ", node.name)
    }
    test_node.enter_tree = proc(node: rawptr) {
        n := cast(^Node)node
        fmt.println("Entering tree: ", n.name)
    }
    test_node.ready = proc(node_ptr: rawptr) {
        node := cast(^Node)node_ptr
        fmt.println("Node ready: ", node.name)
    }
    test_node.process = proc(node_ptr: rawptr, delta: f32) {
        node := cast(^Node)node_ptr
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            fmt.println("Space key pressed! Removing node: ", node.name)
            node.nodeManager->removeNode(cast(rawptr)node)
        }
    }
    test_node.draw = proc(node_ptr: rawptr) {
        node := cast(^Node)node_ptr
    }
    test_node.exit_tree = proc(node_ptr: rawptr) {
        node := cast(^Node)node_ptr
        fmt.println("Exiting tree for node: ", node.name)
    }
    return test_node

}

// In meter units
CapsuleShape :: struct {
    top_point: box2d.Vec2,
    bottom_point: box2d.Vec2,
    radius: f32,
}

CHARACTER_MOVER_PLANE_CAPACITY : int : 8

CharacterMover2 :: struct {
    using node: Node,
    ch_transform: box2d.Transform,
    max_speed: f32,
    min_speed: f32,
    stop_speed: f32,
    jump_force: f32,
    velocity: rl.Vector2,
    is_on_ground: bool,
    friendly_shape_max_push: f32,
    friendly_shape_clip_velocity: bool,
    capsule: box2d.Capsule,
    gravity: f32,
    friction: f32,
    acceleration: f32,
    air_steer: f32,
    plane_count: int,
    time: f32,
    total_iterations: int,
    planes: []box2d.CollisionPlane,
}

createCharacterMover2 :: proc(name: string = "CharacterMover2", position: rl.Vector2 = rl.Vector2{0.0, 0.0}) -> ^CharacterMover2 {
    character := new(CharacterMover2)
    setNodeDefaults(cast(^Node)character, name)
    character.transform.position = position
    character.ch_transform = {{pixelToMeter(position.x), pixelToMeter(position.y)}, box2d.Rot_identity}
    character.type = NodeType.CharacterMover
    character.max_speed = 6.0
    character.min_speed = 0.1
    character.stop_speed = 3.0
    character.jump_force = 10.0
    character.gravity = 30.0 // Gravity in m/s^2
    character.friction = 8.0
    character.velocity = rl.Vector2{0.0, 0.0}
    character.acceleration = 20.0
    character.air_steer = 1.0
    character.is_on_ground = true
    character.planes = make([]box2d.CollisionPlane, CHARACTER_MOVER_PLANE_CAPACITY)

    
    // Define capsule shape in meter units
    character.capsule.center1 = box2d.Vec2{0.0, 0.9}
    character.capsule.center2 = box2d.Vec2{0.0, -0.9}
    character.capsule.radius = 0.5
    
    character.friendly_shape_clip_velocity = false
    character.friendly_shape_max_push = 0.025
    
    // TODO: Implement filters for shape masking and collision handling
	//shapeDef.filter = { MoverBit, AllBits, 0 };
    
    // TODO: investigate what userData could be used for our purposes
	// shapeDef.userData = &m_friendlyShape;

    // Set up character mover methods
    character.process = characterMover2Process
    character.draw = characterMover2Draw
	
    return character

}


characterMover2Draw :: proc(node_ptr: rawptr) {

    character := cast(^CharacterMover2)node_ptr
    // Draw character representation (for debugging)
    capsuleShape := character.capsule
    body_position := character.ch_transform.p
    top_point := (body_position + capsuleShape.center1) * PIXELTOMETER_SCALE
    bottom_point := (body_position + capsuleShape.center2) * PIXELTOMETER_SCALE
    radius := capsuleShape.radius * PIXELTOMETER_SCALE
    rl.DrawCircleV(top_point, radius, rl.Fade(rl.BLUE, 0.5))
    rl.DrawCircleV(bottom_point, radius, rl.Fade(rl.BLUE, 0.5))
}

characterMover2Process :: proc(node_ptr: rawptr, delta: f32) {
    character := cast(^CharacterMover2)node_ptr

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
    }

    solveMovement(character, delta, input_direction)

}

solveMovement :: proc(character: ^CharacterMover2, delta: f32, throttle: f32) {
    using box2d
    speed := Length(character.velocity)

    // if speed < character.min_speed {
    //     character.velocity.x = 0
    // }
    // else if character.is_on_ground {
    //     // Linear damping above stopSpeed and fixed reduction below stopSpeed
    //     control: f32 = speed
    //     if speed < character.stop_speed {
    //         control = character.stop_speed
    //     } 

    //     // friction has units of 1/time
    //     drop: f32 = control * character.friction * delta
    //     newSpeed :f32 = max(0.0, speed - drop)
    //     character.velocity.x *= newSpeed / speed
    // }

    // desiredVelocity: Vec2 = { character.max_speed * throttle, 0.0 }
    // desiredSpeed, desiredDirection := GetLengthAndNormalize(desiredVelocity )

    // if ( desiredSpeed > character.max_speed )
    // {
    //     desiredSpeed = character.max_speed;
    // }

    // if ( character.is_on_ground )
    // {
    //     character.velocity.y = 0.0
    // }

    // // Accelerate
    // currentSpeed := box2d.Dot( character.velocity, desiredDirection );
    // addSpeed := desiredSpeed - currentSpeed;
    // if ( addSpeed > 0.0 )
    // {
    //     steer :f32 = character.air_steer
    //     if ( character.is_on_ground )
    //     {
    //         steer = 1.0
    //     }

    //     accelSpeed :f32 = steer * character.acceleration * character.max_speed * delta;
    //     if ( accelSpeed > addSpeed )
    //     {
    //         accelSpeed = addSpeed
    //     }

    //     character.velocity += accelSpeed * desiredDirection
    // }

    // Apply gravity

    character.velocity.y += character.gravity * delta

    // Figure out if on ground
    pogoRestLength :f32 = 3.0 * character.capsule.radius
    rayLength :f32 = pogoRestLength
    origin :Vec2 = TransformPoint( character.ch_transform, character.capsule.center1 )
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
	translation = { 0.0, +rayLength };

    treeStats := World_CastShape( GAME.world_id, proxy, translation, pogoFilter, castCallback, &castResult )
    // Avoid snapping to ground if still going up
    if ( character.is_on_ground == false )
    {
        character.is_on_ground = castResult.hit && character.velocity.y <= 0.01;
    }
    else
    {
        character.is_on_ground = castResult.hit;
    }
    ray_start_point := Vec2{meterToPixel(origin.x), meterToPixel(origin.y)}
    ray_endpoint := Vec2{meterToPixel(origin.x), meterToPixel(origin.y + rayLength)}
    rl.DrawCircleV({meterToPixel(origin.x), meterToPixel(origin.y)}, 5.0, rl.RED)
    rl.DrawLineV(ray_start_point, ray_endpoint, rl.GREEN)
    if castResult.hit {
        rl.DrawCircleV( Vec2{ meterToPixel(castResult.point.x), meterToPixel(castResult.point.y) }, 5.0, rl.YELLOW)
        rl.DrawText(fmt.ctprint(fmt.tprintf("Ground Hit"), ), 500, 150, 15, rl.RED)
    }

    

    // Solve move and collide
    target: Vec2 = character.ch_transform.p + delta * character.velocity
    // Mover overlap filter
   
    collideFilter :QueryFilter = { u64(FilterCategory.Movers),  u64(FilterCategory.StaticBody) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody) };

    // Movers don't sweep against other movers, allows for soft collision
    castFilter :QueryFilter = { u64(FilterCategory.Movers),  u64(FilterCategory.StaticBody) | u64(FilterCategory.DynamicBody) | u64(FilterCategory.KinematicBody) };

    character.total_iterations = 0
    tolerance :f32= 0.01

    for iteration in 0..<5 {
        character.plane_count = 0

        mover: Capsule

        mover.center1 = TransformPoint( character.ch_transform, character.capsule.center1 )
        mover.center2 = TransformPoint( character.ch_transform, character.capsule.center2 )
        mover.radius = character.capsule.radius

        box2d.World_CollideMover( GAME.world_id, mover, collideFilter, planeResultFcn, character )
        result := SolvePlanes( target - character.ch_transform.p, character.planes );

        character.total_iterations += int(result.iterationCount)

        fraction := box2d.World_CastMover( GAME.world_id, mover, result.position, castFilter );

        delta_ :Vec2 = fraction * result.position;
        character.ch_transform.p += delta_;

        if ( LengthSquared( delta_ ) < tolerance * tolerance )
        {
            break;
        }
    }
    
    character.velocity = ClipVector( character.velocity, character.planes);
}


planeResultFcn :: proc "c" (shapeId: box2d.ShapeId, planeResult: ^box2d.PlaneResult, ctx: rawptr) -> bool {
        self := cast(^CharacterMover2)ctx
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

 castCallback :: proc "c" ( shapeId: box2d.ShapeId, point: box2d.Vec2, normal: box2d.Vec2, fraction: f32, ctx: rawptr ) -> f32 {
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


main :: proc() {
    // Memory tracking setup
    when ODIN_DEBUG {
		mem.tracking_allocator_init(&TRACK, context.allocator)
		context.allocator = mem.tracking_allocator(&TRACK)

		defer {
			mem.tracking_allocator_destroy(&TRACK)
		}
	}

    // Profiling setup
    prof_init()
	defer prof_deinit()

    GAME->init()

    // Create root node and other game nodes
    root := createNode("Root")
    root_id := GAME.node_manager->addNode(cast(rawptr)root)

    tilemap := createTileMapNode("resources/TileMaps/Level1.tmj", GAME.resource_manager)
    GAME.node_manager->addNode(cast(rawptr)tilemap)
    GAME.node_manager->addChild(root, cast(rawptr)tilemap)

    cm := createCharacterMover2("Player", rl.Vector2{540, 490})
    GAME.node_manager->addNode(cast(rawptr)cm)
    GAME.node_manager->addChild(root, cast(rawptr)cm)

    // Initialize nodes
    GAME.node_manager->_initializeNodes()

    // Set root node
    GAME->setRoot(  root_id)



    // Run the main game loop
    GAME->run(root, proc(go: ^GameObject, root: ^Node, delta_time: f32) {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            color_hue := rand.float32_range(0.0, 360.0)
            color := rl.ColorFromHSV(color_hue, 0.8, 0.9)

            createRock(rl.GetMousePosition(), color)
            
        }
        if rl.IsKeyPressed(rl.KeyboardKey.V) {
            GAME.layer_manager->setLayerVisibility(PARALLAX_LAYER_1, !GAME.layer_manager->getLayerVisibility(PARALLAX_LAYER_1))
        }
        
    })

    // Shutdown and cleanup
    GAME->shutdown()
}