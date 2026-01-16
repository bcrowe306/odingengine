package main

import rl "vendor:raylib"
import fmt "core:fmt"

// Create the main game object as a global variable
GAME := createGameObject("Oding Engine Test Game")

main :: proc() {
    
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

    signalConnect(&t1.on_timeout, proc(tn: ^TimerNode, args: ..any) {
        fmt.println("Timer Timeout Signal Emitted")
        pt := getNode(tn, "../TitleText")
        if pt != nil {
            text_node := cast(^Text2D)pt
            text_node.text = fmt.tprintf("Timer Count: %d", tn.timeout_count)
        }
    })

    // Initialize root node
    GAME->init(root)

    // Run the main game loop
    GAME->run(root)

    // Shutdown and cleanup
    GAME->shutdown()
}