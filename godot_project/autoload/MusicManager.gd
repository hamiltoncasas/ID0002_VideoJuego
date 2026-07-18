extends Node

var audio_player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var time = 0.0
var running = false

var melody = [262, 294, 330, 392, 440, 523, 588, 440, 392, 330, 294, 262]
var bass = [65, 73, 82, 98, 110, 130, 147, 110, 98, 82, 73, 65]
var melody_idx = 0
var bass_idx = 0
var note_timer = 0.0
var note_duration = 0.5

func _ready():
	audio_player = AudioStreamPlayer.new()
	generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.5
	audio_player.stream = generator
	add_child(audio_player)
	
	# Small delay to let things initialize, then start
	await get_tree().create_timer(0.1).timeout
	_start()

func _start():
	audio_player.play()
	await get_tree().process_frame
	if audio_player.has_stream_playback():
		playback = audio_player.get_stream_playback()
		running = true

func _process(delta):
	if not running or not playback: return
	
	time += delta
	note_timer += delta
	
	var available = playback.get_frames_available()
	if available <= 0: return
	
	var mix = generator.mix_rate
	var to_fill = mini(available, 2048)
	
	if note_timer >= note_duration:
		note_timer = 0
		melody_idx = (melody_idx + 1) % melody.size()
		if melody_idx % 4 == 0:
			bass_idx = (bass_idx + 1) % bass.size()
	
	var buf = PackedVector2Array()
	var mel_freq = melody[melody_idx]
	var bass_freq = bass[bass_idx]
	
	for i in range(to_fill):
		var t = time + float(i) / mix
		
		# Melody
		var mel = sin(t * mel_freq * 2.0 * PI) * 0.08
		# Bass
		var bas = sin(t * bass_freq * 2.0 * PI) * 0.06
		# Pad
		var pad1 = sin(t * (mel_freq * 0.5) * 2.0 * PI) * 0.03
		var pad2 = sin(t * (mel_freq * 0.5 + 0.7) * 2.0 * PI) * 0.03
		
		var env = sin(min(note_timer / note_duration, 1.0) * PI)
		var sample = (mel * env + bas + pad1 + pad2) * 0.4
		buf.append(Vector2(sample, sample))
	
	playback.push_buffer(buf)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		running = false
