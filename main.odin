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
    player := createCharacterMover("Player")
    t1 := createTimerNode("MainTimer", 1.0, true, true)
    audio_player := createAudioPlayer(GAME.resource_manager, "TestAudioPlayer", "resources/COINS Collect Chime 01.ogg")
    player_text := createText2D(GAME.resource_manager, "TitleText", "Test", "open_sans", 18, rl.YELLOW)
    boarWarrior := createAnimatedSprite2D(GAME.resource_manager, "BoarWarrior")


   
    createAnimation(boarWarrior, "Idle", "resources/Legacy Enemy - Boar Warrior/Idle/Idle-Sheet-White.png", 4, 1, 6, true, true)
    createAnimation(boarWarrior, "Walk", "resources/Legacy Enemy - Boar Warrior/Walk/Walk-Sheet-White.png", 8, 1, 12, true, true)


    addChildNode(player, boarWarrior)
    addChildNode(player, audio_player)
    addChildNode(root, t1)
    addChildNode(root, player)
    addChildNode(root, player_text)

    floorBody := createStaticBody(GAME.world_id, "FloorBody", rl.Vector2{640, 668})
    floorShape := createRectangleCollisionShape(GAME.world_id, floorBody.body_id, rl.Vector2{1260, 100})
    addCollisionShape(cast(^PhysicsBody)floorBody, cast(^CollisionShape)floorShape)
    addChildNode(root, cast(^Node)floorBody)

    rockBody := createDynamicBody(GAME.world_id, "RockBody", rl.Vector2{800, 100})
    rockShape := createCircleCollisionShape(GAME.world_id, rockBody.body_id, 20.0)
    addCollisionShape(cast(^PhysicsBody)rockBody, cast(^CollisionShape)rockShape)
    addChildNode(root, cast(^Node)rockBody)

    signalConnect(&t1.on_timeout, proc(tn: ^TimerNode, args: ..any) {
        pt := getNode(tn, "../TitleText")
        if pt != nil {
            text_node := cast(^Text2D)pt
            text_node.text = fmt.tprintf("Timer Count: %d", tn.timeout_count)
        }
    })

    // Initialize game and root node
    GAME->setRootNode(root)


    // Run the main game loop
    GAME->run(root, proc(go: ^GameObject, root: ^Node, delta_time: f32) {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            newBody := createDynamicBody(GAME.world_id, "RockBody", rl.GetMousePosition())
            newShape := createCircleCollisionShape(GAME.world_id, newBody.body_id, 10.0)
            addCollisionShape(cast(^PhysicsBody)newBody, cast(^CollisionShape)newShape)
            addChildNode(root, cast(^Node)newBody)
        }
        
    })

    // Shutdown and cleanup
    GAME->shutdown()
}