package main 

import "core:fmt"
import "core:encoding/json"
import "core:os"
import "core:path/filepath"
import rl "vendor:raylib"


// TODO: Add support for more Tiled features (object layers, tile properties, etc.)
// TODO: Use Tiled objects for collision shapes in Box2D. Need to use object properties to define shape types.
// TODO: Make use of Tiled layers and render them in order.

TiledPoint :: struct {
    x: f64, //X coordinate of the point
    y: f64, //Y coordinate of the point
}

TiledProperty :: struct {
    name: string, // Name of the property
    type: string, // Type of the property (string (default), int, float, bool, color, file, object or class (since 0.16, with color and file added in 0.17, object added in 1.4 and class added in 1.8))
    propertytype: string, // Name of the custom property type, when applicable (since 1.8)
    value: string, // Value of the property 
}

TiledObject :: struct {
    ellipse: bool, //Used to mark an object as an ellipse
    gid: int, //Global tile ID, only if object represents a tile
    height: f64, //Height in pixels.
    id: int, //Incremental ID, unique across all objects
    name: string, //String assigned to name field in editor
    point: bool, //Used to mark an object as a point
    polygon: []TiledPoint, //Array of Points, in case the object is a polygon
    polyline: []TiledPoint, //Array of Points, in case the object is a polyline
    properties: []TiledProperty, //Array of Properties
    rotation: f64, //Angle in degrees clockwise
    template: string, //Reference to a template file, in case object is a template instance
    text: TiledText, //Only used for text objects
    type: string, //The class of the object (was saved as class in 1.9, optional)
    visible: bool, //Whether object is shown in editor.
    width: f64, //Width in pixels.
    x: f64, //X coordinate in pixels
    y: f64, //Y coordinate in pixels
}


TiledChunk :: struct {
    data: []u32, // Array of unsigned int (GIDs) or base64-encoded data
    height: int, // Height of the chunk in tiles
    width: int, // Width of the chunk in tiles
    x: int, // X coordinate of the chunk in tiles
    y: int, // Y coordinate of the chunk in tiles
}

TiledText :: struct {
    bold: bool, // Whether the text is bold (default: false)
    color: string, // Hex-formatted color (#RRGGBB or #AARRGGBB) (default: #000000)
    fontfamily: string, // Font family (since 1.9, default: sans-serif)
    halign: string, // horizontal alignment (left, center, right) (default: left)
    italic: bool, // Whether the text is italic (default: false)
    kerning: bool, // Whether kerning is enabled (default: true)
    pixelsize: int, // Font size in pixels (default: 16)
    strikeout: bool, // Whether the text is strikeout (default: false)
    underline: bool, // Whether the text is underlined (default: false)
    valign: string, // vertical alignment (top, center, bottom) (default: top)
    wrap: bool, // Whether the text is wrapped (default: false)
    text: string, // The actual text
}

TiledGrid :: struct {
    orientation: string, //orthogonal, isometric, staggered or hexagonal
    width: int, //Width of a single grid cell in pixels
    height: int, //Height of a single grid cell in pixels
}

TiledTileOffset :: struct {
    x: int, //Horizontal offset in pixels
    y: int, //Vertical offset in pixels
}

TiledTransformations :: struct {
    flipdiagonal: bool, //Whether diagonal flipping is allowed
    fliphorizontal: bool, //Whether horizontal flipping is allowed
    flipvertical: bool, //Whether vertical flipping is allowed
}

TiledFrame :: struct {
    duration: int, //Duration to display this frame in milliseconds
    tileid: int, //The local tile ID
}

TiledWangSet :: struct {
    class: string, //The class of the Wang set (since 1.9, optional)
    colors: []TiledWangColor, //Array of Wang colors (since 1.5)
    name: string, //Name of the Wang set
    properties: []TiledProperty, //Array of Properties
    tile: int, //Local ID of tile representing the Wang set
    type: string, //corner, edge or mixed (since 1.5)
    wangtiles: []TiledWangTile, //Array of Wang tiles
}

TiledWangColor :: struct {
    class : string, //The class of the Wang color (since 1.9, optional)
    color: string, //Hex-formatted color (#RRGGBB)
    name: string, //Name of the Wang color
    probability: f64, //The probability for this color to be chosen when generating Wang tiles (since 1.0.0)
    properties: []TiledProperty, //Array of Properties
    tile: int, //Local ID of tile representing this color
}

TiledWangTile :: struct {
    wangid: []u32, //Array of Wang color indices
    tileid: int, //The local tile ID
}

TiledTile :: struct {
    animation: []TiledFrame, //Array of Frames (optional)
    id: int, //Local ID of the tile
    image: string, //Image used for this tile (optional)
    imageheight: int, //Height of source image in pixels (optional)
    imagewidth: int, //Width of source image in pixels (optional)
    x: int, //X position of the tile in tileset image (since 1.6)
    y: int, //Y position of the tile in tileset image (since 1
    width: int, //Width of the tile in pixels (since 1.6)
    height: int, //Height of the tile in pixels (since 1.6)
    objectgroup: TiledLayer, // Layer with type objectgroup, when collision shapes are specified (optional)
    probability: f64, //The probability for this tile to be chosen when it is part of a Wang set or Terrain (since 1.0.0)
    properties: []TiledProperty, //Array of Properties
    terrain: []int, //Array of terrain indices (since 1.0.0)
    type: string, //The type of the tile (since 1.0)
    tileanimationspeed: f32, //Speed multiplier for tile animations (default: 1.0) (since 1.9)
}

TiledTerrain :: struct {
    name: string, //Name of the terrain
    properties: []TiledProperty, //Array of Properties
    tile: int, //Local ID of tile representing this terrain
}

TiledTileset :: struct {
    backgroundcolor: string, //Hex-formatted color (#RRGGBB or #AARRGGBB) (optional)
    class: string, //The class of the tileset (since 1.9, optional)
    columns: int, //The number of tile columns in the tileset
    fillmode: string, //The fill mode to use when rendering tiles from this tileset
    firstgid: int, //GID corresponding to the first tile in the set
    grid: TiledGrid, // (optional)
    image: string, //Image used for tiles in this set
    imageheight: int, //Height of source image in pixels
    imagewidth: int, //Width of source image in pixels
    margin: int, //Buffer between image edge and first tile (pixels)
    name: string, //Name given to this tileset
    objectalignment: string, //Alignment to use for tile objects (since 1.4
    properties: []TiledProperty, //Array of Properties
    source: string, //The external file that contains this tilesets data
    spacing: int, //Spacing between adjacent tiles in image (pixels)
    terrains: []TiledTerrain, //Array of Terrains (optional)
    tilecount: int, //The number of tiles in this tileset
    tiledversion: string, //The Tiled version used to save the file
    tileheight: int, //Maximum height of tiles in this set
    tileoffset: TiledTileOffset, // (optional)
    tilerendersize: string, //The size to use when rendering tiles from this tileset on a tile layer (since 1.9)
    tiles: []TiledTile, //Array of Tiles (optional)
    tilewidth: int, //Maximum width of tiles in this set
    transformations: TiledTransformations, //Allowed transformations (optional)
    transparentcolor: string, //Hex-formatted color (#RRGGBB) (optional)
    type: string, //tileset (for tileset files, since 1.0)
    version: string, //The JSON format version (previously a number, saved as string since 1.6)
    wangsets: []TiledWangSet, //Array of Wang sets (since 1.1.5)
}


TiledMap :: struct {
    backgroundcolor: string, //Hex-formatted color (#RRGGBB or #AARRGGBB) (optional)
    class: string, //The class of the map (since 1.9, optional)
    compressionlevel: int, //The compression level to use for tile layer data (defaults to -1, which means to use the algorithm default)
    height: int, //Number of tile rows
    hexsidelength: int, //Length of the side of a hex tile in pixels (hexagonal maps only)
    infinite: bool, //Whether the map has infinite dimensions
    layers: []TiledLayer, //Array of Layers
    nextlayerid: int, //Auto-increments for each layer
    nextobjectid: int, //Auto-increments for each placed object
    orientation: string, //orthogonal, isometric, staggered or hexagonal
    parallaxoriginx: f64, //X coordinate of the parallax origin in pixels (since 1.8, default: 0)
    parallaxoriginy: f64, //Y coordinate of the parallax origin in pixels (since 1.8, default: 0)
    properties: []TiledProperty, //Array of Properties
    renderorder: string, //right-down (the default), right-up, left-down or left-up (currently only supported for orthogonal maps)
    staggeraxis: string, //x or y (staggered / hexagonal maps only)
    staggerindex: string, //odd or even (staggered / hexagonal maps only)

    tiledversion: string, //The Tiled version used to save the file
    tileheight: int, //Map grid height
    tilesets: []TiledTileset, //Array of Tilesets
    tilewidth: int, //Map grid width
    type: string, //map (since 1.0)
    version: string, //The JSON format version (previously a number, saved as string since 1.6)
    width: int, //Number of tile columns

}


TiledLayer :: struct {
    chunks: []TiledChunk, //Array of chunks (optional). tilelayer only.
    class: string, //The class of the layer (since 1.9, optional)
    compression: string, //zlib, gzip, zstd (since 1.3) or empty (default). tilelayer only.
    data: []u32, //Array of unsigned int (GIDs) or base64-encoded data. tilelayer only.
    draworder: string, //topdown (default) or index. objectgroup only.
    encoding: string, //csv (default) or base64. tilelayer only.
    height: int, //Row count. Same as map height for fixed-size maps. tilelayer only.
    id: int, //Incremental ID - unique across all layers
    image: string, //Image used by this layer. imagelayer only.
    imageheight: int, //Height of the image used by this layer. imagelayer only. (since 1.11.1)
    imagewidth: int, //Width of the image used by this layer. imagelayer only. (since 1.11.1)
    layers: []TiledLayer, //Array of layers. group only.
    locked: bool, //Whether layer is locked in the editor (default: false). (since 1.8.2)
    name: string, //Name assigned to this layer
    objects: []TiledObject, //Array of objects. objectgroup only.
    offsetx: f64, //Horizontal layer offset in pixels (default: 0)
    offsety: f64, //Vertical layer offset in pixels (default: 0)
    opacity: f64, //Value between 0 and 1
    parallaxx: f64, //Horizontal parallax factor for this layer (default: 1). (since 1.5)
    parallaxy: f64, //Vertical parallax factor for this layer (default: 1). (since 1.5)
    properties: []TiledProperty, //Array of Properties
    repeatx: bool, //Whether the image drawn by this layer is repeated along the X axis. imagelayer only. (since 1.8)
    repeaty: bool, //Whether the image drawn by this layer is repeated along the Y axis. imagelayer only. (since 1.8)
    startx: int, //X coordinate where layer content starts (for infinite maps)
    starty: int, //Y coordinate where layer content starts (for infinite maps)
    tintcolor: string, //Hex-formatted tint color (#RRGGBB or #AARRGGBB) that is multiplied with any graphics drawn by this layer or any child layers (optional).
    transparentcolor: string, //Hex-formatted color (#RRGGBB) (optional). imagelayer only.
    type: string, //tilelayer, objectgroup, imagelayer or group
    visible: bool, //Whether layer is shown or hidden in editor
    width: int, //Column count. Same as map width for fixed-size maps. tilelayer only.
    x: int, //Horizontal layer offset in tiles. Always 0.
    y: int, //Vertical layer offset in tiles. Always 0.
}


loadTilesetFromJsonFile :: proc (tile_set: ^TiledTileset, file_directory: string, file_name: string) {
    file_path := filepath.join({file_directory, file_name})
    if file_data, success := os.read_entire_file(file_path); success {
        json.unmarshal(file_data, tile_set)
        return 
    }
    else {
        fmt.println("Failed to read tileset file: ", file_path)
        return
    }
    
}

loadMapFromJsonFile :: proc (file_directory: string, file_name: string) -> ^TiledMap {
    file_path := fmt.tprintf("%s/%s", file_directory, file_name)
    file_data, success := os.read_entire_file(file_path, )
    if !success {
        fmt.println("Failed to read file: ", file_path)
        return nil
    }

    tiled_map: ^TiledMap = new(TiledMap)
    err := json.unmarshal(file_data, tiled_map)
    if err != nil {
        fmt.println("Failed to parse JSON: ", err)
        return nil
    }
    for &tile_set in &tiled_map.tilesets {
        if tile_set.source != "" {
            tile_set.source = fmt.tprintf("%s.tsj", filepath.short_stem(tile_set.source))
            loadTilesetFromJsonFile(&tile_set, file_directory, tile_set.source)

        }
    }
    return tiled_map
}


TileMapNode :: struct {
    using node: Node,
    tiled_map: ^TiledMap,
    tiled_map_path: string,
    tileset_textures: map[string]rl.Texture2D, // Map of firstgid to texture
    resource_manager: ^ResourceManager,
}


createTileMapNode :: proc (tiled_map_path: string, resource_manager: ^ResourceManager) -> ^TileMapNode {
    tile_map_node := new(TileMapNode)
    setNodeDefaults(&tile_map_node.node, "TileMapNode")
    tile_map_node.type = NodeType.TileMapNode
    tile_map_node.tiled_map_path = tiled_map_path
    tile_map_node.resource_manager = resource_manager

    // Load the Tiled map
    dir := filepath.dir(tiled_map_path)
    file := filepath.base(tiled_map_path)
    tile_map_node.tiled_map = loadMapFromJsonFile(dir, file)
    if tile_map_node.tiled_map == nil {
        fmt.println("Failed to load Tiled map from: ", tiled_map_path)
        return nil
    }

    // Load tileset textures
    for &tile_set in &tile_map_node.tiled_map.tilesets {
        texture := resource_manager->loadTexture(filepath.join({dir, tile_set.image}))
        tile_map_node.tileset_textures[tile_set.source] = texture
    }

    // Create collision shapes from Tiled objects in "CollisionLayer"
    // TODO: Make this configurable per map. Also needs to be in seperate function for greater control
    tile_map_node.draw = drawTileMapNode
    for &layer in &tile_map_node.tiled_map.layers {
        if layer.type == "objectgroup" && layer.name == "CollisionLayer" {
            for &object in &layer.objects {
                createStaticBodyBox2d(GAME.world_id, rl.Vector2{f32(object.x), f32(object.y)}, rl.Vector2{f32(object.width), f32(object.height)}, f32(object.rotation))
            }
        }
    }
    return tile_map_node
}

_getChunkPosition :: proc (tiled_chunk: ^TiledChunk, tile_width: int, tile_height: int) -> [2]f32 {
    x := tiled_chunk.x * tile_width
    y := tiled_chunk.y * tile_height
    return {f32(x), f32(y)}
}

_getTilePosition :: proc (layer_index: int, chunk_index: int, tile_index: u32, tile_map: ^TiledMap) -> [2]f32 {
    chunk_position := _getChunkPosition(&tile_map.layers[layer_index].chunks[chunk_index], tile_map.tilewidth, tile_map.tileheight)
    tiles_per_row := tile_map.layers[layer_index].chunks[chunk_index].width
    local_position : [2]f32= {
        f32((tile_index % u32(tiles_per_row)) * u32(tile_map.tilewidth)),
        f32((tile_index / u32(tiles_per_row)) * u32(tile_map.tileheight))
    }
    return chunk_position + local_position
}

_getSourceTileRect :: proc (tile_id: u32, tile_set: ^TiledTileset) -> rl.Rectangle {
    local_id := tile_id - u32(tile_set.firstgid)
    tiles_per_row := tile_set.columns
    x := f32((local_id % u32(tiles_per_row)) * u32(tile_set.tilewidth))
    y := f32((local_id / u32(tiles_per_row)) * u32(tile_set.tileheight))
    return rl.Rectangle{
        x = x,
        y = y,
        width = f32(tile_set.tilewidth),
        height = f32(tile_set.tileheight),
    }
}

_getDestRect :: proc (tile_position: [2]f32, tile_set: ^TiledTileset) -> rl.Rectangle {
    return rl.Rectangle{
        x = tile_position[0],
        y = tile_position[1],
        width = f32(tile_set.tilewidth),
        height = f32(tile_set.tileheight),
    }
}

_getTileSetForTileID :: proc (tile_id: u32, tiled_map: ^TiledMap) -> ^TiledTileset {
    for &tileset in &tiled_map.tilesets {
        if tile_id >= u32(tileset.firstgid) && tile_id < u32(tileset.firstgid + tileset.tilecount) {
            return &tileset
        }
    }
    return nil
}


drawTileMapNode :: proc (tile_map_node_ptr: rawptr) {
    tile_map_node: ^TileMapNode = cast(^TileMapNode)tile_map_node_ptr
    tiled_map := tile_map_node.tiled_map
    for layer, layer_index in &tiled_map.layers {
        if layer.type != "tilelayer" || !layer.visible {
            continue
        }
        for chunk, chunk_index in layer.chunks {
            for tile_id, tile_index in chunk.data {
                if tile_id == 0 {
                    continue // Empty tile
                }
                
                tile_set := _getTileSetForTileID(tile_id, tiled_map)
                if tile_set == nil {
                    continue // No tileset found
                }
                tile_set_texture := tile_map_node.tileset_textures[tile_set.source]
                tile_position := _getTilePosition(layer_index, chunk_index, u32(tile_index), tiled_map)
                source_rect := _getSourceTileRect(tile_id, tile_set)
                dest_rect := _getDestRect(tile_position, tile_set)
                rl.DrawTexturePro(
                    tile_set_texture,
                    source_rect,
                    dest_rect,
                    rl.Vector2{0, 0},
                    0.0,
                    rl.WHITE,
                )
            }
        }
    }
}



