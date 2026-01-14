package main

import "core:fmt"


import rl "vendor:raylib"
import box2d "vendor:box2d"


WINDOWS_SIZE_X ::  1280
WINDOWS_SIZE_Y ::  720
FPS_TARGET ::  60
GRAVITY ::  9.8
GAME_TITLE ::  "Warzone"



main :: proc() {
 

    rl.InitWindow(WINDOWS_SIZE_X, WINDOWS_SIZE_Y, GAME_TITLE)
    defer rl.CloseWindow()
    
    rl.SetTargetFPS(FPS_TARGET)
    layerManager := layerManagerConstruct()

    parent := createNode()
    c1 := createNode()
    c2 := createNode()
    t1 := createTimerNode("MainTimer", 1.0, true, true)
    signalConnect(&t1.on_timeout, proc(tn: ^TimerNode, args: ..any) {
        fmt.printfln("TimerNode '%s' timeout count: %d", tn.name, tn.timeout_count)
    })
    addChildNode(parent, c1)
    addChildNode(parent, c2)
    addChildNode(c1, t1)    

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        // Process add/remove queues
        processQueues(parent)

        rl.ClearBackground(rl.DARKGRAY)
        delta := rl.GetFrameTime()

        // Inputs
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            r := createRectNode()
            
            addChildNode(parent, r)
        }

        if rl.IsMouseButtonDown(rl.MouseButton.LEFT){
            parent.transform.position = rl.GetMousePosition()
        }

        // Update
        updateNodes(parent, delta)
        

        for layer in getLayerDrawOrder(&layerManager) {
            renderNodes(parent, layer.name)
        }
        
        // Close conditions
        if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
            break
        }
        
    }

}