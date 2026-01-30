package main

import "core:math/ease"
import "base:runtime"
import "vendor:box2d"
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
test_value: f32 = 50.0







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

    
    // Create a tilemap node
    tilemap := createTileMapNode("resources/TileMaps/Level1.tmj", GAME.resource_manager)
    GAME.node_manager->addNode(cast(rawptr)tilemap)
    GAME.node_manager->addChild(root, cast(rawptr)tilemap)

    // Create particle node
    particleNode := createParticleNode("ParticleNode", rl.Vector2{0, 0})
    particleNode.particle_amount = 90
    particleNode.particle_life = .3
    particleNode.spread = 360
    particleNode.initial_velocity = 120
    particleNode.velocity_randomness = .4
    particleNode.acceleration = 0
    particleNode.size = rl.Vector2{23, 23}
    particleNode.size_randomness = .2
    particleNode.size_start = 1.0
    particleNode.size_end = 0.0
    particleNode.particle_gravity = rl.Vector2{0, -360}
    particleNode.initial_direction = rl.Vector2{0, -1}
    particleNode.particle_type = .Circle
    GAME.node_manager->addNode(cast(rawptr)particleNode)
    

    // Create a character body and sprite
    characterBody := createCharacterBody("Player", rl.Vector2{540, 490}, radius=.9, height=.3)
    characterSprite := createSprite2D(GAME.resource_manager,"BoarSprite", "resources/Legacy Enemy - Boar Warrior/Idle/Idle-Sheet.png")
    characterSprite.process = proc(node_ptr: rawptr, delta: f32) {
        char_ptr := GAME.node_manager->getNodeByName("Player")
        character := cast(^CharacterBody)char_ptr
        sprite := cast(^Sprite2D)node_ptr
        sprite.texture.flip_h = character.facing_direction
    }
    characterSprite.texture.h_frames = 4
    characterSprite.texture.v_frames = 1
    characterSprite.current_frame = 0

    wallCast := createRaycast2D("WallCast", rl.Vector2{0,0}, rl.Vector2{100,0})
    wallCast.filter = { u64(FilterCategory.Movers), u64(FilterCategory.StaticBody) }
    wallCast.debug = true
    

    // Create camera node
    cameraNode := createCameraNode("MainCamera",
        target = characterBody.transform.global_pos,
        offset = rl.Vector2{GAME.window_size.x / 2, GAME.window_size.y / 2},
        zoom = 1.0,
        limits = {0, 0, math.F32_MAX, 620}

    )
    GAME.node_manager->addNode(cast(rawptr)cameraNode)

    
    GAME.node_manager->addNode(cast(rawptr)wallCast)
    GAME.node_manager->addNode(cast(rawptr)characterSprite)
    GAME.node_manager->addNode(cast(rawptr)characterBody)

    GAME.node_manager->addChild(root, cast(rawptr)characterBody)
    GAME.node_manager->addChild(cast(^Node)characterBody, cast(rawptr)cameraNode)
    GAME.node_manager->addChild(cast(^Node)characterBody, cast(rawptr)particleNode)
    GAME.node_manager->addChild(cast(^Node)characterBody, cast(rawptr)characterSprite)
    GAME.node_manager->addChild(cast(^Node)characterBody, cast(rawptr)wallCast)

    // Initialize nodes
    GAME.node_manager->_initializeNodes()

    // Set root node
    GAME->setRoot(  root_id)


    // Run the main game loop
    GAME->run(root, proc(go: ^GameObject, root: ^Node, delta_time: f32) {

            
        if rl.IsKeyPressed(rl.KeyboardKey.V) {
            GAME.layer_manager->setLayerVisibility(PARALLAX_LAYER_1, !GAME.layer_manager->getLayerVisibility(PARALLAX_LAYER_1))
        }

        rl.DrawText(fmt.ctprintf(" Mouse Position: (%d, %d) ", rl.GetMouseX(), rl.GetMouseY()), 300, 20, 20, rl.RAYWHITE)
        
        
        
    })

    // Shutdown and cleanup
    GAME->shutdown()
}