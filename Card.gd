class_name Card
extends TextureButton

## Card matching/memory game card controller.
## Implements 24px rounded corners, lavender back with orchid glow star,
## dark purple front with high-contrast geometric icons, and player-specific neon inner-glow selection.

# Properties
var id: int = -1
var is_flipped: bool = false
var is_matched: bool = false
var highlight_player: int = 0 # 0: none, 1: Player 1 (orchid), 2: Player 2 (electric yellow)
var is_monochrome: bool = false
var _is_animating_match: bool = false

# Internal texture references (kept for compatibility)
var _front_texture: Texture2D
var _back_texture: Texture2D

func _ready() -> void:
	# Set default minimum size for procedural drawing
	custom_minimum_size = Vector2(110, 145)
	size = Vector2(110, 145)

## Setup the card with a unique ID and textures
func setup_card(card_id: int, front_texture: Texture2D, back_texture: Texture2D, custom_size: Vector2 = Vector2(110, 145), monochrome: bool = false) -> void:
	id = card_id
	_front_texture = front_texture
	_back_texture = back_texture
	is_flipped = false
	is_matched = false
	highlight_player = 0
	disabled = false
	custom_minimum_size = custom_size
	size = custom_size
	is_monochrome = monochrome
	scale = Vector2.ONE
	modulate.a = 1.0
	_is_animating_match = false
	pivot_offset = custom_size / 2.0
	queue_redraw()

## Flips the card if it has not been matched yet
func flip_card(animate: bool = true, play_sound: bool = true) -> void:
	if is_matched:
		return
		
	if not animate or not is_inside_tree():
		is_flipped = !is_flipped
		queue_redraw()
		return
		
	pivot_offset = size / 2.0
	
	if play_sound:
		AudioManager.play_card_flip()
		
	var tween = create_tween()
	# Step 1: scale down to 0 horizontally
	tween.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Step 2: toggle state and redraw
	tween.tween_callback(func():
		is_flipped = !is_flipped
		queue_redraw()
	)
	# Step 3: scale back up to 1.0 horizontally
	tween.tween_property(self, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## Animates the card flying up and fading out when matched
func animate_match() -> void:
	_is_animating_match = true
	pivot_offset = size / 2.0
	
	var tween = create_tween().set_parallel(true)
	# Animate position.y upward by 40 pixels
	tween.tween_property(self, "position:y", position.y - 40.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Animate opacity (modulate.a) to 0.0
	tween.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# On complete, finalize matched state and stop drawing
	tween.chain().tween_callback(func():
		_is_animating_match = false
		is_matched = true
		queue_redraw()
	)

## Sets selection highlight (0: none, 1: Player 1, 2: Player 2)
func set_highlight(player_num: int) -> void:
	highlight_player = player_num
	queue_redraw()

func _draw() -> void:
	if is_matched and not _is_animating_match:
		return
		
	var card_rect = Rect2(Vector2.ZERO, size)
	
	# 1. Card Base Styling (24px rounded corners)
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(24)
	
	if not is_flipped:
		# Card Back: Lavender (#e6e6fa) surface
		style.bg_color = Color.from_string("#e6e6fa", Color.WHITE)
		style.border_color = Color.from_string("#d0d0e8", Color.WHITE)
		style.set_border_width_all(2)
		draw_style_box(style, card_rect)
		
		# Center orchid purple (#af93d4) glow/star symbol
		var center = size / 2.0
		var orchid_color = Color.from_string("#af93d4", Color.MAGENTA)
		
		# Draw a 4-point star/sparkle symbol
		draw_line(center - Vector2(20, 0), center + Vector2(20, 0), orchid_color, 4.0)
		draw_line(center - Vector2(0, 20), center + Vector2(0, 20), orchid_color, 4.0)
		draw_circle(center, 7.0, orchid_color)
	else:
		# Card Front: Dark Purple (#4b0082) surface
		style.bg_color = Color.from_string("#4b0082", Color.BLACK)
		style.border_color = Color.from_string("#3d006f", Color.BLACK)
		style.set_border_width_all(2)
		draw_style_box(style, card_rect)
		
		# High-contrast geometric front symbol based on card ID
		var center = size / 2.0
		_draw_front_symbol(id, center)
		
	# 2. Player-Specific Selection Glow (Neon Inner Border)
	if highlight_player > 0:
		var glow_style = StyleBoxFlat.new()
		glow_style.draw_center = false
		glow_style.set_corner_radius_all(24)
		glow_style.set_border_width_all(6)
		
		if highlight_player == 1:
			# Player 1: Mor (#af93d4) neon inner glow
			glow_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
			glow_style.shadow_color = Color.from_string("#af93d4", Color.BLACK)
			glow_style.shadow_size = 6
			draw_style_box(glow_style, card_rect)
		elif highlight_player == 2:
			# Player 2: Electric Yellow (#ffff00) neon inner glow
			glow_style.border_color = Color.from_string("#ffff00", Color.YELLOW)
			glow_style.shadow_color = Color.from_string("#ffff00", Color.BLACK)
			glow_style.shadow_size = 6
			draw_style_box(glow_style, card_rect)
		elif highlight_player == 3:
			# Player 1 and Player 2: Dual selection (Outer Orchid, Inner Yellow)
			glow_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
			glow_style.shadow_color = Color.from_string("#af93d4", Color.BLACK)
			glow_style.shadow_size = 6
			draw_style_box(glow_style, card_rect)
			
			var inner_glow = StyleBoxFlat.new()
			inner_glow.draw_center = false
			inner_glow.set_corner_radius_all(24)
			inner_glow.set_border_width_all(3)
			inner_glow.border_color = Color.from_string("#ffff00", Color.YELLOW)
			draw_style_box(inner_glow, card_rect)

## Draws a high-contrast geometric symbol based on the card id
func _draw_front_symbol(card_id: int, center: Vector2) -> void:
	var colors = [
		Color.from_string("#ffff00", Color.YELLOW),  # Electric Yellow
		Color.from_string("#ff00ff", Color.MAGENTA), # Neon Pink
		Color.from_string("#00ffff", Color.CYAN),    # Neon Cyan
		Color.from_string("#39ff14", Color.GREEN),   # Neon Green
		Color.from_string("#ff5f1f", Color.ORANGE),  # Neon Orange
		Color.WHITE,
		Color.from_string("#ff007f", Color.RED),     # Rose Red
		Color.from_string("#7cfc00", Color.GREEN),   # Lawn Green
		Color.from_string("#9400d3", Color.PURPLE),  # Dark Violet
		Color.from_string("#ff8c00", Color.ORANGE)   # Dark Orange
	]
	
	var symbol_color = Color.WHITE
	if not is_monochrome:
		symbol_color = colors[card_id % colors.size()]
	var symbol_type = card_id % 30
	
	match symbol_type:
		0: # Circle
			draw_circle(center, 22.0, symbol_color)
		1: # Square
			var rect = Rect2(center - Vector2(20, 20), Vector2(40, 40))
			draw_rect(rect, symbol_color)
		2: # Triangle
			var points = PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(-22, 18),
				center + Vector2(22, 18)
			])
			draw_colored_polygon(points, symbol_color)
		3: # Cross
			draw_line(center - Vector2(20, 0), center + Vector2(20, 0), symbol_color, 8.0)
			draw_line(center - Vector2(0, 20), center + Vector2(0, 20), symbol_color, 8.0)
		4: # Diamond
			var points = PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(22, 0),
				center + Vector2(0, 24),
				center + Vector2(-22, 0)
			])
			draw_colored_polygon(points, symbol_color)
		5: # Hollow Ring
			draw_circle(center, 22.0, symbol_color)
			draw_circle(center, 12.0, Color.from_string("#4b0082", Color.BLACK))
		6: # Pentagon
			var points = PackedVector2Array()
			for i in range(5):
				var angle = deg_to_rad(i * 72 - 90)
				points.append(center + Vector2(cos(angle), sin(angle)) * 24.0)
			draw_colored_polygon(points, symbol_color)
		7: # Hexagon
			var points = PackedVector2Array()
			for i in range(6):
				var angle = deg_to_rad(i * 60 - 90)
				points.append(center + Vector2(cos(angle), sin(angle)) * 24.0)
			draw_colored_polygon(points, symbol_color)
		8: # 8-Point Star
			var points = PackedVector2Array()
			for i in range(16):
				var r = 24.0 if i % 2 == 0 else 10.0
				var angle = deg_to_rad(i * 22.5 - 90)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(points, symbol_color)
		9: # Concentric Double Ring
			draw_circle(center, 22.0, symbol_color)
			draw_circle(center, 15.0, Color.from_string("#4b0082", Color.BLACK))
			draw_circle(center, 8.0, symbol_color)
		10: # Pill/Capsule
			var rect = Rect2(center - Vector2(10, 22), Vector2(20, 44))
			var cap_style = StyleBoxFlat.new()
			cap_style.bg_color = symbol_color
			cap_style.set_corner_radius_all(10)
			draw_style_box(cap_style, rect)
		11: # Hourglass
			var points = PackedVector2Array([
				center + Vector2(-20, -20),
				center + Vector2(20, -20),
				center + Vector2(4, 0),
				center + Vector2(20, 20),
				center + Vector2(-20, 20),
				center + Vector2(-4, 0)
			])
			draw_colored_polygon(points, symbol_color)
		12: # 5-Point Star
			var points = PackedVector2Array()
			for i in range(10):
				var r = 24.0 if i % 2 == 0 else 10.0
				var angle = deg_to_rad(i * 36 - 90)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(points, symbol_color)
		13: # Heart
			var points = PackedVector2Array()
			for i in range(30):
				var t = i * (2.0 * PI / 30.0)
				var x = 16.0 * pow(sin(t), 3)
				var y = -(13.0 * cos(t) - 5.0 * cos(2.0*t) - 2.0*cos(3.0*t) - cos(4.0*t))
				points.append(center + Vector2(x, y) * 1.5)
			draw_colored_polygon(points, symbol_color)
		14: # Arrow
			var points = PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(22, 0),
				center + Vector2(10, 0),
				center + Vector2(10, 24),
				center + Vector2(-10, 24),
				center + Vector2(-10, 0),
				center + Vector2(-22, 0)
			])
			draw_colored_polygon(points, symbol_color)
		15: # Crescent Moon
			var points = PackedVector2Array()
			for i in range(16):
				var angle = deg_to_rad(i * 12 - 90)
				points.append(center + Vector2(cos(angle), sin(angle)) * 24.0)
			for i in range(16):
				var angle = deg_to_rad(90 - i * 12)
				points.append(center + Vector2(8 + cos(angle) * 18.0, sin(angle) * 18.0))
			draw_colored_polygon(points, symbol_color)
		16: # X-Cross
			draw_line(center - Vector2(16, 16), center + Vector2(16, 16), symbol_color, 8.0)
			draw_line(center - Vector2(-16, 16), center + Vector2(-16, 16), symbol_color, 8.0)
		17: # Shield
			var points = PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(20, -24),
				center + Vector2(20, 0),
				center + Vector2(0, 24),
				center + Vector2(-20, 0),
				center + Vector2(-20, -24)
			])
			draw_colored_polygon(points, symbol_color)
		18: # Flower / Gear
			var points = PackedVector2Array()
			for i in range(24):
				var r = 24.0 if i % 2 == 0 else 16.0
				var angle = deg_to_rad(i * 15)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(points, symbol_color)
		19: # Bullseye / Cross Ring
			draw_circle(center, 22.0, symbol_color)
			draw_circle(center, 15.0, Color.from_string("#4b0082", Color.BLACK))
			draw_circle(center, 6.0, symbol_color)
			draw_line(center - Vector2(24, 0), center - Vector2(15, 0), symbol_color, 3.0)
			draw_line(center + Vector2(15, 0), center + Vector2(24, 0), symbol_color, 3.0)
			draw_line(center - Vector2(0, 24), center - Vector2(0, 15), symbol_color, 3.0)
			draw_line(center + Vector2(0, 15), center + Vector2(0, 24), symbol_color, 3.0)
		20: # Trapezoid
			var points = PackedVector2Array([
				center + Vector2(-12, -20),
				center + Vector2(12, -20),
				center + Vector2(22, 20),
				center + Vector2(-22, 20)
			])
			draw_colored_polygon(points, symbol_color)
		21: # Parallelogram
			var points = PackedVector2Array([
				center + Vector2(-10, -20),
				center + Vector2(22, -20),
				center + Vector2(10, 20),
				center + Vector2(-22, 20)
			])
			draw_colored_polygon(points, symbol_color)
		22: # 4-Point Sparkle
			var points = PackedVector2Array()
			for i in range(8):
				var r = 24.0 if i % 2 == 0 else 8.0
				var angle = deg_to_rad(i * 45)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(points, symbol_color)
		23: # 6-Point Star
			var points = PackedVector2Array()
			for i in range(12):
				var r = 24.0 if i % 2 == 0 else 10.0
				var angle = deg_to_rad(i * 30)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(points, symbol_color)
		24: # Octagon
			var points = PackedVector2Array()
			for i in range(8):
				var angle = deg_to_rad(i * 45)
				points.append(center + Vector2(cos(angle), sin(angle)) * 22.0)
			draw_colored_polygon(points, symbol_color)
		25: # Teardrop
			var points = PackedVector2Array()
			points.append(center + Vector2(0, -24))
			for i in range(16):
				var angle = i * (PI / 15.0)
				points.append(center + Vector2(cos(angle) * 18.0, sin(angle) * 18.0 + 6.0))
			draw_colored_polygon(points, symbol_color)
		26: # Ring with Triangle
			draw_circle(center, 22.0, symbol_color)
			draw_circle(center, 16.0, Color.from_string("#4b0082", Color.BLACK))
			var points = PackedVector2Array([
				center + Vector2(0, -10),
				center + Vector2(-9, 7),
				center + Vector2(9, 7)
			])
			draw_colored_polygon(points, symbol_color)
		27: # Segmented Circle
			draw_circle(center, 22.0, symbol_color)
			draw_line(center - Vector2(24, 0), center + Vector2(24, 0), Color.from_string("#4b0082", Color.BLACK), 4.0)
			draw_line(center - Vector2(0, 24), center + Vector2(0, 24), Color.from_string("#4b0082", Color.BLACK), 4.0)
		28: # Chevron Zigzag
			var points = PackedVector2Array([
				center + Vector2(-22, -12),
				center + Vector2(0, -24),
				center + Vector2(22, -12),
				center + Vector2(22, 4),
				center + Vector2(0, -8),
				center + Vector2(-22, 4)
			])
			draw_colored_polygon(points, symbol_color)
		29: # Kite
			var points = PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(16, -6),
				center + Vector2(0, 24),
				center + Vector2(-16, -6)
			])
			draw_colored_polygon(points, symbol_color)
