package main
import rl "vendor:raylib"
import fmt "core:fmt"

Text2D :: struct {
    using node: Node,
    text: string,
    font_size: i32,
    color: rl.Color,
    font: rl.Font,
    resource_manager: ^ResourceManager,
    is_font_loaded: bool,
}

createText2D :: proc(rm: ^ResourceManager, name: string = "", text: string = "", font: string = "", font_size: i32 = 20, color: rl.Color = rl.WHITE) -> ^Text2D {
    text2d := new(Text2D)
    text2d.type = NodeType.Text2D
    setNodeDefaults(cast(^Node)text2d, name)
    text2d.text = text
    text2d.font_size = font_size
    text2d.color = color
    text2d.resource_manager = rm
    if font == "" {
        text2d.is_font_loaded = false
    }
    else {
        text2d.is_font_loaded = true
         text2d.font = rm->getFont(font)
    }
    text2d.draw = drawText2D
    return text2d
}


drawText2D :: proc(node_ptr: rawptr) {
    node := cast(^Text2D)node_ptr
    if node.is_font_loaded  {
        rl.DrawTextEx(node.font, fmt.ctprint(node.text), rl.Vector2{node.transform.global_pos.x, node.transform.global_pos.y}, cast(f32)node.font_size, 1.0, node.color)
    }
    else {
        rl.DrawText(fmt.ctprint(node.text), cast(i32)node.transform.global_pos.x, cast(i32)node.transform.global_pos.y, node.font_size, node.color)
    }
    
}
