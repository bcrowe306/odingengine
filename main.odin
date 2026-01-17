package main

import "vendor:box2d"
import rl "vendor:raylib"
import fmt "core:fmt"

// Create the main game object as a global variable
GAME := createGameObject("Oding Engine Test Game")

main :: proc() {
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

    floorBody := createStaticBody(GAME.world_id, "FloorBody", rl.Vector2{640, 668})
    floorShape := createRectangleCollisionShape(GAME.world_id, floorBody.body_id, rl.Vector2{1260, 100})
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
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            using GAME
            newBody := createDynamicBody(GAME.world_id, "RockBody", rl.GetMousePosition())
            node_manager->addNode(cast(rawptr)newBody)
            node_manager->addChild(root, cast(rawptr)newBody)
            newShape := createCircleCollisionShape(GAME.world_id, newBody.body_id, 10.0)
            node_manager->addNode(cast(rawptr)newShape)
            addCollisionShape(cast(^PhysicsBody)newBody, cast(^CollisionShape)newShape)
            
        }
        
    })

    // Shutdown and cleanup
    GAME->shutdown()
}