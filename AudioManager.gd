extends Node

# Audio Players
var bgm_player: AudioStreamPlayer
var sfx_player_tick: AudioStreamPlayer
var sfx_player_cross: AudioStreamPlayer
var sfx_player_combo: AudioStreamPlayer
var sfx_player_hover: AudioStreamPlayer
var sfx_player_type: AudioStreamPlayer
var sfx_player_celebration: AudioStreamPlayer
var sfx_player_card: AudioStreamPlayer

# Pre-generated streams
var stream_chill_bgm: AudioStreamWAV
var stream_comp_bgm: AudioStreamWAV
var stream_tick: AudioStreamWAV
var stream_cross: AudioStreamWAV
var stream_combo: AudioStreamWAV
var stream_hover: AudioStreamWAV
var stream_type: AudioStreamWAV
var stream_celebration: AudioStreamWAV
var stream_card: AudioStreamWAV

# Volume Settings (0.0 to 1.0)
var bgm_volume: float = 0.8
var sfx_volume: float = 0.8

func _ready() -> void:
	# 1. Pre-generate all synth streams in memory
	stream_chill_bgm = generate_chill_bgm()
	stream_comp_bgm = generate_comp_bgm()
	stream_tick = generate_tick_sfx()
	stream_cross = generate_cross_sfx()
	stream_combo = generate_combo_sfx()
	stream_hover = generate_button_hover_sfx()
	stream_type = generate_type_sfx()
	stream_celebration = generate_celebration_sfx()
	stream_card = generate_card_flip_sfx()
	
	# 2. Setup Audio Players
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BgmPlayer"
	add_child(bgm_player)
	
	sfx_player_tick = AudioStreamPlayer.new()
	sfx_player_tick.name = "SfxPlayerTick"
	add_child(sfx_player_tick)
	
	sfx_player_cross = AudioStreamPlayer.new()
	sfx_player_cross.name = "SfxPlayerCross"
	add_child(sfx_player_cross)
	
	sfx_player_combo = AudioStreamPlayer.new()
	sfx_player_combo.name = "SfxPlayerCombo"
	add_child(sfx_player_combo)
	
	sfx_player_hover = AudioStreamPlayer.new()
	sfx_player_hover.name = "SfxPlayerHover"
	add_child(sfx_player_hover)
	
	sfx_player_type = AudioStreamPlayer.new()
	sfx_player_type.name = "SfxPlayerType"
	add_child(sfx_player_type)
	
	sfx_player_celebration = AudioStreamPlayer.new()
	sfx_player_celebration.name = "SfxPlayerCelebration"
	add_child(sfx_player_celebration)
	
	sfx_player_card = AudioStreamPlayer.new()
	sfx_player_card.name = "SfxPlayerCard"
	add_child(sfx_player_card)
	
	# Play chill music at start
	play_chill_bgm()

func play_chill_bgm() -> void:
	if bgm_player.stream == stream_chill_bgm and bgm_player.playing:
		# Just update volume in case slider changed
		set_bgm_volume(bgm_volume)
		return
	bgm_player.stop()
	bgm_player.stream = stream_chill_bgm
	set_bgm_volume(bgm_volume)
	bgm_player.play()

func play_comp_bgm() -> void:
	if bgm_player.stream == stream_comp_bgm and bgm_player.playing:
		# Just update volume
		set_bgm_volume(bgm_volume)
		return
	bgm_player.stop()
	bgm_player.stream = stream_comp_bgm
	set_bgm_volume(bgm_volume)
	bgm_player.play()

func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()

func play_tick() -> void:
	sfx_player_tick.stream = stream_tick
	sfx_player_tick.volume_db = linear_to_db(sfx_volume) - 8.0 # Soft woodblock tap
	sfx_player_tick.play()

func play_cross() -> void:
	sfx_player_cross.stream = stream_cross
	sfx_player_cross.volume_db = linear_to_db(sfx_volume) - 10.0 # Dampened organic thud
	sfx_player_cross.play()

func play_combo() -> void:
	sfx_player_combo.stream = stream_combo
	sfx_player_combo.volume_db = linear_to_db(sfx_volume) - 2.0 # Warm cascading harp glissando
	sfx_player_combo.play()

func play_button_hover() -> void:
	sfx_player_hover.stream = stream_hover
	sfx_player_hover.volume_db = linear_to_db(sfx_volume) - 4.0 # Clear wooden click on hover (raised volume)
	sfx_player_hover.play()

func play_type_sfx() -> void:
	sfx_player_type.stream = stream_type
	sfx_player_type.volume_db = linear_to_db(sfx_volume) - 4.0 # Clear typing key click (raised volume)
	sfx_player_type.play()

func play_celebration() -> void:
	sfx_player_celebration.stream = stream_celebration
	sfx_player_celebration.volume_db = linear_to_db(sfx_volume) - 2.0 # Triumphant acoustic harp glissando
	sfx_player_celebration.play()

func play_card_flip() -> void:
	sfx_player_card.stream = stream_card
	sfx_player_card.volume_db = linear_to_db(sfx_volume) - 20.0 # Very soft card rustle/flip
	sfx_player_card.play()

func set_bgm_volume(val: float) -> void:
	bgm_volume = val
	if bgm_player:
		if val <= 0.01:
			bgm_player.volume_db = -80.0
		else:
			if bgm_player.stream == stream_chill_bgm:
				bgm_player.volume_db = linear_to_db(val) - 2.0
			else:
				bgm_player.volume_db = linear_to_db(val) - 8.0

func set_sfx_volume(val: float) -> void:
	sfx_volume = val


# --- NATURAL SYNTHESIS METHODS ---

# Helper for plucked string simulation (Karplus-Strong)
func generate_plucked_note_array(frequency: float, duration: float, mix_rate: int) -> PackedFloat32Array:
	var num_samples = int(mix_rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	
	var buffer_size = int(mix_rate / frequency)
	if buffer_size < 2:
		buffer_size = 2
	var buffer = PackedFloat32Array()
	buffer.resize(buffer_size)
	
	# Seed buffer with white noise (pluck strike)
	for i in range(buffer_size):
		buffer[i] = randf_range(-1.0, 1.0)
		
	var head = 0
	for i in range(num_samples):
		var val = buffer[head]
		samples[i] = val
		
		# Low-pass filter loop (average adjacent samples and apply decay)
		var next_head = (head + 1) % buffer_size
		var new_val = (buffer[head] + buffer[next_head]) * 0.5 * 0.990
		buffer[head] = new_val
		head = next_head
		
	return samples

# Helper for warm Rhodes EP piano chord note
func get_rhodes_sample(t: float, freq: float, decay: float = 2.0) -> float:
	var env = exp(-t * decay)
	# Fundamental + rich, warm overtones (additive harmonics)
	var wave = sin(t * freq * 2.0 * PI) * 0.82
	wave += sin(t * freq * 2.0 * 2.0 * PI) * 0.12
	wave += sin(t * freq * 3.0 * 2.0 * PI) * 0.04
	wave += sin(t * freq * 4.0 * 2.0 * PI) * 0.02
	return wave * env

# Helper for competitive BGM warm analog-style bass
func get_analog_bass_sample(t: float, freq: float) -> float:
	var env = exp(-t * 6.0)
	var s_tri = 2.0 * abs(fmod(t * freq, 1.0) - 0.5) - 1.0
	var s_sin = sin(t * freq * 2.0 * PI)
	return (s_sin * 0.8 + s_tri * 0.2) * env

# Helper for kick drum synthesis (slide down pitch sweep)
func get_kick_sample(t: float) -> float:
	var freq = 40.0 + (120.0 - 40.0) * exp(-t * 30.0)
	var wave = sin(t * freq * 2.0 * PI)
	var env = exp(-t * 15.0)
	return wave * env

# Helper for snare drum synthesis (detuned impact + noise decay)
func get_snare_sample(t: float) -> float:
	var noise = randf_range(-1.0, 1.0)
	var tone = sin(t * 180.0 * 2.0 * PI)
	var env_tone = exp(-t * 30.0)
	var env_noise = exp(-t * 12.0)
	return (tone * env_tone * 0.4 + noise * env_noise * 0.6)

# Helper for hi-hat synthesis (short white noise burst)
func get_hat_sample(t: float) -> float:
	var noise = randf_range(-1.0, 1.0)
	var env = exp(-t * 80.0)
	return noise * env

# Helper for soft acoustic pluck synthesis with low-pass filter and soft thumb attack
func generate_soft_pluck(frequency: float, duration: float, mix_rate: int, decay_coeff: float = 0.996) -> PackedFloat32Array:
	var num_samples = int(mix_rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	
	var buffer_size = int(mix_rate / frequency)
	if buffer_size < 2:
		buffer_size = 2
	var buffer = PackedFloat32Array()
	buffer.resize(buffer_size)
	
	# Seed buffer with filtered noise (soft attack)
	var prev_noise = 0.0
	for i in range(buffer_size):
		var noise = randf_range(-1.0, 1.0)
		# Low pass filter the noise
		noise = (noise + prev_noise) * 0.5
		prev_noise = noise
		buffer[i] = noise
		
	var head = 0
	var prev_val = 0.0
	for i in range(num_samples):
		var val = buffer[head]
		
		# Output low-pass filter to make it warmer
		var output_val = (val + prev_val) * 0.5
		prev_val = val
		
		samples[i] = output_val
		
		# Low-pass filter loop (average adjacent samples and apply decay)
		var next_head = (head + 1) % buffer_size
		var new_val = (buffer[head] + buffer[next_head]) * 0.5 * decay_coeff
		buffer[head] = new_val
		head = next_head
		
	return samples

# Helper to generate an acoustic wooden body tap (cajon/guitar body knock)
func generate_wood_knock(duration: float, mix_rate: int) -> PackedFloat32Array:
	var num_samples = int(mix_rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(mix_rate)
		var env = exp(-t * 35.0) # fast decay
		var sample = sin(t * 130.0 * 2.0 * PI) * 0.6
		sample += sin(t * 220.0 * 2.0 * PI) * 0.3
		sample += sin(t * 380.0 * 2.0 * PI) * 0.1
		var noise = randf_range(-1.0, 1.0) if t < 0.005 else 0.0
		samples[i] = (sample * 0.88 + noise * 0.12) * env
	return samples

# 1. Cute Sweet Chill Menu BGM (Bouncy Swing Guitar & Rhythmic Wooden Taps)
func generate_chill_bgm() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(22050 * 32.0)
	
	var data = PackedByteArray()
	var duration = 32.0
	var num_samples = int(22050 * duration)
	
	# Note Frequency Constants
	var A2 = 110.00
	var G2 = 98.00
	var C3 = 130.81
	var D3 = 146.83
	var E3 = 164.81
	var G3 = 196.00
	var A3 = 220.00
	var B3 = 246.94
	var C4 = 261.63
	var C_SHARP_4 = 277.18
	var D4 = 293.66
	var E4 = 329.63
	var F4 = 349.23
	var G4 = 392.00
	var A4 = 440.00
	var B4 = 493.88
	var C5 = 523.25
	var C_SHARP_5 = 554.37
	var D5 = 587.33
	var E5 = 659.25
	var F5 = 698.46
	var G5 = 783.99
	var A5 = 880.00
	var B5 = 987.77
	var C6 = 1046.50
	var C_SHARP_6 = 1108.73
	var D6 = 1174.66
	var E6 = 1318.51
	var F6 = 1396.91
	var G6 = 1567.98
	
	# 16 chords (2.0s per chord, total 32.0s)
	# Playful Cmaj7 -> A7 -> Dm7 -> G7 turnaround (x4)
	# Structured as: [root_freq, alt_freq, [upper_chord_notes]]
	var chords = [
		[C3, G3, [C4, E4, G4, B4]],  # 1. Cmaj7
		[A2, E3, [C_SHARP_4, E4, G4, C_SHARP_5]], # 2. A7
		[D3, A3, [D4, F4, A4, C5]],  # 3. Dm7
		[G2, D3, [B3, D4, F4, G4]],  # 4. G7
		
		[C3, G3, [C4, E4, G4, B4]],  # 5. Cmaj7
		[A2, E3, [C_SHARP_4, E4, G4, C_SHARP_5]], # 6. A7
		[D3, A3, [D4, F4, A4, C5]],  # 7. Dm7
		[G2, D3, [B3, D4, F4, G4]],  # 8. G7
		
		[C3, G3, [C4, E4, G4, B4]],  # 9. Cmaj7
		[A2, E3, [C_SHARP_4, E4, G4, C_SHARP_5]], # 10. A7
		[D3, A3, [D4, F4, A4, C5]],  # 11. Dm7
		[G2, D3, [B3, D4, F4, G4]],  # 12. G7
		
		[C3, G3, [C4, E4, G4, B4]],  # 13. Cmaj7
		[A2, E3, [C_SHARP_4, E4, G4, C_SHARP_5]], # 14. A7
		[D3, A3, [D4, F4, A4, C5]],  # 15. Dm7
		[G2, D3, [B3, D4, F4, G4]]   # 16. G7
	]
	
	# Bouncy Jumping Melody notes: [start_time_in_seconds, frequency]
	var melody = [
		# Meas 1-4
		[0.0, E5], [0.3, G5], [0.5, C6], [0.8, B5], [1.0, G5], [1.3, E5], [1.5, G5],
		[2.0, C_SHARP_5], [2.3, E5], [2.5, A5], [2.8, G5], [3.0, E5], [3.3, C_SHARP_5], [3.5, E5],
		[4.0, F5], [4.3, A5], [4.5, D6], [4.8, C6], [5.0, A5], [5.3, F5], [5.5, A5],
		[6.0, G5], [6.3, B5], [6.5, D6], [6.8, F6], [7.0, D6], [7.3, B5], [7.5, G5],
		# Meas 5-8
		[8.0, E5], [8.3, G5], [8.5, C6], [8.8, B5], [9.0, G5], [9.3, E5], [9.5, G5],
		[10.0, C_SHARP_5], [10.3, E5], [10.5, A5], [10.8, G5], [11.0, E5], [11.3, C_SHARP_5], [11.5, E5],
		[12.0, F5], [12.3, A5], [12.5, D6], [12.8, C6], [13.0, A5], [13.3, F5], [13.5, A5],
		[14.0, B5], [14.3, D6], [14.5, G6], [14.8, F6], [15.0, D6], [15.3, B5], [15.5, G5],
		# Meas 9-12
		[16.0, G5], [16.3, E5], [16.5, C5], [16.8, D5], [17.0, E5], [17.3, G5], [17.5, C6],
		[18.0, A5], [18.3, G5], [18.5, E5], [18.8, C_SHARP_5], [19.0, E5], [19.3, G5], [19.5, A5],
		[20.0, F5], [20.3, A5], [20.5, D6], [20.8, E6], [21.0, F6], [21.3, E6], [21.5, D6],
		[22.0, B5], [22.3, C6], [22.5, D6], [22.8, E6], [23.0, F6], [23.3, D6], [23.5, B5],
		# Meas 13-16
		[24.0, E5], [24.3, G5], [24.5, C6], [24.8, D6], [25.0, E6], [25.3, C6], [25.5, G5],
		[26.0, C_SHARP_6], [26.3, A5], [26.5, G5], [26.8, E5], [27.0, A5], [27.3, C_SHARP_6], [27.5, E6],
		[28.0, F6], [28.3, E6], [28.5, D6], [28.8, C6], [29.0, B5], [29.3, A5], [29.5, F5],
		[30.0, G5], [30.3, B5], [30.5, D6], [30.8, G6], [31.0, D6], [31.3, B5], [31.5, G5]
	]
	
	var mix_buffer = PackedFloat32Array()
	mix_buffer.resize(num_samples)
	mix_buffer.fill(0.0)
	
	# 1. Synthesize Chords and Rhythms dynamically based on section
	for chord_idx in range(chords.size()):
		var chord_start_time = chord_idx * 2.0
		var active_chord = chords[chord_idx]
		
		# Define roots and upper notes
		var root_freq = active_chord[0]
		var alt_freq = active_chord[1]
		var upper_notes = active_chord[2]
		
		if chord_idx < 6:
			# --- SECTION A: INTRO SWING (0.0s to 12.0s) ---
			# Upbeat swing rhythm, pure acoustic guitar chords (no body taps yet)
			# Bass Root (at 0.0s)
			var bass_root_start = chord_start_time
			var bass_root_sample = int(bass_root_start * 22050.0)
			var bass_root_samples = generate_soft_pluck(root_freq, 1.8, 22050, 0.996)
			for j in range(bass_root_samples.size()):
				var target_idx = bass_root_sample + j
				if target_idx < num_samples:
					mix_buffer[target_idx] += bass_root_samples[j] * 0.038
					
			# Bass Alt (at 1.0s)
			var bass_alt_start = chord_start_time + 1.0
			var bass_alt_sample = int(bass_alt_start * 22050.0)
			var bass_alt_samples = generate_soft_pluck(alt_freq, 0.8, 22050, 0.995)
			for j in range(bass_alt_samples.size()):
				var target_idx = bass_alt_sample + j
				if target_idx < num_samples:
					mix_buffer[target_idx] += bass_alt_samples[j] * 0.030
					
			# Strum Upper Notes on swing beats (0.3s, 0.5s, 0.8s, 1.3s, 1.5s, 1.8s)
			var strum_times = [0.3, 0.5, 0.8, 1.3, 1.5, 1.8]
			for strum_t in strum_times:
				var base_start = chord_start_time + strum_t
				for note_idx in range(upper_notes.size()):
					var note_freq = upper_notes[note_idx]
					var strum_note_start = base_start + (note_idx * 0.02) # quick stagger
					var strum_note_sample = int(strum_note_start * 22050.0)
					# Short, crisp staccato decay
					var strum_chord_samples = generate_soft_pluck(note_freq, 0.35, 22050, 0.990)
					for j in range(strum_chord_samples.size()):
						var target_idx = strum_note_sample + j
						if target_idx < num_samples:
							mix_buffer[target_idx] += strum_chord_samples[j] * 0.022
							
		elif chord_idx >= 6 and chord_idx < 12:
			# --- SECTION B: FULL SWING GROOVE (12.0s to 24.0s) ---
			# Bouncy swing guitar chords PLUS wooden cajon body taps on backbeats.
			# Bass Root (at 0.0s)
			var bass_root_start = chord_start_time
			var bass_root_sample = int(bass_root_start * 22050.0)
			var bass_root_samples = generate_soft_pluck(root_freq, 1.8, 22050, 0.996)
			for j in range(bass_root_samples.size()):
				var target_idx = bass_root_sample + j
				if target_idx < num_samples:
					mix_buffer[target_idx] += bass_root_samples[j] * 0.038
					
			# Bass Alt (at 1.0s)
			var bass_alt_start = chord_start_time + 1.0
			var bass_alt_sample = int(bass_alt_start * 22050.0)
			var bass_alt_samples = generate_soft_pluck(alt_freq, 0.8, 22050, 0.995)
			for j in range(bass_alt_samples.size()):
				var target_idx = bass_alt_sample + j
				if target_idx < num_samples:
					mix_buffer[target_idx] += bass_alt_samples[j] * 0.030
					
			# Wood Knock percussion on backbeats (at 0.5s and 1.5s)
			for knock_t in [0.5, 1.5]:
				var knock_start = chord_start_time + knock_t
				var knock_start_sample = int(knock_start * 22050.0)
				var knock_samples = generate_wood_knock(0.15, 22050)
				for j in range(knock_samples.size()):
					var target_idx = knock_start_sample + j
					if target_idx < num_samples:
						mix_buffer[target_idx] += knock_samples[j] * 0.028 # louder knocks
						
			# Strum Upper Notes on swing beats
			var strum_times = [0.3, 0.5, 0.8, 1.3, 1.5, 1.8]
			for strum_t in strum_times:
				var base_start = chord_start_time + strum_t
				for note_idx in range(upper_notes.size()):
					var note_freq = upper_notes[note_idx]
					var strum_note_start = base_start + (note_idx * 0.02)
					var strum_note_sample = int(strum_note_start * 22050.0)
					var strum_chord_samples = generate_soft_pluck(note_freq, 0.35, 22050, 0.990)
					for j in range(strum_chord_samples.size()):
						var target_idx = strum_note_sample + j
						if target_idx < num_samples:
							mix_buffer[target_idx] += strum_chord_samples[j] * 0.022
							
		else:
			# --- SECTION C: TRIPLETS / ARPEGGIATED OUTRO (24.0s to 32.0s) ---
			# Cascading swing triplets. No taps.
			var arpeggio_notes = [root_freq, alt_freq, upper_notes[0], upper_notes[1], upper_notes[2], upper_notes[3]]
			var arpeggio_times = [0.0, 0.3, 0.6, 0.9, 1.2, 1.5]
			for note_idx in range(arpeggio_notes.size()):
				var note_freq = arpeggio_notes[note_idx]
				var note_start = chord_start_time + arpeggio_times[note_idx]
				var start_sample = int(note_start * 22050.0)
				var note_samples = generate_soft_pluck(note_freq, 1.2, 22050, 0.996)
				for j in range(note_samples.size()):
					var target_idx = start_sample + j
					if target_idx < num_samples:
						mix_buffer[target_idx] += note_samples[j] * 0.038
						
	# 2. Synthesize wandering acoustic melody
	for note in melody:
		var melody_start_time = note[0]
		var note_freq = note[1]
		var melody_start_sample = int(melody_start_time * 22050.0)
		
		# Melody plucks decay slightly faster (0.994) to sound clear and distinct
		var melody_pluck_samples = generate_soft_pluck(note_freq, 1.2, 22050, 0.994)
		for j in range(melody_pluck_samples.size()):
			var target_idx = melody_start_sample + j
			if target_idx < num_samples:
				mix_buffer[target_idx] += melody_pluck_samples[j] * 0.050 # Slightly louder melody
				
	for i in range(num_samples):
		var val = int(clamp(mix_buffer[i] * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream



# 2. Driving Organic Competitive BGM (Plucked Arpeggio + Synth Bass + Drums)
func generate_comp_bgm() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(22050 * 4.0)
	
	var data = PackedByteArray()
	var duration = 4.0
	var num_samples = int(22050 * duration)
	
	var mix_buffer = PackedFloat32Array()
	mix_buffer.resize(num_samples)
	mix_buffer.fill(0.0)
	
	var bass_freqs = [55.0, 49.0, 43.65, 36.71] # A1, G1, F1, D1
	
	# 1. Synthesize Bass and Percussion
	for i in range(num_samples):
		var t = float(i) / 22050.0
		
		# Pumping Bassline (eighth notes)
		var bass_beat = int(t / 0.5)
		var bass_freq = bass_freqs[bass_beat % 4]
		var bass_t = fmod(t, 0.5)
		if bass_beat % 2 == 1:
			bass_freq *= 2.0
		mix_buffer[i] += get_analog_bass_sample(bass_t, bass_freq) * 0.05
		
		# Kick (every 1.0s)
		var kick_t = fmod(t, 1.0)
		if kick_t < 0.15:
			mix_buffer[i] += get_kick_sample(kick_t) * 0.065
			
		# Snare (at 0.5s and 1.5s etc)
		var snare_t = fmod(t + 0.5, 1.0)
		if snare_t < 0.15:
			mix_buffer[i] += get_snare_sample(snare_t) * 0.035
			
		# Hi-Hat (every 0.25s)
		var hat_t = fmod(t, 0.25)
		if hat_t < 0.03:
			mix_buffer[i] += get_hat_sample(hat_t) * 0.009
			
	# 2. Fast Lead (16th notes Karplus-Strong arpeggios)
	var lead_seq = [
		220.0, 440.0, 329.63, 440.0, 261.63, 440.0, 329.63, 440.0, # Am
		196.0, 392.0, 293.66, 392.0, 246.94, 392.0, 293.66, 392.0, # G
		174.61, 349.23, 261.63, 349.23, 220.0, 349.23, 261.63, 349.23, # F
		146.83, 293.66, 220.0, 293.66, 174.61, 293.66, 220.0, 293.66  # Dm
	]
	
	# 32 notes in 4 seconds = 0.125s per note
	for n in range(lead_seq.size()):
		var start_time = n * 0.125
		var start_sample = int(start_time * 22050.0)
		var note_freq = lead_seq[n]
		var note_samples = generate_plucked_note_array(note_freq, 0.2, 22050)
		for j in range(note_samples.size()):
			var target_idx = start_sample + j
			if target_idx < num_samples:
				mix_buffer[target_idx] += note_samples[j] * 0.015
				
	for i in range(num_samples):
		var val = int(clamp(mix_buffer[i] * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 3. Woodblock Tap Correct Selection SFX
func generate_tick_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.05
	var num_samples = int(44100 * duration)
	
	# 3 detuned frequencies for organic wood resonance
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var env = exp(-t * 80.0)
		var sample = sin(t * 880.0 * 2.0 * PI) * 0.6
		sample += sin(t * 1200.0 * 2.0 * PI) * 0.3
		sample += sin(t * 1600.0 * 2.0 * PI) * 0.1
		sample *= env * 0.06
		
		var val = int(clamp(sample * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 4. Dampened Wood Thud Incorrect Selection SFX
func generate_cross_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.15
	var num_samples = int(44100 * duration)
	
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var env = exp(-t * 25.0)
		var freq = 60.0 + (130.0 - 60.0) * exp(-t * 40.0) # sweeping thud tone
		var tone = sin(t * freq * 2.0 * PI)
		
		var noise = randf_range(-1.0, 1.0) if t < 0.005 else 0.0
		var sample = (tone * 0.9 + noise * 0.1) * env * 0.045
		
		var val = int(clamp(sample * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 5. Cascading Harp glissando Combo SFX
func generate_combo_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.6
	var num_samples = int(44100 * duration)
	
	var mix_buffer = PackedFloat32Array()
	mix_buffer.resize(num_samples)
	mix_buffer.fill(0.0)
	
	var notes = [659.25, 783.99, 880.00, 987.77, 1174.66, 1318.51] # E5, G5, A5, B5, D6, E6
	var offsets = [0.0, 0.05, 0.10, 0.15, 0.20, 0.25]
	
	for n in range(notes.size()):
		var start_sample = int(offsets[n] * 44100.0)
		var note_freq = notes[n]
		var note_dur = 0.3
		var note_samples = generate_plucked_note_array(note_freq, note_dur, 44100)
		for j in range(note_samples.size()):
			var target_idx = start_sample + j
			if target_idx < num_samples:
				mix_buffer[target_idx] += note_samples[j] * 0.045
				
	for i in range(num_samples):
		var val = int(clamp(mix_buffer[i] * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 6. Woodblock Hover Tap SFX
func generate_button_hover_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.04
	var num_samples = int(44100 * duration)
	
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var env = exp(-t * 150.0)
		var sample = sin(t * 1800.0 * 2.0 * PI) * 0.08 * env # Increased amplitude multiplier from 0.015 to 0.08
		
		var val = int(clamp(sample * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 7. Soft Tactile Typewriter Typing Click SFX (increased volume)
func generate_type_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.025
	var num_samples = int(44100 * duration)
	
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var env = exp(-t * 220.0)
		var noise = randf_range(-1.0, 1.0)
		# Increased amplitude multiplier from 0.02 to 0.15 for better audibility
		var sample = (noise * 0.6 + sin(t * 900.0 * 2.0 * PI) * 0.4) * env * 0.15
		
		var val = int(clamp(sample * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 8. Grand Acoustic Harp Glissando Celebration Fanfare
func generate_celebration_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 1.8
	var num_samples = int(44100 * duration)
	
	var mix_buffer = PackedFloat32Array()
	mix_buffer.resize(num_samples)
	mix_buffer.fill(0.0)
	
	var notes = [
		130.81, 164.81, 196.00, 261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50
	] # C3, E3, G3, C4, E4, G4, C5, E5, G5, C6
	var offsets = [0.0, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72]
	
	for n in range(notes.size()):
		var start_sample = int(offsets[n] * 44100.0)
		var note_freq = notes[n]
		var note_dur = 1.0
		var note_samples = generate_plucked_note_array(note_freq, note_dur, 44100)
		for j in range(note_samples.size()):
			var target_idx = start_sample + j
			if target_idx < num_samples:
				mix_buffer[target_idx] += note_samples[j] * 0.055
				
	for i in range(num_samples):
		var val = int(clamp(mix_buffer[i] * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream

# 9. Soft tactile card flip/movement sound effect
func generate_card_flip_sfx() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var data = PackedByteArray()
	var duration = 0.12
	var num_samples = int(44100 * duration)
	
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var env_noise = exp(-t * 45.0)
		var env_tone = exp(-t * 20.0)
		var noise = randf_range(-1.0, 1.0) * 0.15
		
		# Low frequency flap sound (pitch sweep down from 150Hz to 50Hz)
		var freq = 50.0 + (150.0 - 50.0) * exp(-t * 30.0)
		var tone = sin(t * freq * 2.0 * PI) * 0.5
		
		var sample = (tone * env_tone + noise * env_noise) * 0.05
		
		var val = int(clamp(sample * 32767.0, -32768, 32767))
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
		
	stream.data = data
	return stream
