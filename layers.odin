package main


import sort "core:sort"
import "core:slice"


BACKGROUND_LAYER: string = "Background"
PARALLAX_LAYER_1: string = "Parallax1"
PARALLAX_LAYER_2: string = "Parallax2"
PARALLAX_LAYER_3: string = "Parallax3"
MIDGROUND_LAYER: string = "Midground"
TILESET_LAYER: string = "Tileset"
PLAYER_LAYER: string = "Player"
FOREGROUND_LAYER: string = "Foreground"
UI_LAYER: string = "UI"

Layer :: struct {
    name: string,
    z_index: i32,
}

LayerManager :: struct {
    layers: [dynamic]Layer,
}

layerManagerConstruct :: proc() -> LayerManager {
    manager : LayerManager
    addLayer(&manager, BACKGROUND_LAYER, 0)
    addLayer(&manager, PARALLAX_LAYER_1, 1)
    addLayer(&manager, PARALLAX_LAYER_2, 2)
    addLayer(&manager, PARALLAX_LAYER_3, 3)
    addLayer(&manager, MIDGROUND_LAYER, 4)
    addLayer(&manager, TILESET_LAYER, 5)
    addLayer(&manager, PLAYER_LAYER, 6)
    addLayer(&manager, FOREGROUND_LAYER, 7)
    addLayer(&manager, UI_LAYER, 8)
    return manager
}

addLayer :: proc(manager: ^LayerManager, layer_name: string, z_index: i32) {
    append(&manager.layers, Layer{name = layer_name, z_index = z_index})

}

getLayerDrawOrder :: proc(manager: ^LayerManager) -> []Layer {
    // Returns an array of z_index values in sorted order
    lowest_to_highest := manager.layers[:]
    slice.sort_by(lowest_to_highest, proc(a: Layer, b: Layer) -> bool {
        return a.z_index < b.z_index
    })
    return lowest_to_highest
}
