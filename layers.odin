package main


import sort "core:sort"
import "core:slice"
import fmt "core:fmt"

LayerZIndex :: int

BACKGROUND_LAYER: LayerZIndex = 0
PARALLAX_LAYER_1: LayerZIndex = 1
PARALLAX_LAYER_2: LayerZIndex = 2
PARALLAX_LAYER_3: LayerZIndex = 3
MIDGROUND_LAYER: LayerZIndex = 4
TILESET_LAYER: LayerZIndex = 5
PLAYER_LAYER: LayerZIndex = 6
FOREGROUND_LAYER: LayerZIndex = 7
UI_LAYER: LayerZIndex = 8

Layer :: struct {
    name: string,
    z_index: LayerZIndex,
    visible: bool,
}

LayerToNode :: struct {
    layer_index: LayerZIndex,
    node_index: NodeIndex,
}

LayerManager :: struct {
    layers: [dynamic]Layer,
    layer_nodes: [dynamic]LayerToNode,
    layer_nodes_sorted: []LayerToNode,
    allow_nonexistent_layers: bool,
    layers_changed: bool,
    draw_nodes: proc(manager: ^LayerManager, node_manager: ^NodeManager),
    processNodeChanges: proc(manager: ^LayerManager, node_manager: ^NodeManager),
    addLayer: proc(manager: ^LayerManager, layer_name: string, z_index: LayerZIndex, visible: bool),
    addLayerNode: proc(manager: ^LayerManager, layer_index: LayerZIndex, node_index: NodeIndex),
    getLayerDrawOrder: proc(manager: ^LayerManager) -> []LayerToNode,
    getLayerByZIndex: proc(manager: ^LayerManager, z_index: LayerZIndex) -> ^Layer,
    getLayerByName: proc(manager: ^LayerManager, name: string) -> ^Layer,
    clearLayerNodes: proc(manager: ^LayerManager),
    removeLayerNode: proc(manager: ^LayerManager, node_index: NodeIndex),
    setLayerVisibility: proc(manager: ^LayerManager, z_index: LayerZIndex, visible: bool),
    getLayerVisibility: proc(manager: ^LayerManager, z_index: LayerZIndex) -> bool,

}

layerManagerConstruct :: proc() -> ^LayerManager {
    manager := new(LayerManager)
    manager.draw_nodes = drawLayerNodes
    manager.processNodeChanges = processLayerNodeChanges
    manager.addLayer = addLayer
    manager.addLayerNode = addLayerNode
    manager.getLayerDrawOrder = getLayerDrawOrder
    manager.getLayerByZIndex = getLayerByZIndex
    manager.getLayerByName = getLayerByName
    manager.clearLayerNodes = clearLayerNodes
    manager.removeLayerNode = removeLayerNode
    manager.allow_nonexistent_layers = true
    manager.layers_changed = false
    manager.setLayerVisibility = setLayerVisibility
    manager.getLayerVisibility = getLayerVisibility

    manager->addLayer("Background", BACKGROUND_LAYER, true)
    manager->addLayer("Parallax1", PARALLAX_LAYER_1, true)
    manager->addLayer("Parallax2", PARALLAX_LAYER_2, true)
    manager->addLayer("Parallax3", PARALLAX_LAYER_3, true)
    manager->addLayer("Midground", MIDGROUND_LAYER, true)
    manager->addLayer("Tileset", TILESET_LAYER, true)
    manager->addLayer("Player", PLAYER_LAYER, true)
    manager->addLayer("Foreground", FOREGROUND_LAYER, true)
    manager->addLayer("UI", UI_LAYER, true)

    return manager
}

processLayerNodeChanges :: proc(manager: ^LayerManager, node_manager: ^NodeManager) {
    // Process nodes in layer order
    if manager.layers_changed {
        manager.layer_nodes_sorted = manager->getLayerDrawOrder()
        manager.layers_changed = false
    }
}

addLayer :: proc(manager: ^LayerManager, layer_name: string, z_index: LayerZIndex, visible: bool = true) {

    // Find if layer already exists by name or z_index
    for existing_layer in manager.layers {
        if existing_layer.name == layer_name || existing_layer.z_index == z_index {
            fmt.println("Layer already exists: ", layer_name)
            return
        }
    }
    append(&manager.layers, Layer{name = layer_name, z_index = z_index, visible = visible})
    manager.layers_changed = true

}

setLayerVisibility :: proc(manager: ^LayerManager, z_index: LayerZIndex, visible: bool) {
    layer := manager->getLayerByZIndex(z_index)
    if layer != nil {
        layer.visible = visible
    }
}

getLayerVisibility :: proc(manager: ^LayerManager, z_index: LayerZIndex) -> bool {
    layer := manager->getLayerByZIndex(z_index)
    if layer != nil {
        return layer.visible
    }
    return false
}

getLayerByZIndex :: proc(manager: ^LayerManager, z_index: LayerZIndex) -> ^Layer {
    for &layer in manager.layers {
        if layer.z_index == z_index {
            return &layer
        }
    }
    return nil
}

getLayerByName :: proc(manager: ^LayerManager, name: string) -> ^Layer {
    for &layer in manager.layers {
        if layer.name == name {
            return &layer
        }
    }
    return nil
}

addLayerNode :: proc(manager: ^LayerManager, layer_index: LayerZIndex, node_index: NodeIndex) {
    
    // Only add node if not already present. If present, update the layer_index
    for &ltn in manager.layer_nodes {
        if ltn.node_index == node_index {
            ltn.layer_index = layer_index
            return
        }
    }
    append(&manager.layer_nodes, LayerToNode{layer_index = layer_index, node_index = node_index})
    manager.layers_changed = true
}

removeLayerNode :: proc(manager: ^LayerManager, node_index: NodeIndex) {
    for &ltn, i in manager.layer_nodes {
        if ltn.node_index == node_index {
            ordered_remove(&manager.layer_nodes, i)
            manager.layers_changed = true
            return
        }
    }
}

getLayerDrawOrder :: proc(manager: ^LayerManager) -> []LayerToNode {
    // Returns an array of z_index values in sorted order
    lowest_to_highest := manager.layer_nodes[:]
    slice.sort_by(lowest_to_highest, proc(a: LayerToNode, b: LayerToNode) -> bool {
        return a.layer_index < b.layer_index
    })
    return lowest_to_highest
}

drawLayerNodes :: proc (manager: ^LayerManager, node_manager: ^NodeManager) {
    for layer_node in manager.layer_nodes_sorted {

        // Check if layer is present, allowed and visible before drawing nodes
        layer := manager->getLayerByZIndex(layer_node.layer_index)
        if (layer == nil && !manager.allow_nonexistent_layers) {
            continue
        }
        else if (layer != nil && !layer.visible) {
            continue
        }

        // Draw node if visible and in correct layer
        node_ptr := node_manager->getNodeByIndex(layer_node.node_index)
        if node_ptr != nil {
            node := cast(^Node)node_ptr
            node->globalTransform()
            if node.visible && node.layer == layer_node.layer_index {
                if node.draw != nil {
                    node.draw(cast(rawptr)node)
                }
            }
        }
    }
}

clearLayerNodes :: proc (manager: ^LayerManager) {
    clear(&manager.layer_nodes)
    manager.layers_changed = true
}
