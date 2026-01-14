package main

import rl "vendor:raylib"

InputType :: enum {
    Keyboard,
    MouseButton,
}

InputObject :: union {
    rl.KeyboardKey,
    rl.MouseButton,
}

InputDef :: proc(^Input) -> f32

Input :: struct {
    input_type: InputType,
    action_pressed: InputDef,
    action_released: InputDef,
    action_down: InputDef,
    action_up: InputDef,
    object: InputObject,
}



createInput :: proc(object: InputObject) -> ^Input {
    new_input := new(Input)
    switch v in object {
    case rl.KeyboardKey:
        new_input.input_type = InputType.Keyboard
        new_input.object = object
    case rl.MouseButton:
        new_input.input_type = InputType.MouseButton
        new_input.object = object
    }
    new_input.action_pressed = inputActionPressed
    new_input.action_released = inputActionReleased
    new_input.action_down = inputActionDown
    new_input.action_up = inputActionUp
    return new_input
}

inputActionPressed :: proc(input: ^Input) -> f32 {
    switch v in input.object { 
    case rl.MouseButton:
        if rl.IsMouseButtonPressed(v) {
            return 1.0
        } else {
            return 0.0
        }
    case rl.KeyboardKey:

        if rl.IsKeyPressed(v) {
            return 1.0
        } else {
            return 0.0
        }
    }
    return 0.0
}

inputActionReleased :: proc(input: ^Input) -> f32 {
    switch v in input.object {
    case rl.MouseButton:
        if rl.IsMouseButtonReleased(v) {
            return 1.0
        } else {
            return 0.0
        }
    case rl.KeyboardKey:
    
        if rl.IsKeyReleased(v) {
            return 1.0
        } else {
            return 0.0
        }
    }
    return 0.0
}

inputActionDown :: proc(input: ^Input) -> f32 {
    switch v in input.object {
    case rl.MouseButton:
        if rl.IsMouseButtonDown(v) {
            return 1.0
        } else {
            return 0.0
        }
    case rl.KeyboardKey:
        
        if rl.IsKeyDown(v) {
            return 1.0
        } else {
            return 0.0
        }
    }
    return 0.0
}

inputActionUp :: proc(input: ^Input) -> f32 {
    switch v in input.object {
    case rl.MouseButton:
        if rl.IsMouseButtonUp(v) {
            return 1.0
        } else {
            return 0.0
        }
    case rl.KeyboardKey:

        if rl.IsKeyUp(v) {
            return 1.0
        } else {
            return 0.0
        }
    }
    return 0.0
}


Action :: struct {
    name: string,
    inputs: [dynamic]^Input,
    pressed: proc(action: ^Action) -> bool,
    pressed_value: proc(action: ^Action) -> f32,
    released: proc(action: ^Action) -> bool,
    released_value: proc(action: ^Action) -> f32,
    down: proc(action: ^Action) -> bool,
    down_value: proc(action: ^Action) -> f32,
    up: proc(action: ^Action) -> bool,
    up_value: proc(action: ^Action) -> f32,
    addInput: proc(action: ^Action, input: ..^Input),
    deleteInput: proc(action: ^Action, input: ^Input),
}

createAction :: proc(name: string) -> ^Action {
    action := new(Action)
    action.name = name
    action.pressed = actionPressed
    action.pressed_value = actionPressedValue
    action.released = actionReleased
    action.released_value = actionReleasedValue
    action.down = actionDown
    action.down_value = actionDownValue
    action.up = actionUp
    action.up_value = actionUpValue
    action.addInput = addInputToAction
    action.deleteInput = deleteInputFromAction
    return action
}

addInputToAction :: proc(action: ^Action, input: ..^Input) {
    for inp in input{
        append(&action.inputs, inp)
        }
}

deleteInputFromAction :: proc(action: ^Action, input: ^Input) {
    for act_input, index in action.inputs {
        if act_input == input {
            ordered_remove(&action.inputs, index)
            break
        }
    }
}

actionPressed :: proc(action: ^Action) -> bool {
    for input in action.inputs {
        if input.action_pressed(input) > 0.0 {
            return true
        }
    }
    return false
}
actionPressedValue :: proc(action: ^Action) -> f32 {
    total : f32 = 0.0
    for input in action.inputs {
        total += input.action_pressed(input)
    }
    return clamp(total, 0.0, 1.0)
}

actionReleased :: proc(action: ^Action) -> bool {
    for input in action.inputs {
        if input.action_released(input) > 0.0 {
            return true
        }
    }
    return false
}
actionReleasedValue :: proc(action: ^Action) -> f32 {
    total : f32 = 0.0
    for input in action.inputs {
        total += input.action_released(input)
    }
    return clamp(total, 0.0, 1.0)
}

actionDown :: proc(action: ^Action) -> bool {
    for input in action.inputs {
        if input.action_down(input) > 0.0 {
            return true
        }
    }
    return false
}
actionDownValue :: proc(action: ^Action) -> f32 {
    total : f32 = 0.0
    for input in action.inputs {
        total += input.action_down(input)
    }
    return clamp(total, 0.0, 1.0)
}
actionUp :: proc(action: ^Action) -> bool {
    for input in action.inputs {
        if input.action_up(input) > 0.0 {
            return true
        }
    }
    return false
}
actionUpValue :: proc(action: ^Action) -> f32 {
    total : f32 = 0.0
    for input in action.inputs {
        total += input.action_up(input)
    }
    return clamp(total, 0.0, 1.0)
}



ActionsManager :: struct {
    actions: map[string]^Action,
    createAction: proc(am: ^ActionsManager, name: string, inputs: ..^Input) -> ^Action,
    getAction: proc(am: ^ActionsManager, name: string) -> ^Action,
    getAxis: proc(am: ^ActionsManager, positive_value: f32, negative_value: f32) -> f32,
}

createActionsManager :: proc() -> ^ActionsManager {
    am := new(ActionsManager)
    am.actions = map[string]^Action{}
    am.createAction = createActionInManager
    am.getAction = getActionFromManager
    return am
}

createActionInManager :: proc(am: ^ActionsManager, name: string, inputs: ..^Input) -> ^Action {
    if action, exists := am.actions[name]; exists {
        return action
    } else {
        action := createAction(name)
        am.actions[name] = action
        for inp in inputs {
            action->addInput(inp)
        }
        return action
    }
}

getActionFromManager :: proc(am: ^ActionsManager, name: string) -> ^Action {
    if action, exists := am.actions[name]; exists {
        return action
    } else {
        return nil
    }
}

getAxis :: proc(am: ^ActionsManager, positive_value: f32, negative_value: f32) -> f32 {
    axis_value : f32 = 0.0
    axis_value += positive_value
    axis_value -= negative_value
    return clamp(axis_value, -1.0, 1.0)
}