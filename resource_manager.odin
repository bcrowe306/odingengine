package main

import rl "vendor:raylib"
import fmt "core:fmt"

DEFAULT_FONTS :: [][2]string {
    {"open_sans", "resources/Open_Sans/static/OpenSans-MediumItalic.ttf"},
}

FontResource :: struct {
    font: rl.Font,
    ref_count: u32,
    file_path: string,
    name: string,
}

TextureResource :: struct {
    texture: rl.Texture2D,
    ref_count: u32,
    file_path: string,
    name: string,
}

ResourceManager :: struct {
    textures: map[string]TextureResource,
    sounds: map[string]rl.Sound,
    fonts: map[string]FontResource,
    loadTexture: proc(rm: ^ResourceManager, path: string) -> rl.Texture2D,
    loadSound: proc(rm: ^ResourceManager, path: string) -> rl.Sound,
    freeResources: proc(rm: ^ResourceManager),
    loadFont: proc(rm: ^ResourceManager, path: string, name: string) -> rl.Font,
    loadDefaultFonts: proc(rm: ^ResourceManager),
    getFont: proc(rm: ^ResourceManager, name: string) -> rl.Font,

}

createResourceManager :: proc() -> ^ResourceManager {
    rm := new(ResourceManager)
    rm.textures = map[string]TextureResource{}
    rm.sounds = map[string]rl.Sound{}
    rm.fonts = map[string]FontResource{}
    rm.loadTexture = loadTexture
    rm.loadSound = loadSound
    rm.freeResources = freeResources
    rm.loadFont = loadFont
    rm.loadDefaultFonts = loadDefaultFonts
    rm.getFont = getFont

    return rm
}

loadSound :: proc(rm: ^ResourceManager, path: string) -> rl.Sound {
    if sound, exists := rm.sounds[path]; exists {
        return sound
    } else {
        sound := rl.LoadSound(fmt.ctprint(path))
        rm.sounds[path] = sound
        return sound
    }
}



loadTexture :: proc(rm: ^ResourceManager, path: string) -> rl.Texture2D {
    if texture_resource, exists := rm.textures[path]; exists {
        return texture_resource.texture
    } else {
        texture := rl.LoadTexture(fmt.ctprint(path))
        rm.textures[path] = TextureResource{texture, 1, path, path}
        return texture
    }
}

loadFont :: proc(rm: ^ResourceManager, path: string, name: string) -> rl.Font {
    if font_resource, exists := rm.fonts[path]; exists {
        font_resource.ref_count += 1
        return font_resource.font
    } else {
        font := rl.LoadFont(fmt.ctprint(path))
        rm.fonts[path] = FontResource{font, 1, path, name}
        return font
    }
}
getFont :: proc(rm: ^ResourceManager, name: string) -> rl.Font {
    for _, font_resource in rm.fonts {
        if font_resource.name == name {
            fmt.printfln("Retrieved Font: %s", name)
            return font_resource.font
        }
    }
    return rl.Font{}
}

loadDefaultFonts :: proc(rm: ^ResourceManager) {
    for font_info, index in DEFAULT_FONTS {
        name := font_info[0]
        path := font_info[1]
        loadFont(rm, path, name)
    }
}

freeResources :: proc(rm: ^ResourceManager) {
    for i, texture_resource in rm.textures {
        rl.UnloadTexture(texture_resource.texture)
    }
    clear(&rm.textures)

    for _, sound in rm.sounds {
        rl.UnloadSound(sound)
    }
    clear(&rm.sounds)
}