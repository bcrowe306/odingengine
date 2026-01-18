package main

import "core:math/rand"
import "vendor:box2d"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:mem"

// Create the main game object as a global variable
GAME := createGameObject("Oding Engine Test Game", target_fps=120)
TRACK: mem.Tracking_Allocator



main :: proc() {
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
    player := createCharacterMover("Player")
    GAME.node_manager->addNode(cast(rawptr)player)
    t1 := createTimerNode("MainTimer", 1.0, true, true)
    GAME.node_manager->addNode(cast(rawptr)t1)
    audio_player := createAudioPlayer(GAME.resource_manager, "TestAudioPlayer", "resources/COINS Collect Chime 01.ogg")
    GAME.node_manager->addNode(cast(rawptr)audio_player)
    player_text := createText2D(GAME.resource_manager, "TitleText", "Test", "open_sans", 18, rl.YELLOW)
    GAME.node_manager->addNode(cast(rawptr)player_text)
    boarWarrior := createAnimatedSprite2D(GAME.resource_manager, "BoarWarrior")
    GAME.node_manager->addNode(cast(rawptr)boarWarrior)
   
    createAnimation(boarWarrior, "Idle", "resources/Legacy Enemy - Boar Warrior/Idle/Idle-Sheet-White.png", 4, 1, 6, true, true)
    createAnimation(boarWarrior, "Walk", "resources/Legacy Enemy - Boar Warrior/Walk/Walk-Sheet-White.png", 8, 1, 12, true, true)

    GAME.node_manager->addChild(player, boarWarrior)
    GAME.node_manager->addChild(player, audio_player)
    GAME.node_manager->addChild(player, audio_player)
    GAME.node_manager->addChild(root, t1)
    GAME.node_manager->addChild(root, player)
    GAME.node_manager->addChild(root, player_text)

    createFloorBody(GAME.world_id, "FloorBody", rl.Vector2{750, 200}, rl.Vector2{300, 40}, -30.0)
    createFloorBody(GAME.world_id, "FloorBody", rl.Vector2{300, 400}, rl.Vector2{400, 40}, 15.0)
    createFloorBody(GAME.world_id, "FloorBody", rl.Vector2{640, 668}, rl.Vector2{1260, 100})

    floorBody := createStaticBody(GAME.world_id, "FloorBody", rl.Vector2{640, 668})
    GAME.node_manager->addNode(cast(rawptr)floorBody)
    floorShape := createRectangleCollisionShape(GAME.world_id, floorBody.body_id, rl.Vector2{1260, 100})
    GAME.node_manager->addNode(cast(rawptr)floorShape)
    addCollisionShape(cast(^PhysicsBody)floorBody, cast(^CollisionShape)floorShape)
    GAME.node_manager->addChild(root, cast(rawptr)floorBody)

    rockBody := createDynamicBody(GAME.world_id, "RockBody", rl.Vector2{800, 100})
    GAME.node_manager->addNode(cast(rawptr)rockBody)
    rockShape := createCircleCollisionShape(GAME.world_id, rockBody.body_id, 20.0)
    GAME.node_manager->addNode(cast(rawptr)rockShape)
    addCollisionShape(cast(^PhysicsBody)rockBody, cast(^CollisionShape)rockShape)
    GAME.node_manager->addChild(root, cast(rawptr)rockBody)

    signalConnect(&t1.on_timeout, proc(tn: ^TimerNode, args: ..any) {
        pt := getNode(tn, "../TitleText")
        if pt != nil {
            text_node := cast(^Text2D)pt
            text_node.text = fmt.tprintf("Timer Count: %d", tn.timeout_count)
        }
    })

    // Initialize game and root node
    GAME.node_manager->_initializeNodes()
    GAME->setRoot(  root_id)


    // Run the main game loop
    GAME->run(root, proc(go: ^GameObject, root: ^Node, delta_time: f32) {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            color_hue := rand.float32_range(0.0, 360.0)
            color := rl.ColorFromHSV(color_hue, 0.8, 0.9)

            createRock(rl.GetMousePosition(), color)
            
        }
        
    })

    // Shutdown and cleanup
    GAME->shutdown()
}