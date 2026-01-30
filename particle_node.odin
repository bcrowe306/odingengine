package main

import "core:math/ease"
import "base:runtime"
import "vendor:box2d"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:mem"
import "core:math"
import "core:math/rand"

MAX_PARTICLES: int : 100000


ParticleEmitterShape :: enum {
    Point,
    Circle,
    Box,
}
ParticleType :: enum {
    Circle,
    Rectangle,
    Texture,
}

Particle :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    rotation: f32,
    rotation_speed: f32,
    color: rl.Color,
    life: f32,
    size: rl.Vector2,
}

ParticleNode :: struct {
    using node: Node,
    initial_velocity: f32, // Initial speed of particles in pixels per second
    one_shot: bool, // If true, emits particles only once
    emitting: bool, // Whether the emitter is currently emitting particles
    velocity_randomness: f32, // float between 0.0 and 1.0
    initial_direction: rl.Vector2, // Normalized direction vector
    spread: f32, // Spread angle in degrees. this will rotate the initial direction randomly within this angle to create spread; 0 = no spread (only initial direction)
    acceleration: f32, // Acceleration in pixels per second
    rotation: f32, // Rotation in degrees
    rotation_randomness: f32, // Rotation randomness; float between 0.0 and 1.0
    rotation_speed: f32, // Rotation speed in degrees per second
    rotation_speed_randomness: f32, // float between 0.0 and 1.0
    rotation_acceleration: f32, // Rotation acceleration in degrees per second
    particle_life: f32, // How long each particle lives, in seconds
    particle_amount: f32, // The amount of particles to emit over lifetime
    explosivity: f32, // How explosive the emission is; 0.0 to 1.0
    particle_gravity: rl.Vector2, // Vector for gravity, pixels per second
    size: rl.Vector2, // Base size of particle
    size_randomness: f32, // Size randomness; float between 0.0 and 1.0
    size_start: f32, // Size scale of particle at start of life; 0.0 to 1.0
    size_end: f32, // Size scale of particle at end of life; 0.0 to 1.0
    size_curve: ease.Ease, // Easing curve for size over lifetime
    emitter_shape: ParticleEmitterShape, // Shape of the emitter
    particle_type: ParticleType, // Type of particle to render
    _particle_index: int,
    _particles: [MAX_PARTICLES]Particle,
    _alive_particles: [dynamic]int,
    _dead_particles: [dynamic][2]int, // p_index, a_index
    _p_duration_accum: f32,
    _lifetime_accum: f32,
    _lifetime_particle_count: int,
    slider_height: f32,
    slider_width: f32,
    slider_x: f32,
    particle_type_dropdown_state: GuiDropdownState,
    editor: bool, // Toggle editor GUI
}

GuiDropdownState :: struct {
    is_open: bool,
    selected_index: i32,
}

createParticleNode :: proc (name: string, position: rl.Vector2) -> ^ParticleNode {
    pn := new(ParticleNode)
    setNodeDefaults(cast(^Node)pn, name)
    pn.name = name
    pn.transform.position = position
    pn.initial_velocity = 100.0
    pn.emitting = true
    pn.velocity_randomness = 0.2
    pn.initial_direction = rl.Vector2{0, -1}
    pn.spread = 15.0
    pn.one_shot = false
    pn.acceleration = 0.0
    pn.rotation = 0.0
    pn.rotation_randomness = 0.0
    pn.rotation_speed = 0.0
    pn.rotation_speed_randomness = 0.0
    pn.rotation_acceleration = 0.0
    pn.particle_life = 2.0
    pn.particle_amount = 10.0
    pn.explosivity = 0.0
    pn.particle_gravity = rl.Vector2{0, 200.0}
    pn.size = rl.Vector2{8, 8}
    pn.size_randomness = 0.2
    pn.size_start = 1.0
    pn.size_end = 1.0
    pn.size_curve = ease.Ease.Linear
    pn.emitter_shape = ParticleEmitterShape.Point
    pn.particle_type = ParticleType.Circle
    pn._particle_index = 0
    pn._p_duration_accum = 0.0
    pn._lifetime_accum = 0.0
    pn._lifetime_particle_count = 0
    pn.slider_height = 10.0
    pn.slider_width = 300.0
    pn.slider_x = GAME.window_size.x - (pn.slider_width + 50)
    pn.node.process = processParticleNode
    pn.node.draw = drawParticleNode
    pn.editor = false
    return pn
}

processParticleNode :: proc (pn_ptr: rawptr, delta_time: f32) {
    pn := cast(^ParticleNode)pn_ptr
    using pn

    // Particle System Test
        _p_duration_accum += delta_time
        _lifetime_accum += delta_time

        // Check lifetime
        if _lifetime_accum >= particle_life {
            fmt.printfln("Total Particles Created in Lifetime: %d", _lifetime_particle_count)
            if one_shot {
                emitting = false
            }
            else {
                emitting = true
            }
            _lifetime_accum = 0.0
            _lifetime_particle_count = 0
            
        }

        // Stop emitting if one_shot and reached particle amount
        if _lifetime_particle_count >= int(particle_amount) {
            emitting = false
        }

        p_dur := math.lerp(particle_life / particle_amount, 0.0, explosivity)
        if _p_duration_accum >= p_dur {

            if emitting {
                // Determine how many particles to create based on accumulated time
                particles_to_create := 1
                if _p_duration_accum > p_dur {
                    if p_dur == 0.0 {
                        particles_to_create = int(particle_amount)
                    }
                    else {
                        particles_to_create = int(_p_duration_accum / p_dur)
                        
                    }
                    if particles_to_create > 1 {
                        fmt.printfln("Creating %d particles", particles_to_create)
                    }
                    
                }

                // Create the particles
                for i in 0..<particles_to_create {

                    pIndex := _particle_index
                    _particle_index = (_particle_index + 1) % MAX_PARTICLES

                    // Generate random velocity and size
                    random_velocity := math.lerp(initial_velocity * (1.0 - velocity_randomness), initial_velocity * (1.0 + velocity_randomness), rand.float32())
                    dir := initial_direction
                    s := size * math.lerp(1.0 - size_randomness, 1.0 + size_randomness, rand.float32())

                    if rl.Vector2Equals(dir, rl.Vector2{0,0}) && spread != 0.0 {
                        dir = rl.Vector2Rotate([2]f32{1,0}, math.to_radians_f32(rand.float32_range(-spread, spread)))
                    }
                    else {
                        dir = rl.Vector2Rotate(dir, math.to_radians_f32(rand.float32_range(-spread, spread)))
                    }
                    iVel := random_velocity * rl.Vector2Normalize(dir)

                    // Randomize rotation
                    rot := rotation + rand.float32_range(-rotation_randomness * 360.0, rotation_randomness * 360.0)
                    low := -rotation_speed_randomness * rotation_speed
                    high := rotation_speed_randomness * rotation_speed
                    if low > high {
                        temp := low
                        low = high
                        high = temp
                    }
                    rot_speed := rotation_speed + rand.float32_range(low, high)

                    // Create particle
                    _particles[pIndex] = Particle{
                        position = transform.global_pos,
                        rotation = rot,
                        rotation_speed = rot_speed,
                        size = s,
                        velocity = iVel,
                        color = rl.Fade(rl.ORANGE, 0.5),
                        life = particle_life,
                    }
                    append(&_alive_particles, pIndex)
                    _lifetime_particle_count += 1
                    
                }
                    
                
            }
            _p_duration_accum = 0.0
        }
       

        // Update particles
        for p_index, a_index in _alive_particles {
            p := &_particles[p_index]
            
            if p.life > 0.0 {

                // Update velocity with gravity
                p.velocity += rl.Vector2Normalize(p.velocity) * acceleration * delta_time
                p.velocity += particle_gravity * delta_time

                // Update position
                p.position += p.velocity * delta_time

                // Update rotation
                p.rotation_speed += rotation_acceleration * delta_time
                p.rotation += p.rotation_speed * delta_time

                // Decrease life
                p.life -= delta_time
                
            }
            else {
                append(&_dead_particles, [2]int{p_index, a_index})
            }
        }

        // Traverse reversely to safely remove dead particles
        for i := len(_dead_particles) - 1; i >= 0; i -= 1 {

            p_index := _dead_particles[i][0]
            a_index := _dead_particles[i][1]
            // Remove from alive_particles
            ordered_remove(&_alive_particles, a_index)
            // Optionally reset particle data here if needed
        }
        clear(&_dead_particles)
        // resize(&_dead_particles, 0)
        // resize(&_alive_particles, len(_alive_particles))
}


drawParticleNode :: proc (pn_ptr: rawptr) {
    pn := cast(^ParticleNode)pn_ptr
    using pn

    for p_index in _alive_particles {
        particle := &_particles[p_index]

        // calculate lifetime progress
        progress := ease.ease(size_curve, 1.0 - (particle.life / particle_life))

        switch particle_type {
            case .Rectangle:
                // Draw rectangle particle
                radius_x := particle.size.x * 0.5
                radius_y := particle.size.y * 0.5
                radius_x *= math.lerp(size_start, size_end, progress)
                radius_y *= math.lerp(size_start, size_end, progress)
                rl.DrawRectanglePro(
                    rl.Rectangle{particle.position.x - radius_x, particle.position.y - radius_y, radius_x * 2, radius_y * 2},
                    rl.Vector2{radius_x, radius_y},
                    particle.rotation,
                    particle.color,
                )
            case .Circle:
                // Draw circle particle
                radius := min(particle.size.x, particle.size.y) * 0.5
                
                radius *= math.lerp(size_start, size_end, progress)
                rl.DrawCircleV(particle.position, radius, particle.color)
            case .Texture:
                // Draw textured particle (placeholder, implement texture handling as needed)
        }
    }
    if editor {
        drawParticleEditorGui(pn)
    }
}

drawParticleEditorGui :: proc(pn: ^ParticleNode) {
    using pn

    rl.GuiSliderBar({slider_x, 15, slider_width, slider_height}, "Amount", fmt.caprintf("%f", particle_amount), &particle_amount, 1.0, 2000.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 30,  slider_width, slider_height}, "Particle Life", fmt.caprintf("%f", particle_life), &particle_life, 0.0001, 5.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 45,  slider_width, slider_height}, "Spread", fmt.caprintf("%f", spread), &spread, 0.001, 360.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 60,  slider_width, slider_height}, "Velocity", fmt.caprintf("%f", initial_velocity), &initial_velocity, 0.000, 1000)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 75,  slider_width, slider_height}, "Velocity Randomness", fmt.caprintf("%f", velocity_randomness), &velocity_randomness, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 90,  slider_width, slider_height}, "Acceleration", fmt.caprintf("%f", acceleration), &acceleration, -2000, 2000)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 105, slider_width, slider_height}, "Size X", fmt.caprintf("%f", size.x), &size.x, 0.0, 100.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 120, slider_width, slider_height}, "Size Y", fmt.caprintf("%f", size.y), &size.y, 0.0, 100.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 135, slider_width, slider_height}, "Size Randomness", fmt.caprintf("%f", size_randomness), &size_randomness, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 150, slider_width, slider_height}, "Size Start", fmt.caprintf("%f", size_start), &size_start, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 165, slider_width, slider_height}, "Size End", fmt.caprintf("%f", size_end), &size_end, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 180, slider_width, slider_height}, "Gravity Y", fmt.caprintf("%f", particle_gravity.y), &particle_gravity.y, -2000.0, 2000.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 195, slider_width, slider_height}, "Direction X", fmt.caprintf("%f", initial_direction.x), &initial_direction.x, -1.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 210, slider_width, slider_height}, "Direction Y", fmt.caprintf("%f", initial_direction.y), &initial_direction.y, -1.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 225, slider_width, slider_height}, "Explosivity", fmt.caprintf("%f", explosivity), &explosivity, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 255, slider_width, slider_height}, "Rotation", fmt.caprintf("%f", rotation), &rotation, 0.0, 360.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 270, slider_width, slider_height}, "Rotation Randomness", fmt.caprintf("%f", rotation_randomness), &rotation_randomness, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 285, slider_width, slider_height}, "Rotation Speed", fmt.caprintf("%f", rotation_speed), &rotation_speed, -1000.0, 1000.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 300, slider_width, slider_height}, "Rotation Speed Randomness", fmt.caprintf("%f", rotation_speed_randomness), &rotation_speed_randomness, 0.0, 1.0)
    rl.GuiSliderBar(rl.Rectangle{slider_x, 315, slider_width, slider_height}, "Rotation Acceleration", fmt.caprintf("%f", rotation_acceleration), &rotation_acceleration, -360.0, 360.0)
    rl.GuiCheckBox(rl.Rectangle{slider_x, 240, 10, 10}, "One Shot", &one_shot)

    if rl.GuiDropdownBox(rl.Rectangle{slider_x, 330, slider_width, slider_height}, "Circle;Rectangle;Texture", &particle_type_dropdown_state.selected_index, particle_type_dropdown_state.is_open) {
        // Dropdown selection changed
        particle_type_dropdown_state.is_open = !particle_type_dropdown_state.is_open
        particle_type = cast(ParticleType)particle_type_dropdown_state.selected_index

    }
    
}
    