package main

import rl "vendor:raylib"
import math "core:math"


minkowski_difference :: proc(a: rl.Rectangle, b: rl.Rectangle) -> rl.Rectangle {
    left := a.x - (b.x + b.width)
    right := (a.x + a.width) - b.x
    top := a.y - (b.y + b.height)
    bottom := (a.y + a.height) - b.y

    return rl.Rectangle{left, top, right - left, bottom - top}
}

