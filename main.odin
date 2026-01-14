package main

import rl "vendor:raylib"
import box2d "vendor:box2d"
import fmt "core:fmt"


WINDOWS_SIZE_X ::  1280
WINDOWS_SIZE_Y ::  720
FPS_TARGET ::  60
GRAVITY ::  9.8
GAME_TITLE ::  "Warzone"

// Global Action Manager
ACTIONMANAGER := createActionsManager()


main :: proc() {
 

    rl.InitWindow(WINDOWS_SIZE_X, WINDOWS_SIZE_Y, GAME_TITLE)
    defer rl.CloseWindow()
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()
    
    rl.SetTargetFPS(FPS_TARGET)
    layerManager := layerManagerConstruct()
    resource_manager := createResourceManager()
    resource_manager->loadDefaultFonts()

    root := createNode("Root")
    player := createNode("Player")
    t1 := createTimerNode("MainTimer", 1.0, true, true)
    audio_player := createAudioPlayer(resource_manager, "TestAudioPlayer", "resources/COINS Collect Chime 01.ogg")
    player_text := createText2D(resource_manager, "TitleText", "Test", "open_sans", 18, rl.YELLOW)
    boarWarrior := createAnimatedSprite2D(resource_manager, "BoarWarrior")
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

    init(root)
    input_a := createInput(rl.KeyboardKey.A)
    input_left := createInput(rl.KeyboardKey.LEFT)
    ACTIONMANAGER->createAction("MoveLeft", input_a, input_left)


    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        // Process add/remove queues
        processQueues(root)

        rl.ClearBackground(rl.DARKGRAY)
        delta := rl.GetFrameTime()

        // Inputs
        if ACTIONMANAGER->getAction("MoveLeft")->pressed() {
            boarWarrior->setAnimation("Idle")
            audio_player->play()
        }
        else if rl.IsKeyPressed(rl.KeyboardKey.W) {
            boarWarrior->setAnimation("Walk")
        }

        if rl.IsMouseButtonDown(rl.MouseButton.LEFT){
            player.transform.position = rl.GetMousePosition()
        }

        if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT){
            player->queueFree()
        }

        if rl.IsKeyPressed(rl.KeyboardKey.F){
            setFlipH(boarWarrior, !getFlipH(boarWarrior))
        }

        // Update
        updateNodes(root, delta)
        

        for layer in getLayerDrawOrder(&layerManager) {
            renderNodes(root, layer.name)
        }
        
        // Close conditions
        if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
            break
        }
        
    }

}