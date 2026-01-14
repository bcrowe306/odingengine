package main

import fmt "core:fmt"

TimerNode :: struct {
    using node: Node,
    duration: f32,
    elapsed: f32,
    repeat: bool,
    active: bool,
    timeout_count: u64,
    on_timeout: Signal(^TimerNode),
}

createTimerNode :: proc(name: string = "", duration: f32 = 1.0, repeat: bool = false, auto_start: bool = false) -> ^TimerNode {
    timer_node := new(TimerNode)
    setNodeDefaults(cast(^Node)timer_node, name)
    timer_node.duration = duration
    timer_node.elapsed = 0.0
    timer_node.repeat = repeat
    timer_node.active = auto_start
    timer_node.process = processTimerNode
    timer_node.on_timeout.name = "on_timeout"
    return timer_node
}

processTimerNode :: proc(node_ptr: rawptr, delta: f32) {
    timer_node := cast(^TimerNode)node_ptr
    if timer_node.active {
        timer_node.elapsed += delta
        if timer_node.elapsed >= timer_node.duration {
            // Timer completed
            timer_node.timeout_count += 1
            signalEmit(&timer_node.on_timeout, timer_node)
            if timer_node.repeat {
                timer_node.elapsed = 0.0
            } else {
                timer_node.active = false
            }
        }
    }
}