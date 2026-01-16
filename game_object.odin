package main

import "core:c"
import "core:time"
import rl "vendor:raylib"
import box2d "vendor:box2d"
import fmt "core:fmt"
import math "core:math"

CHARACTER_SIZE :f32 = 64
CHARACTER_METERS: f32 = 2
PIXELTOMETER_SCALE : f32 = CHARACTER_SIZE / CHARACTER_METERS
METERTOPIXEL_SCALE : f32 = CHARACTER_METERS / CHARACTER_SIZE

pixelToMeter :: proc(px: f32) -> f32 {
    return px / (CHARACTER_SIZE / CHARACTER_METERS)
}

meterToPixel :: proc(m: f32) -> f32 {
    return m * (CHARACTER_SIZE / CHARACTER_METERS)
}

// mousePositionInWorld :: proc(world_id: box2d.WorldId) -> rl.Vector2 {
//     mousePos := rl.GetMousePosition()
//     camPos := rl.GetCamera2D().target - rl.GetCamera2D().offset
//     worldX := mousePos.x + camPos.x
//     worldY := mousePos.y + camPos.y
//     return rl.Vector2{worldX, worldY}
// }

getMousePositionInWorldMeters :: proc() -> box2d.Vec2 {
    mousePos := rl.GetMousePosition()
    return mousePos
}

PhysicsSettings :: struct {
    worker_threads: int,
    gravity: box2d.Vec2,
    allow_sleep: bool,
    time_step: f32,
    substep_count: int,
    elapsed_time: f32,

}

GameObject :: struct {
    window_size: rl.Vector2,
    window_resizable: bool,
    window_vsync: bool,
    window_transparent: bool,
    render_target: rl.RenderTexture2D,
    title: string,
    background_color: rl.Color,
    target_fps: i32,
    world_id: box2d.WorldId,
    actions_manager: ^ActionsManager,
    layer_manager: LayerManager,
    resource_manager: ^ResourceManager,
    physics_settings: PhysicsSettings,
    init: proc(go: ^GameObject),
    setRootNode: proc(go: ^GameObject, root: ^Node),
    run: proc(go: ^GameObject, root: ^Node, update_func: proc(go: ^GameObject, root: ^Node, delta_time: f32) = nil),
    shutdown: proc(go: ^GameObject),

}

setWindowFlags :: proc(go: ^GameObject) {
    
    flags := rl.ConfigFlags{}
    if go.window_resizable {
        flags |= {.WINDOW_RESIZABLE}
    }
    if go.window_vsync {
        flags |= {.VSYNC_HINT}
    }
    if go.window_transparent {
        flags |= {.WINDOW_TRANSPARENT}
    }
    rl.SetConfigFlags(flags)

}

createGameObject :: proc (title: string, window_size: rl.Vector2 = rl.Vector2{1280, 720}, background_color: rl.Color = rl.DARKGRAY, target_fps: i32 = 60) -> ^GameObject {
    game_obj := new(GameObject)
    game_obj.window_size = window_size
    game_obj.window_resizable = true
    game_obj.window_vsync = true
    game_obj.window_transparent = false
    game_obj.title = title
    game_obj.background_color = background_color
    game_obj.target_fps = target_fps
    game_obj.actions_manager = createActionsManager()
    game_obj.layer_manager = layerManagerConstruct()
    game_obj.resource_manager = createResourceManager()
    game_obj.physics_settings = PhysicsSettings{
        worker_threads = 4,
        gravity = box2d.Vec2{0.0, 9.8},
        allow_sleep = true,
        time_step = 1.0 / 60.0,
        substep_count = 4,
    }
    game_obj.init = initializeGameObject
    game_obj.run = run
    game_obj.shutdown = shutdownGameObject
    game_obj.setRootNode = setRootNode
    return game_obj
}

initializeGameObject :: proc (go: ^GameObject) {
    
    setWindowFlags(go)
    rl.InitWindow(i32(go.window_size.x), i32(go.window_size.y), fmt.ctprint(go.title))
    rl.InitAudioDevice()
    rl.SetTargetFPS(go.target_fps)
    go.render_target = rl.LoadRenderTexture(i32(go.window_size.x), i32(go.window_size.y))


    worldDef := box2d.DefaultWorldDef()
    worldDef.gravity = go.physics_settings.gravity
    worldDef.workerCount = i32(go.physics_settings.worker_threads)
    worldDef.enableSleep = go.physics_settings.allow_sleep
    go.world_id = box2d.CreateWorld(worldDef)

    go.actions_manager->createAction("DIR_LEFT", createInput(rl.KeyboardKey.A), createInput(rl.KeyboardKey.LEFT))
    go.actions_manager->createAction("DIR_RIGHT", createInput(rl.KeyboardKey.R), createInput(rl.KeyboardKey.D))
    go.actions_manager->createAction("ACTION_JUMP", createInput(rl.KeyboardKey.SPACE))
    go.actions_manager->createAction("ACTION_ATTACK", createInput(rl.KeyboardKey.J))

    go.resource_manager->loadDefaultFonts()
}

setRootNode :: proc (go: ^GameObject, root: ^Node) {
    init(root)
}

run :: proc (go: ^GameObject, root: ^Node, update_func: proc(go: ^GameObject, root: ^Node, delta_time: f32) = nil) {

    for !rl.WindowShouldClose() {
        
        rl.BeginTextureMode(go.render_target)
            

            // Process add/remove queues
            processQueues(root)

            rl.ClearBackground(go.background_color)
            delta := rl.GetFrameTime()

            // Update physics world according to time step settings
            go.physics_settings.elapsed_time += delta
            if go.physics_settings.elapsed_time >= go.physics_settings.time_step {
                box2d.World_Step(go.world_id, go.physics_settings.time_step, i32(go.physics_settings.substep_count))
                go.physics_settings.elapsed_time = 0.0
            }

            // Update nodes
            updateNodes(root, delta)

            // Custom update function
            if update_func != nil {
                update_func(go, root, delta)
            }
            show_nodes :: proc (n: ^Node, depth: int, count: ^int) {
                
                
                if rl.GuiButton(rl.Rectangle{10 + f32(depth * 20), 10 + f32(count^ * 30), 120, 25}, fmt.ctprintf("%d, %s", n.id, n.name)) {
                    n->addChild(createNode("NewChild"))
                }
                count^ +=1
                for &node_ptr, index in &n.children {
                    n := cast(^Node)node_ptr
                    
                    if node_ptr != nil {
                        show_nodes(n, depth + 1, count)
                    }
                   
                }

            }
            nc := 0
            show_nodes(root, 0, &nc)

            // Draw all layers in order
            for layer in getLayerDrawOrder(&go.layer_manager) {
                renderNodes(root, layer.name)
            }

            // Close conditions
            if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
                break
            }
        rl.EndTextureMode()
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK) // Letterbox color

        // Calculate scaling and positioning for letterbox effect
        scale := math.min(f32(rl.GetScreenWidth()) / go.window_size.x, f32(rl.GetScreenHeight()) / go.window_size.y)
        offsetX := (f32(rl.GetScreenWidth()) - (go.window_size.x * scale)) * 0.5
        offsetY := (f32(rl.GetScreenHeight()) - (go.window_size.y * scale)) * 0.5

        rl.DrawTexturePro(
            go.render_target.texture,
            rl.Rectangle{ 0.0, 0.0, f32(go.render_target.texture.width), f32(-go.render_target.texture.height) }, // Source (note the negative height to flip the texture correctly for OpenGL)
            rl.Rectangle{ f32(offsetX), f32(offsetY), f32(go.window_size.x) * scale, f32(go.window_size.y) * scale }, // Destination
            rl.Vector2{ 0, 0 }, 0.0, rl.WHITE
        );

        rl.EndDrawing();
    }
}

shutdownGameObject :: proc (go: ^GameObject) {
    box2d.DestroyWorld(go.world_id)
    go.resource_manager->freeResources()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}