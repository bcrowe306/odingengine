package main

import rl "vendor:raylib"

AudioPlayer :: struct {
    using node: Node,
    sound: rl.Sound,
    is_playing: bool,
    volume: f32,
    pitch: f32,
    pan: f32,
    loop: bool,
    resource_manager: ^ResourceManager,
    play: proc(ap: ^AudioPlayer),
    stop: proc(ap: ^AudioPlayer),

}

createAudioPlayer :: proc(rm: ^ResourceManager, name: string = "AudioPlayer", sound_path: string) -> ^AudioPlayer {
    audio_player := new(AudioPlayer)
    setNodeDefaults(cast(^Node)audio_player, name)
    audio_player.type = NodeType.AudioPlayer
    audio_player.resource_manager = rm
    audio_player.sound = rm->loadSound(sound_path)
    audio_player.is_playing = false
    audio_player.volume = 1.0
    audio_player.pitch = 1.0
    audio_player.pan = 0.5
    audio_player.loop = false
    audio_player.play = playAudioPlayerSound
    audio_player.stop = stopAudioPlayerSound
    return audio_player
}

playAudioPlayerSound :: proc(ap: ^AudioPlayer) {
    rl.SetSoundPan(ap.sound, ap.pan)
    rl.SetSoundVolume(ap.sound, ap.volume)
    rl.SetSoundPitch(ap.sound, ap.pitch)
    rl.PlaySound(ap.sound)
}

playRandomPitchAudioPlayerSound :: proc(ap: ^AudioPlayer, min_pitch: f32, max_pitch: f32) {
    
    random_pitch := rl.GetRandomValue(cast(i32)(min_pitch * 100), cast(i32)(max_pitch * 100)) / 100.0
    rl.SetSoundPan(ap.sound, ap.pan)
    rl.SetSoundVolume(ap.sound, ap.volume)
    rl.SetSoundPitch(ap.sound, cast(f32)random_pitch)
    rl.PlaySound(ap.sound)
    rl.SetSoundPitch(ap.sound, ap.pitch)
}

stopAudioPlayerSound :: proc(ap: ^AudioPlayer) {
    rl.StopSound(ap.sound)
}
