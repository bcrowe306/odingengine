package main

import fmt "core:fmt"

listenerSignature :: proc(args: ..any)


Signal :: struct ($T: typeid) {
    name: string,
    listeners: [dynamic]proc(arg1: T, args: ..any)
}

createSignal :: proc($T: typeid) -> ^Signal(T) {
    s := new(Signal(T))
    return s
}

signalConnect :: proc(signal: ^Signal($T), listener: proc(arg1: T, args: ..any)) {
    append(&signal.listeners, listener)
}

signalEmit :: proc(signal: ^Signal($T), arg1: T) {
    for listener in signal.listeners {
        if listener != nil {
            listener(arg1)
        }
    }
}
signalDisconnect :: proc(signal: ^Signal($T), listener: proc(arg1: T)) {
    for l, index in signal.listeners {
        if l == listener {
            ordered_remove(&signal.listeners, index)
            break
        }
    }
}
signalClear :: proc(s: ^Signal) {
    clear(&s.listeners)
}