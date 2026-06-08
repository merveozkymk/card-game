class_name Game
extends Node2D

## Game logic controller for the 1v1 split-screen card matching game.
## Manages score bubbles, combo badges, keyboard input navigation, level progression, and layout positioning.

# Signals
signal level_completed(winner: int, level: int)
signal game_completed(winner: int)

# Card Script reference
const CardScript = preload("res://Card.gd")

# Level and Score Variables
@export var current_level: int = 1
@export var p1_score: int = 0
@export var p2_score: int = 0

# Player Names
var p1_name: String = "Oyuncu 1"
var p2_name: String = "Oyuncu 2"

# Players' selected card indices
var p1_selected_idx: int = 0
var p2_selected_idx: int = 0

# Player card lists
var p1_cards: Array = []
var p2_cards: Array = []

var game_mode: String = "classic"
var target_card_id: int = -1
var level3_timer: Timer
var level3_target_ids: Array = []
var level3_generation: int = 0

# Players' currently flipped cards
var p1_flipped_cards: Array = []
var p2_cards_flipped: Array = []
var shift_timer: Timer

# Combos
var p1_combo: int = 0
var p2_combo: int = 0

# Level-specific stats
var p1_level_score: int = 0
var p2_level_score: int = 0
var p1_level_moves: int = 0
var p2_level_moves: int = 0
var p1_level_max_combo: int = 0
var p2_level_max_combo: int = 0

# Tournament cumulative stats
var p1_tour_score: int = 0
var p2_tour_score: int = 0
var p1_tour_moves: int = 0
var p2_tour_moves: int = 0
var p1_tour_max_combo: int = 0
var p2_tour_max_combo: int = 0
var p1_tour_matched_cards: int = 0
var p2_tour_matched_cards: int = 0


# Node References
@export var p1_grid: GridContainer
@export var p2_grid: GridContainer
@export var game_ui: GameUI

# Texture Placeholders (used for fallback compatibility)
@export var front_textures: Array[Texture2D] = []
@export var back_texture: Texture2D

# Gameplay States
var can_play: bool = false
var p1_can_play: bool = true
var p2_can_play: bool = true

# Level Configurations
# Level 1: 12 cards total (6 cards per player grid, 3x2)
# Level 2: 16 cards total (8 cards per player grid, 4x2)
# Level 3: 20 cards total (10 cards per player grid, 5x2)
# Level 4: 24 cards total (12 cards per player grid, 6x2)
const LEVEL_CONFIG = {
	1: {"total_cards": 12, "columns": 4},
	2: {"total_cards": 16, "columns": 4},
	3: {"total_cards": 20, "columns": 5},
	4: {"total_cards": 24, "columns": 6}
}

func _ready() -> void:
	# Set window mode to maximized (fullscreen size) on launch
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	_setup_nodes()
	
	# Connect UI signals
	if game_ui:
		game_ui.start_actual_game.connect(_on_start_actual_game)
		game_ui.continue_game.connect(_on_continue_game)
	else:
		push_error("GameUI reference not found!")
		
	# Listen to viewport changes for dynamic layout alignment
	get_viewport().size_changed.connect(_reposition_grids)

## Automatically pulls node references
func _setup_nodes() -> void:
	if p1_grid == null:
		p1_grid = get_node_or_null("LeftGrid")
	if p2_grid == null:
		p2_grid = get_node_or_null("RightGrid")
	if game_ui == null:
		game_ui = get_node_or_null("GameUI")
		
	# Fallback if LeftGrid/RightGrid are not set in properties
	if p1_grid == null:
		p1_grid = get_node_or_null("P1Grid")
	if p2_grid == null:
		p2_grid = get_node_or_null("P2Grid")
		
	# Recreate grids if absolutely missing
	if p1_grid == null:
		p1_grid = GridContainer.new()
		p1_grid.name = "LeftGrid"
		add_child(p1_grid)
	if p2_grid == null:
		p2_grid = GridContainer.new()
		p2_grid.name = "RightGrid"
		add_child(p2_grid)

## Triggered when start button on NameInputPanel is pressed
func _on_start_actual_game(p1: String, p2: String, mode: String = "classic") -> void:
	p1_name = p1
	p2_name = p2
	p1_score = 0
	p2_score = 0
	p1_combo = 0
	p2_combo = 0
	game_mode = mode
	
	AudioManager.play_comp_bgm()
	
	if game_ui:
		update_scores_on_ui()
		game_ui.show_combo_badge(1, false)
		game_ui.show_combo_badge(2, false)
		
	start_level(1)

## Triggered when LevelWinPanel continue button is pressed
func _on_continue_game() -> void:
	start_level(current_level + 1)

## Generates texture placeholders if needed
func _generate_placeholders_if_needed(total_pairs: int) -> void:
	if back_texture == null:
		var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.2, 0.2, 0.25))
		back_texture = ImageTexture.create_from_image(img)
		
	if front_textures.size() < total_pairs:
		front_textures.clear()
		for i in range(total_pairs):
			var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
			var hue = float(i) / float(total_pairs)
			var color = Color.from_hsv(hue, 0.8, 0.8)
			img.fill(color)
			front_textures.append(ImageTexture.create_from_image(img))

## Loads and positions the grid setup for a level
func start_level(level: int) -> void:
	if level > 4:
		return
		
	current_level = level
	can_play = false
	p1_can_play = true
	p2_can_play = true
	p1_selected_idx = 0
	p2_selected_idx = 0
	p1_combo = 0
	p2_combo = 0
	
	p1_level_score = 0
	p2_level_score = 0
	p1_level_moves = 0
	p2_level_moves = 0
	p1_level_max_combo = 0
	p2_level_max_combo = 0
	
	if game_ui:
		game_ui.show_combo_badge(1, false)
		game_ui.show_combo_badge(2, false)
	update_scores_on_ui()
	
	_clear_cards()
	
	if game_mode == "reflex":
		p1_grid.columns = 8
		p1_grid.add_theme_constant_override("h_separation", 10)
		p1_grid.add_theme_constant_override("v_separation", 10)
		
		# Hide P2 grid and divider
		p2_grid.visible = false
		p1_grid.visible = true
		
		_generate_placeholders_if_needed(40)
		
		# Generate 40 unique card IDs
		var card_ids = []
		for i in range(40):
			card_ids.append(i)
		card_ids.shuffle()
		
		# Level 2 monochrome card flag
		var is_monochrome = (current_level == 2)
		
		# Spawn cards on p1_grid (shared grid)
		for i in range(40):
			var card_id = card_ids[i]
			var card = CardScript.new()
			p1_grid.add_child(card)
			# Setup with scaled size 70x92 for 8x5 grid
			card.setup_card(card_id, front_textures[card_id % front_textures.size()], back_texture, Vector2(70, 92), is_monochrome)
			p1_cards.append(card)
			card.flip_card(true, false) # Always face-up in reflex mode, animate but no sound
			
		_reposition_grids()
		
		# Select first available for both players and draw highlights
		_select_first_available_card(1)
		_select_first_available_card(2)
		_refresh_card_highlights()
		
		can_play = true
		
		# Level 3 Timer Initialization
		if current_level == 3:
			if not is_instance_valid(level3_timer):
				level3_timer = Timer.new()
				level3_timer.name = "Level3Timer"
				level3_timer.one_shot = false
				level3_timer.timeout.connect(_on_level3_timer_timeout)
				add_child(level3_timer)
		else:
			if is_instance_valid(level3_timer):
				level3_timer.stop()
				
		_select_new_target_shape()
		_stop_shift_timer()
	else:
		p2_grid.visible = true
		p1_grid.visible = true
		
		var config = LEVEL_CONFIG.get(current_level, {"total_cards": 6, "columns": 3})
		var total_cards = config["total_cards"]
		var cols = config["columns"]
		var total_pairs = total_cards / 2
		
		p1_grid.columns = cols
		p2_grid.columns = cols
		p1_grid.add_theme_constant_override("h_separation", 16)
		p1_grid.add_theme_constant_override("v_separation", 16)
		p2_grid.add_theme_constant_override("h_separation", 16)
		p2_grid.add_theme_constant_override("v_separation", 16)
		
		_generate_placeholders_if_needed(total_pairs)
		
		# Generate card IDs
		var card_ids: Array = []
		for i in range(total_pairs):
			card_ids.append(i)
			card_ids.append(i)
			
		var p1_ids = card_ids.duplicate()
		var p2_ids = card_ids.duplicate()
		p1_ids.shuffle()
		p2_ids.shuffle()
		
		# Spawn cards for P1
		for i in range(total_cards):
			var card_id = p1_ids[i]
			var card = CardScript.new()
			p1_grid.add_child(card)
			card.setup_card(card_id, front_textures[card_id], back_texture)
			p1_cards.append(card)
			card.flip_card(true, false) # Animate but no sound
			
		# Spawn cards for P2
		for i in range(total_cards):
			var card_id = p2_ids[i]
			var card = CardScript.new()
			p2_grid.add_child(card)
			card.setup_card(card_id, front_textures[card_id], back_texture)
			p2_cards.append(card)
			card.flip_card(true, false) # Animate but no sound
			
		# Center grids symmetrically in split-screen format
		_reposition_grids()
		
		# 2 seconds memorization preview time
		await get_tree().create_timer(2.0).timeout
		
		# Flip cards face-down
		for card in p1_cards:
			if is_instance_valid(card) and card.is_flipped:
				card.flip_card(true, false) # Animate but no sound
		for card in p2_cards:
			if is_instance_valid(card) and card.is_flipped:
				card.flip_card(true, false) # Animate but no sound
				
		# Wait for flip-down animation to complete (0.25s)
		await get_tree().create_timer(0.25).timeout
		
		# Highlight initial selection indexes
		_select_first_available_card(1)
		_select_first_available_card(2)
		_refresh_card_highlights()
			
		can_play = true
		if current_level == 3:
			_start_shift_timer()
		else:
			_stop_shift_timer()

## Cleans up card nodes
func _clear_cards() -> void:
	for card in p1_cards:
		if is_instance_valid(card):
			card.queue_free()
	for card in p2_cards:
		if is_instance_valid(card):
			card.queue_free()
	p1_cards.clear()
	p2_cards.clear()
	p1_flipped_cards.clear()
	p2_cards_flipped.clear()
	if is_instance_valid(level3_timer):
		level3_timer.stop()

## Repositions LeftGrid and RightGrid symmetrically inside the viewport
func _reposition_grids() -> void:
	if p1_grid == null or p2_grid == null:
		return
		
	if not is_inside_tree():
		return
		
	var cols = 0
	var rows = 0
	var card_w = 110.0
	var card_h = 145.0
	var spacing = 16.0
	
	if game_mode == "reflex":
		cols = 8
		rows = 5
		card_w = 70.0
		card_h = 92.0
		spacing = 10.0
	else:
		var config = LEVEL_CONFIG.get(current_level, {"total_cards": 6, "columns": 3})
		var total_cards = config["total_cards"]
		cols = config["columns"]
		rows = int(ceil(total_cards / float(cols)))
		
	var grid_w = cols * card_w + (cols - 1) * spacing
	var grid_h = rows * card_h + (rows - 1) * spacing
	
	# Force explicit sizes on grids
	p1_grid.custom_minimum_size = Vector2(grid_w, grid_h)
	p1_grid.size = Vector2(grid_w, grid_h)
	if game_mode == "classic":
		p2_grid.custom_minimum_size = Vector2(grid_w, grid_h)
		p2_grid.size = Vector2(grid_w, grid_h)
		
	var viewport_size = get_viewport().get_visible_rect().size
	
	if game_mode == "reflex":
		# Center horizontally in the middle of the screen
		var center_x = (viewport_size.x / 2.0) - (grid_w / 2.0)
		# Center vertically in the remaining space below the top UI (to prevent overlap with target shapes and score bubbles)
		var start_y = 200.0
		var available_h = viewport_size.y - start_y
		var center_y = start_y + (available_h / 2.0) - (grid_h / 2.0)
		if center_y < start_y:
			center_y = start_y
		p1_grid.position = Vector2(center_x, center_y)
	else:
		# Center horizontally in P1's half
		var p1_center_x = (viewport_size.x / 4.0) - (grid_w / 2.0)
		# Center horizontally in P2's half
		var p2_center_x = (3.0 * viewport_size.x / 4.0) - (grid_w / 2.0)
		
		# Center vertically in the viewport, offset down to clear score bubbles
		var start_y = 220.0
		var available_h = viewport_size.y - start_y
		var center_y = start_y + (available_h / 2.0) - (grid_h / 2.0)
		
		p1_grid.position = Vector2(p1_center_x, center_y)
		p2_grid.position = Vector2(p2_center_x, center_y)

## Handles directional keyboard inputs
func _unhandled_input(event: InputEvent) -> void:
	if not can_play:
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		_end_level(1)
		return
		
	# Player 1 WASD keys
	if p1_can_play:
		if event.is_action_pressed("p1_up", false):
			_navigate_grid(1, "up")
		elif event.is_action_pressed("p1_down", false):
			_navigate_grid(1, "down")
		elif event.is_action_pressed("p1_left", false):
			_navigate_grid(1, "left")
		elif event.is_action_pressed("p1_right", false):
			_navigate_grid(1, "right")
		elif event.is_action_pressed("p1_accept", false):
			_select_card(1)
			
	# Player 2 Arrow keys
	if p2_can_play:
		if event.is_action_pressed("p2_up", false):
			_navigate_grid(2, "up")
		elif event.is_action_pressed("p2_down", false):
			_navigate_grid(2, "down")
		elif event.is_action_pressed("p2_left", false):
			_navigate_grid(2, "left")
		elif event.is_action_pressed("p2_right", false):
			_navigate_grid(2, "right")
		elif event.is_action_pressed("p2_accept", false):
			_select_card(2)

## Computes selection shifts and handles boundary wraps skipping matched cards
func _navigate_grid(player_num: int, direction: String) -> void:
	var current_idx = p1_selected_idx if player_num == 1 else p2_selected_idx
	var cards = p1_cards
	if game_mode == "classic":
		cards = p1_cards if player_num == 1 else p2_cards
	var total_cards = cards.size()
	
	if total_cards == 0:
		return
		
	var cols = 8
	if game_mode == "classic":
		var config = LEVEL_CONFIG.get(current_level, {"columns": 3})
		cols = config["columns"]
	var rows = int(ceil(total_cards / float(cols)))
	
	var r_curr = current_idx / cols
	var c_curr = current_idx % cols
	
	var d_row = 0
	var d_col = 0
	
	match direction:
		"up":
			d_row = -1
		"down":
			d_row = 1
		"left":
			d_col = -1
		"right":
			d_col = 1
			
	var new_row = r_curr
	var new_col = c_curr
	var found_idx = -1
	
	# 1. Step in the straight line direction until we find an unmatched card
	while true:
		new_row += d_row
		new_col += d_col
		
		# Bounds check
		if new_row < 0 or new_row >= rows or new_col < 0 or new_col >= cols:
			break
			
		var check_idx = new_row * cols + new_col
		if check_idx >= 0 and check_idx < total_cards:
			if not cards[check_idx].is_matched:
				found_idx = check_idx
				break
				
	# 2. Fallback: If no card found in straight line, search in the general direction (diagonal fallback)
	if found_idx == -1:
		var best_idx = -1
		var min_dist = 999999
		for i in range(total_cards):
			if cards[i].is_matched:
				continue
			if i == current_idx:
				continue
				
			var r_i = i / cols
			var c_i = i % cols
			
			var matches_direction = false
			match direction:
				"up":
					matches_direction = (r_i < r_curr)
				"down":
					matches_direction = (r_i > r_curr)
				"left":
					matches_direction = (c_i < c_curr)
				"right":
					matches_direction = (c_i > c_curr)
					
			if matches_direction:
				var dist = abs(r_i - r_curr) + abs(c_i - c_curr)
				if dist < min_dist:
					min_dist = dist
					best_idx = i
		if best_idx != -1:
			found_idx = best_idx
			
	# 3. Fallback: If only 2 unmatched cards remain in the entire grid, let any arrow move to the other card!
	if found_idx == -1:
		var unmatched_indices = []
		for i in range(total_cards):
			if not cards[i].is_matched:
				unmatched_indices.append(i)
		if unmatched_indices.size() == 2:
			var other_idx = unmatched_indices[0] if unmatched_indices[1] == current_idx else unmatched_indices[1]
			found_idx = other_idx
			
	# If we found a valid unmatched card, highlight it
	if found_idx != -1 and found_idx != current_idx:
		if player_num == 1:
			p1_selected_idx = found_idx
		else:
			p2_selected_idx = found_idx
			
		_refresh_card_highlights()

func _refresh_card_highlights() -> void:
	if game_mode == "reflex":
		var cards = p1_cards
		for i in range(cards.size()):
			var card = cards[i]
			if is_instance_valid(card):
				var p1_selected = (p1_selected_idx == i and p1_can_play)
				var p2_selected = (p2_selected_idx == i and p2_can_play)
				if p1_selected and p2_selected:
					card.set_highlight(3)
				elif p1_selected:
					card.set_highlight(1)
				elif p2_selected:
					card.set_highlight(2)
				else:
					card.set_highlight(0)
	else:
		# Classic mode: update P1 and P2 individually
		for i in range(p1_cards.size()):
			var card = p1_cards[i]
			if is_instance_valid(card):
				if p1_selected_idx == i and p1_can_play and not card.is_matched:
					card.set_highlight(1)
				else:
					card.set_highlight(0)
		for i in range(p2_cards.size()):
			var card = p2_cards[i]
			if is_instance_valid(card):
				if p2_selected_idx == i and p2_can_play and not card.is_matched:
					card.set_highlight(2)
				else:
					card.set_highlight(0)

## Find the closest unmatched card to the current selection index and highlight it
func _select_first_available_card(player_num: int) -> void:
	var current_idx = p1_selected_idx if player_num == 1 else p2_selected_idx
	var cards = p1_cards
	if game_mode == "classic":
		cards = p1_cards if player_num == 1 else p2_cards
	var total_cards = cards.size()
	
	if total_cards == 0:
		return
		
	# If the current index is valid and unmatched, keep highlighting it
	if current_idx >= 0 and current_idx < total_cards:
		if not cards[current_idx].is_matched:
			_refresh_card_highlights()
			return
			
	# Scan outwards to find the nearest unmatched card
	var best_idx = -1
	var min_dist = 999999
	
	for i in range(total_cards):
		if not cards[i].is_matched:
			var dist = abs(i - current_idx)
			if dist < min_dist:
				min_dist = dist
				best_idx = i
				
	if player_num == 1:
		p1_selected_idx = best_idx
	else:
		p2_selected_idx = best_idx
		
	_refresh_card_highlights()

## Selects/flips a card
func _select_card(player_num: int) -> void:
	if game_mode == "reflex":
		_select_card_reflex(player_num)
		return
		
	var selected_idx = p1_selected_idx if player_num == 1 else p2_selected_idx
	var cards = p1_cards if player_num == 1 else p2_cards
	var flipped = p1_flipped_cards if player_num == 1 else p2_cards_flipped
	
	if cards.size() == 0 or selected_idx >= cards.size():
		return
		
	var card = cards[selected_idx]
	if card.is_matched or card.is_flipped:
		return
		
	card.flip_card()
	flipped.append(card)
	
	if flipped.size() == 2:
		if player_num == 1:
			p1_level_moves += 1
		else:
			p2_level_moves += 1
		update_scores_on_ui()
		_check_match(player_num)

func _select_card_reflex(player_num: int) -> void:
	if player_num == 1 and not p1_can_play:
		return
	if player_num == 2 and not p2_can_play:
		return
		
	var selected_idx = p1_selected_idx if player_num == 1 else p2_selected_idx
	if selected_idx < 0 or selected_idx >= p1_cards.size():
		return
		
	var card = p1_cards[selected_idx]
	if card.is_matched:
		return
		
	var is_correct = false
	var clicked_shape = card.id % 30
	if current_level == 3:
		for target_id in level3_target_ids:
			if (target_id % 30) == clicked_shape:
				is_correct = true
				break
	else:
		is_correct = (clicked_shape == (target_card_id % 30))
		
	if is_correct:
		AudioManager.play_tick()
		# Correct match!
		card.is_matched = true
		card.disabled = true
		card.animate_match()
		
		# If level 3, remove the matched shape from the active target list
		if current_level == 3:
			for target_id in level3_target_ids:
				if (target_id % 30) == clicked_shape:
					level3_target_ids.erase(target_id)
					break
		
		var score_add = 10
		if player_num == 1:
			p1_score += score_add
			p1_level_score += score_add
		else:
			p2_score += score_add
			p2_level_score += score_add
			
		if game_ui:
			update_scores_on_ui()
			game_ui.flash_score_bubble(player_num)
			
		# Check level completion
		var unmatched_cards = []
		for c in p1_cards:
			if not c.is_matched:
				unmatched_cards.append(c)
				
		if unmatched_cards.size() == 0:
			_end_level(player_num)
		elif unmatched_cards.size() == 1:
			# Auto-match the last remaining card and end the level immediately!
			var last_card = unmatched_cards[0]
			last_card.is_matched = true
			last_card.disabled = true
			last_card.animate_match()
			
			# Award points for the final card to the player who made the match
			if player_num == 1:
				p1_score += score_add
				p1_level_score += score_add
			else:
				p2_score += score_add
				p2_level_score += score_add
			if game_ui:
				update_scores_on_ui()
				
			_end_level(player_num)
		else:
			_select_new_target_shape()
			_shuffle_grid_reflex()
	else:
		AudioManager.play_cross()
		# Incorrect match! 1.5s freeze penalty
		if player_num == 1:
			p1_can_play = false
			_refresh_card_highlights()
			await get_tree().create_timer(1.5).timeout
			p1_can_play = true
			_refresh_card_highlights()
		else:
			p2_can_play = false
			_refresh_card_highlights()
			await get_tree().create_timer(1.5).timeout
			p2_can_play = true
			_refresh_card_highlights()

func _select_new_target_shape() -> void:
	var unmatched_cards = []
	for card in p1_cards:
		if is_instance_valid(card) and not card.is_matched:
			unmatched_cards.append(card)
			
	if unmatched_cards.size() == 0:
		_end_level(1)
		return
		
	var is_monochrome = (current_level == 2)
	
	if current_level == 3:
		level3_generation += 1
		var current_gen = level3_generation
		
		if is_instance_valid(level3_timer):
			level3_timer.stop()
			
		var temp_cards = unmatched_cards.duplicate()
		temp_cards.shuffle()
		
		var selected_shapes = []
		level3_target_ids.clear()
		for c in temp_cards:
			var shape = c.id % 30
			if not selected_shapes.has(shape):
				selected_shapes.append(shape)
				level3_target_ids.append(c.id)
			if level3_target_ids.size() >= 3:
				break
		if level3_target_ids.size() < min(3, temp_cards.size()):
			for c in temp_cards:
				if not level3_target_ids.has(c.id):
					level3_target_ids.append(c.id)
				if level3_target_ids.size() >= min(3, temp_cards.size()):
					break
			
		if game_ui:
			game_ui.update_target_shape(level3_target_ids, false)
			
		# Show for 3 seconds then hide
		await get_tree().create_timer(3.0).timeout
		
		if current_gen == level3_generation and current_level == 3 and can_play:
			if game_ui:
				game_ui.hide_target_shapes()
			if is_instance_valid(level3_timer):
				level3_timer.start(10.0)
	else:
		# Pick 1 target ID
		var random_card = unmatched_cards[randi() % unmatched_cards.size()]
		target_card_id = random_card.id
		if game_ui:
			game_ui.update_target_shape([target_card_id], is_monochrome)

func _on_level3_timer_timeout() -> void:
	if current_level == 3 and game_mode == "reflex" and can_play:
		_select_new_target_shape()
		_shuffle_grid_reflex()

func _shuffle_grid_reflex() -> void:
	var cards = p1_cards
	var total_cards = cards.size()
	if total_cards == 0:
		return
		
	var unmatched_indices = []
	for i in range(total_cards):
		if not cards[i].is_matched:
			unmatched_indices.append(i)
			
	if unmatched_indices.size() <= 1:
		return
		
	var initial_positions = {}
	for idx in unmatched_indices:
		initial_positions[idx] = cards[idx].position
		
	var shuffled_nodes = []
	for idx in unmatched_indices:
		shuffled_nodes.append(cards[idx])
	shuffled_nodes.shuffle()
	
	for i in range(unmatched_indices.size()):
		var target_idx = unmatched_indices[i]
		cards[target_idx] = shuffled_nodes[i]
		
	var tween = create_tween().set_parallel(true)
	for i in range(unmatched_indices.size()):
		var target_idx = unmatched_indices[i]
		var card = cards[target_idx]
		var end_pos = initial_positions[target_idx]
		tween.tween_property(card, "position", end_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	tween.chain().tween_callback(func():
		for i in range(cards.size()):
			var card = cards[i]
			if is_instance_valid(card):
				p1_grid.move_child(card, i)
				card.position = Vector2.ZERO
		_select_first_available_card(1)
		_select_first_available_card(2)
		_refresh_card_highlights()
	)

## Matches evaluation, scoring, and combos
func _check_match(player_num: int) -> void:
	var flipped = p1_flipped_cards if player_num == 1 else p2_cards_flipped
	var cards = p1_cards if player_num == 1 else p2_cards
	
	if flipped.size() != 2:
		return
		
	var card1 = flipped[0]
	var card2 = flipped[1]
	
	if card1.id == card2.id:
		card1.is_matched = true
		card2.is_matched = true
		card1.disabled = true
		card2.disabled = true
		card1.animate_match()
		card2.animate_match()
		card1.set_highlight(0)
		card2.set_highlight(0)
		flipped.clear()
		
		# Immediately redirect selection to the nearest active card
		_select_first_available_card(player_num)
		
		# Scoring and Combo calculation
		var has_combo = false
		if player_num == 1:
			p1_combo += 1
			p1_level_max_combo = max(p1_level_max_combo, p1_combo)
			var score_add = 10
			if p1_combo > 1:
				score_add += 5 * (p1_combo - 1)
				has_combo = true
				if game_ui:
					game_ui.show_combo_badge(1, true)
			p1_score += score_add
			p1_level_score += score_add
		else:
			p2_combo += 1
			p2_level_max_combo = max(p2_level_max_combo, p2_combo)
			var score_add = 10
			if p2_combo > 1:
				score_add += 5 * (p2_combo - 1)
				has_combo = true
				if game_ui:
					game_ui.show_combo_badge(2, true)
			p2_score += score_add
			p2_level_score += score_add
			
		if has_combo:
			AudioManager.play_combo()
		else:
			AudioManager.play_tick()
			
		if game_ui:
			update_scores_on_ui()
			
		# Check level win
		var all_matched = true
		for card in cards:
			if not card.is_matched:
				all_matched = false
				break
				
		if all_matched:
			_end_level(player_num)
	else:
		AudioManager.play_cross()
		# Incorrect match: reset combos and block actions temporarily
		if player_num == 1:
			p1_can_play = false
			p1_combo = 0
			if game_ui:
				game_ui.show_combo_badge(1, false)
		else:
			p2_can_play = false
			p2_combo = 0
			if game_ui:
				game_ui.show_combo_badge(2, false)
				
		await get_tree().create_timer(0.5).timeout
		
		if is_instance_valid(card1):
			card1.flip_card()
		if is_instance_valid(card2):
			card2.flip_card()
			
		flipped.clear()
		
		if player_num == 1:
			p1_can_play = true
		else:
			p2_can_play = true

## End level procedures
func _end_level(winner_player: int) -> void:
	can_play = false
	_stop_shift_timer()
	
	emit_signal("level_completed", winner_player, current_level)
	
	# Dynamic score calculation
	var p1_dyn = 0
	var p2_dyn = 0
	if game_mode == "reflex":
		p1_dyn = p1_level_score
		p2_dyn = p2_level_score
	else:
		p1_dyn = max(0, p1_level_score - p1_level_moves * 2 + p1_level_max_combo * 15)
		p2_dyn = max(0, p2_level_score - p2_level_moves * 2 + p2_level_max_combo * 15)
	
	# Accumulate to tournament totals
	p1_tour_score += p1_dyn
	p2_tour_score += p2_dyn
	p1_tour_moves += p1_level_moves
	p2_tour_moves += p2_level_moves
	p1_tour_max_combo = max(p1_tour_max_combo, p1_level_max_combo)
	p2_tour_max_combo = max(p2_tour_max_combo, p2_level_max_combo)
	
	# Last level evaluations (moved after score accumulation)
	if current_level >= 4:
		var final_winner = 1 if p1_tour_score > p2_tour_score else (2 if p2_tour_score > p1_tour_score else 0)
		emit_signal("game_completed", final_winner)
	
	var config = LEVEL_CONFIG.get(current_level, {"total_cards": 12})
	var total_cards = 40 if game_mode == "reflex" else config["total_cards"]
	if game_mode == "reflex":
		p1_tour_matched_cards += p1_level_score / 10
		p2_tour_matched_cards += p2_level_score / 10
	else:
		p1_tour_matched_cards += total_cards
		p2_tour_matched_cards += total_cards
	
	var level_winner = 0 # 0: tie, 1: P1, 2: P2
	var level_winner_name = ""
	if p1_dyn > p2_dyn:
		level_winner = 1
		level_winner_name = p1_name
	elif p2_dyn > p1_dyn:
		level_winner = 2
		level_winner_name = p2_name
	else:
		level_winner = 0
		level_winner_name = "Beraberlik!"
		
	# Show level complete UI panel
	if game_ui:
		game_ui.show_level_complete(
			level_winner_name,
			current_level,
			p1_dyn,
			p2_dyn,
			p1_level_moves,
			p2_level_moves,
			p1_level_max_combo,
			p2_level_max_combo,
			level_winner
		)
		game_ui.show_combo_badge(1, false)
		game_ui.show_combo_badge(2, false)

## Calculate and return the total cumulative results (including active level in-progress stats)
func get_tournament_results() -> Dictionary:
	# Add current level's active stats (if they haven't been completed yet)
	var p1_dyn = 0
	var p2_dyn = 0
	if game_mode == "reflex":
		p1_dyn = p1_level_score
		p2_dyn = p2_level_score
	else:
		p1_dyn = max(0, p1_level_score - p1_level_moves * 2 + p1_level_max_combo * 15)
		p2_dyn = max(0, p2_level_score - p2_level_moves * 2 + p2_level_max_combo * 15)
	
	# Compute matched cards in the current level so far
	var p1_matched = 0
	var p2_matched = 0
	if game_mode == "reflex":
		p1_matched = p1_level_score / 10
		p2_matched = p2_level_score / 10
	else:
		for card in p1_cards:
			if is_instance_valid(card) and card.is_matched:
				p1_matched += 1
		for card in p2_cards:
			if is_instance_valid(card) and card.is_matched:
				p2_matched += 1
			
	var p1_final_score = p1_tour_score
	var p2_final_score = p2_tour_score
	var p1_final_moves = p1_tour_moves
	var p2_final_moves = p2_tour_moves
	var p1_final_combo = p1_tour_max_combo
	var p2_final_combo = p2_tour_max_combo
	var p1_final_matched = p1_tour_matched_cards
	var p2_final_matched = p2_tour_matched_cards
	
	# Only add active level stats if the level is not completed yet
	# (We know it's not completed if some cards are not matched yet)
	var p1_grid_finished = true
	for card in p1_cards:
		if is_instance_valid(card) and not card.is_matched:
			p1_grid_finished = false
			break
			
	if not p1_grid_finished:
		p1_final_score += p1_dyn
		p2_final_score += p2_dyn
		p1_final_moves += p1_level_moves
		p2_final_moves += p2_level_moves
		p1_final_combo = max(p1_final_combo, p1_level_max_combo)
		p2_final_combo = max(p2_final_combo, p2_level_max_combo)
		p1_final_matched += p1_matched
		p2_final_matched += p2_matched
		
	var tour_winner = 0 # 0: tie, 1: P1, 2: P2
	if p1_final_score > p2_final_score:
		tour_winner = 1
	elif p2_final_score > p1_final_score:
		tour_winner = 2
		
	return {
		"p1_score": p1_final_score,
		"p2_score": p2_final_score,
		"p1_moves": p1_final_moves,
		"p2_moves": p2_final_moves,
		"p1_combo": p1_final_combo,
		"p2_combo": p2_final_combo,
		"p1_matched": p1_final_matched,
		"p2_matched": p2_final_matched,
		"winner": tour_winner
	}

func get_current_display_scores() -> Dictionary:
	var p1_dyn = 0
	var p2_dyn = 0
	if game_mode == "reflex":
		p1_dyn = p1_level_score
		p2_dyn = p2_level_score
	else:
		p1_dyn = max(0, p1_level_score - p1_level_moves * 2 + p1_level_max_combo * 15)
		p2_dyn = max(0, p2_level_score - p2_level_moves * 2 + p2_level_max_combo * 15)
	return {
		"p1": p1_tour_score + p1_dyn,
		"p2": p2_tour_score + p2_dyn
	}

func update_scores_on_ui() -> void:
	if game_ui:
		var scores = get_current_display_scores()
		game_ui.update_arena_scores(p1_name, scores["p1"], p2_name, scores["p2"])

## Reset all tournament scoring stats for a fresh game
func reset_tournament() -> void:
	AudioManager.play_chill_bgm()
	_clear_cards()
	_stop_shift_timer()
	p1_tour_score = 0
	p2_tour_score = 0
	p1_tour_moves = 0
	p2_tour_moves = 0
	p1_tour_max_combo = 0
	p2_tour_max_combo = 0
	p1_tour_matched_cards = 0
	p2_tour_matched_cards = 0
	p1_score = 0
	p2_score = 0
	p1_level_score = 0
	p2_level_score = 0
	p1_level_moves = 0
	p2_level_moves = 0
	p1_level_max_combo = 0
	p2_level_max_combo = 0
	current_level = 1


# Timer management
func _start_shift_timer() -> void:
	if not is_instance_valid(shift_timer):
		shift_timer = Timer.new()
		shift_timer.name = "ShiftTimer"
		shift_timer.one_shot = true
		shift_timer.timeout.connect(_on_shift_timer_timeout)
		add_child(shift_timer)
	_reset_shift_timer()

func _reset_shift_timer() -> void:
	if is_instance_valid(shift_timer) and current_level == 3 and can_play:
		var wait_time = randf_range(10.0, 15.0)
		shift_timer.start(wait_time)

func _stop_shift_timer() -> void:
	if is_instance_valid(shift_timer):
		shift_timer.stop()

func _on_shift_timer_timeout() -> void:
	if current_level == 3 and can_play:
		await _trigger_grid_shift()
	_reset_shift_timer()

# Grid Shifting Logic
func _trigger_grid_shift() -> void:
	if not can_play or current_level != 3:
		return
		
	var config = LEVEL_CONFIG.get(3, {"columns": 5})
	var cols = config["columns"]
	
	# Decide row vs column swap
	var is_row = randf() < 0.5
	var a = 0
	var b = 0
	
	if is_row:
		# 4 rows in Level 3 (20 cards / 5 columns = 4 rows)
		a = randi() % 4
		b = randi() % 4
		while b == a:
			b = randi() % 4
	else:
		# 5 columns in Level 3
		a = randi() % 5
		b = randi() % 5
		while b == a:
			b = randi() % 5
			
	var tween_p1 = _swap_grid_elements(1, is_row, a, b, cols)
	var tween_p2 = _swap_grid_elements(2, is_row, a, b, cols)
	
	# Wait for tweens to finish
	if tween_p1:
		await tween_p1.finished
	if tween_p2 and tween_p2.is_valid():
		await tween_p2.finished

func _swap_grid_elements(player_num: int, is_row: bool, a: int, b: int, cols: int) -> Tween:
	var cards = p1_cards if player_num == 1 else p2_cards
	var grid = p1_grid if player_num == 1 else p2_grid
	var total_cards = cards.size()
	if total_cards == 0:
		return null
		
	var swap_pairs = []
	if is_row:
		for c in range(cols):
			var idx_a = a * cols + c
			var idx_b = b * cols + c
			if idx_a < total_cards and idx_b < total_cards:
				swap_pairs.append([idx_a, idx_b])
	else:
		var rows = int(ceil(total_cards / float(cols)))
		for r in range(rows):
			var idx_a = r * cols + a
			var idx_b = r * cols + b
			if idx_a < total_cards and idx_b < total_cards:
				swap_pairs.append([idx_a, idx_b])
				
	if swap_pairs.size() == 0:
		return null
		
	# Store the current positions
	var positions = {}
	for pair in swap_pairs:
		var card_a = cards[pair[0]]
		var card_b = cards[pair[1]]
		if is_instance_valid(card_a) and is_instance_valid(card_b):
			positions[pair[0]] = card_a.position
			positions[pair[1]] = card_b.position
			
	# Save references of selected cards before the swap
	var p1_selected_card = p1_cards[p1_selected_idx] if (player_num == 1 and p1_selected_idx >= 0 and p1_selected_idx < total_cards) else null
	var p2_selected_card = p2_cards[p2_selected_idx] if (player_num == 2 and p2_selected_idx >= 0 and p2_selected_idx < total_cards) else null
			
	# Start parallel tweening
	var tween = create_tween().set_parallel(true)
	for pair in swap_pairs:
		var card_a = cards[pair[0]]
		var card_b = cards[pair[1]]
		if is_instance_valid(card_a) and is_instance_valid(card_b):
			tween.tween_property(card_a, "position", positions[pair[1]], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(card_b, "position", positions[pair[0]], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
	# Update the actual array and grid hierarchy on completion
	tween.chain().tween_callback(func():
		for pair in swap_pairs:
			var idx_a = pair[0]
			var idx_b = pair[1]
			var temp = cards[idx_a]
			cards[idx_a] = cards[idx_b]
			cards[idx_b] = temp
			
		# Rearrange child nodes in GridContainer
		for i in range(cards.size()):
			var card = cards[i]
			if is_instance_valid(card):
				grid.move_child(card, i)
				card.position = Vector2.ZERO
				
		# Update keyboard selection indicators
		if player_num == 1 and is_instance_valid(p1_selected_card):
			var new_idx = cards.find(p1_selected_card)
			if new_idx != -1:
				p1_selected_idx = new_idx
		elif player_num == 2 and is_instance_valid(p2_selected_card):
			var new_idx = cards.find(p2_selected_card)
			if new_idx != -1:
				p2_selected_idx = new_idx
				
		# Refresh hover styling
		for card in cards:
			if is_instance_valid(card):
				card.set_highlight(0)
		_select_first_available_card(player_num)
	)
	
	return tween
