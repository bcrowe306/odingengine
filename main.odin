package main

import "core:math/rand"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:mem"


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