package main

import "core:fmt"


import rl "vendor:raylib"
import box2d "vendor:box2d"

printSomething:: proc(str: string) {
    fmt.println(str)
}

WINDOWS_SIZE_X ::  1280
WINDOWS_SIZE_Y ::  720
FPS_TARGET ::  60
GRAVITY ::  9.8
GAME_TITLE ::  "Warzone"


main :: proc() {
    
    rl.InitWindow(WINDOWS_SIZE_X, WINDOWS_SIZE_Y, GAME_TITLE)
    defer rl.CloseWindow()

    root: Node = nodeConstruct(rl.Vector2{0,0}, rl.Vector2{1,1}, 0.0)
   
    rl.SetTargetFPS(FPS_TARGET)

    ballPosition := rl.Vector2{200, 200}

    for !rl.WindowShouldClose() {
        // Update
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.WHITE)

        delta := rl.GetFrameTime()

        if rl.IsKeyPressed(rl.KeyboardKey.SPACE){
            newNode: Node = nodeConstruct(ballPosition, rl.Vector2{1,1}, 0.0)
            nodeAddChild(&root, newNode)
        }
        
        if rl.IsKeyPressed(rl.KeyboardKey.R) {
            new_pos : rl.Vector2 = rl.Vector2{ballPosition.x + 30 * f32(len(root.children)), ballPosition.y + 30}
            newNode: Node = rectangleNodeConstruct(new_pos, rl.Vector2{1,1}, 0.0, rl.Vector2{20, 20}).base
            newNode.draw = drawRect
            nodeAddChild(&root, newNode)
        }

        for &node, index in root.children {
            nodeUpdate(&node, delta)
            nodeRender(&node)
        }
        rl.DrawText(fmt.ctprintf("Children Count: %d", len(root.children)), 10, 10, 20, rl.BLACK)
        nodeProcessQueues(&root)

       
        if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
            break
        }
    }

}