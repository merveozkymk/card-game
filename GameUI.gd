class_name GameUI
extends CanvasLayer

## UI Controller managing level transitions, MainMenu, ArenaUI split screen indicators,
## score bubbles, combo badges, and animated button scales.

# Signals
signal continue_game # Signal to transition to next level
signal start_actual_game(p1_name: String, p2_name: String, game_mode: String) # Signal to start the actual game after names are entered with mode

# UI Nodes
var level_win_panel: Control
var winner_label: Label
var continue_button: Button
var quit_button: Button

var developing_panel: Control
var developing_quit_button: Button

var welcome_panel: Control
var start_button: Button

var name_input_panel: Control
var p1_name_input: LineEdit
var p2_name_input: LineEdit
var begin_game_button: Button
var how_to_play_panel: Panel

# Game Mode and Selection UI references
var selected_game_mode: String = "classic"
var target_container: Panel
var target_hbox: HBoxContainer
var target_containers: Array = []
var classic_mode_btn: Button
var reflex_mode_btn: Button
var selected_style: StyleBoxFlat
var unselected_style: StyleBoxFlat
var hover_unselected_style: StyleBoxFlat

# Decoration/Animation Nodes
var glow_circle1: Control
var glow_circle2: Control
var icon_box: Control
var floating_grid: GridContainer

# Arena UI properties (split-screen indicators and score bubbles)
var arena_ui: Control
var p1_score_bubble: Panel
var p1_score_label: Label
var p2_score_bubble: Panel
var p2_score_label: Label
var p1_combo_badge: Panel
var p2_combo_badge: Panel

# Viewport-relative tween tracker
var _grid_tween: Tween

# State tracker
var _current_level: int = 1

# LevelWinPanel custom styling nodes
var win_panel_style: StyleBoxFlat
var win_title_label: Label
var win_subtitle_label: Label
var p1_score_val: Label
var p2_score_val: Label
var p1_badge: Panel
var p2_badge: Panel
var combo_val_label: Label
var moves_val_label: Label

var win_float_card1: Control
var win_float_card2: Control
var win_float_card3: Control
var central_panel: Panel
var p1_box_style: StyleBoxFlat
var p2_box_style: StyleBoxFlat

# GrandWinPanel UI nodes
var grand_win_panel: Panel
var grand_central_panel: Panel
var grand_win_title: Label
var grand_win_subtitle: Label
var grand_p1_box: Panel
var grand_p2_box: Panel
var grand_p1_score_val: Label
var grand_p2_score_val: Label
var grand_p1_title: Label
var grand_p2_title: Label
var grand_p1_puan_lbl: Label
var grand_p2_puan_lbl: Label
var grand_p1_badge: Panel
var grand_p2_badge: Panel
var grand_stats_label1: Label
var grand_stats_label2: Label
var grand_menu_button: Button
var grand_float_card1: Control
var grand_float_card2: Control
var grand_float_card3: Control
var grand_float_card4: Control
var grand_float_card5: Control
var grand_trophy_left: Label
var grand_trophy_right: Label
var grand_panel_style: StyleBoxFlat
var grand_p1_box_style: StyleBoxFlat
var grand_p2_box_style: StyleBoxFlat
var grand_p1_bg_icon: Label
var grand_p2_bg_icon: Label


func _ready() -> void:
	# Set window mode to maximized (fullscreen size) on launch
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	# Create the background canvas layer programmatically at the bottom (layer = -1)
	_create_background_canvas()
	
	# Recursively find all required nodes starting from root
	_fallback_node_search()
	
	# Build the stacked overlapping cards mascot dynamically
	_setup_stacked_mascot_cards()
	
	# Apply styling theme values to elements
	_apply_theme_aesthetics()
	
	# Build split-screen arena UI (score bubbles, combo badges, dividing lines)
	_setup_arena_ui()
	
	# Build the programmatically styled win panel
	_setup_level_win_panel()
	
	# Build the programmatically styled grand win panel
	_setup_grand_win_panel()
	
	# Build the programmatically styled how to play panel
	_setup_how_to_play_panel()
	
	# Center MainMenu, panels, and arena components mathematically
	_update_layout_positions()
	
	# Populate background floating grid cells
	_setup_background_grid()
	
	# Style background glowing lila circles
	_setup_glow_circles_styling()
	
	# Trigger floating/pulsing loops
	_start_animations()
	
	# Create settings button and volume controls
	_create_settings_ui()
	
	# Recursively attach hover/squish scale tweens to all buttons
	_setup_all_buttons_recursive(self)
	
	# Realign layout on viewport changes
	get_viewport().size_changed.connect(_update_layout_positions)
	
	# Bind buttons pressed signals
	if developing_quit_button:
		developing_quit_button.pressed.connect(_on_quit_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if begin_game_button:
		begin_game_button.pressed.connect(_on_begin_game_pressed)
		
	var how_button = _find_node_recursive(self, "HowToPlayButton")
	if how_button:
		how_button.pressed.connect(_on_how_to_play_pressed)
		
	if p1_name_input:
		p1_name_input.text_changed.connect(func(_new_text): AudioManager.play_type_sfx())
	if p2_name_input:
		p2_name_input.text_changed.connect(func(_new_text): AudioManager.play_type_sfx())
		
	# Initial visibility configurations
	var root = self.get_parent()
	var main_menu = _find_node_recursive(root, "MainMenu")
	if main_menu:
		main_menu.visible = true
	if welcome_panel:
		welcome_panel.visible = true
	if name_input_panel:
		name_input_panel.visible = false
	if level_win_panel:
		level_win_panel.visible = false
	if developing_panel:
		developing_panel.visible = false
	if arena_ui:
		arena_ui.visible = false

## Recursively finds a node by name
func _find_node_recursive(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, node_name)
		if found != null:
			return found
	return null

## Creates BackgroundCanvas programmatically to hold Background and FloatingGrid at layer = -1
func _create_background_canvas() -> void:
	call_deferred("_deferred_create_background_canvas")

func _deferred_create_background_canvas() -> void:
	var root = self.get_parent()
	var canvas = root.get_node_or_null("BackgroundCanvas")
	if canvas == null:
		canvas = CanvasLayer.new()
		canvas.name = "BackgroundCanvas"
		canvas.layer = -1 # Draws behind the Node2D 2D world
		root.add_child(canvas)
		root.move_child(canvas, 0)
		
	var main_menu = _find_node_recursive(root, "MainMenu")
	if main_menu:
		var background = _find_node_recursive(main_menu, "Background")
		if background:
			background.get_parent().remove_child(background)
			canvas.add_child(background)
			
		var f_grid = _find_node_recursive(main_menu, "FloatingGrid")
		if f_grid:
			f_grid.get_parent().remove_child(f_grid)
			canvas.add_child(f_grid)
			floating_grid = f_grid as GridContainer
			# Re-setup grid cell nodes and sizes after reparenting
			_setup_background_grid()
			_update_layout_positions()

## Recursively loads references from root node
func _fallback_node_search() -> void:
	var root = self.get_parent()
	level_win_panel = _find_node_recursive(root, "LevelWinPanel")
	winner_label = _find_node_recursive(root, "WinnerLabel")
	continue_button = _find_node_recursive(root, "ContinueButton")
	quit_button = _find_node_recursive(root, "QuitButton")
	
	developing_panel = _find_node_recursive(root, "DevelopingPanel")
	developing_quit_button = _find_node_recursive(root, "DevQuitButton")
	if developing_quit_button == null:
		developing_quit_button = _find_node_recursive(root, "DevelopingQuitButton")
		
	welcome_panel = _find_node_recursive(root, "WelcomePanel")
	start_button = _find_node_recursive(root, "StartButton")
	
	name_input_panel = _find_node_recursive(root, "NameInputPanel")
	p1_name_input = _find_node_recursive(root, "P1NameInput")
	p2_name_input = _find_node_recursive(root, "P2NameInput")
	begin_game_button = _find_node_recursive(root, "BeginGameButton")
	
	glow_circle1 = _find_node_recursive(root, "GlowCircle1")
	glow_circle2 = _find_node_recursive(root, "GlowCircle2")
	icon_box = _find_node_recursive(root, "IconBox")
	
	var canvas = root.get_node_or_null("BackgroundCanvas")
	if canvas:
		floating_grid = _find_node_recursive(canvas, "FloatingGrid") as GridContainer

## Configures layout sizing and custom styling overrides
func _apply_theme_aesthetics() -> void:
	if welcome_panel:
		welcome_panel.custom_minimum_size = Vector2(900, 1000)
		welcome_panel.size = Vector2(900, 1000)
		
	if name_input_panel:
		name_input_panel.custom_minimum_size = Vector2(900, 850)
		name_input_panel.size = Vector2(900, 850)
		
	var w_vbox = _find_node_recursive(welcome_panel, "VBox")
	if w_vbox:
		w_vbox.add_theme_constant_override("separation", 24)
		w_vbox.offset_left = 80
		w_vbox.offset_top = 60
		w_vbox.offset_right = -80
		w_vbox.offset_bottom = -60
		
	var n_vbox = _find_node_recursive(name_input_panel, "VBox")
	if n_vbox:
		n_vbox.add_theme_constant_override("separation", 24)
		n_vbox.offset_left = 80
		n_vbox.offset_top = 60
		n_vbox.offset_right = -80
		n_vbox.offset_bottom = -60
		
		# Dynamic Mode Selection Buttons
		var mode_selection_hbox = n_vbox.get_node_or_null("ModeSelectionHBox")
		if mode_selection_hbox == null:
			mode_selection_hbox = HBoxContainer.new()
			mode_selection_hbox.name = "ModeSelectionHBox"
			mode_selection_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			mode_selection_hbox.add_theme_constant_override("separation", 20)
			
			# Selected Style Flat Box
			selected_style = StyleBoxFlat.new()
			selected_style.bg_color = Color.from_string("#af93d4", Color.MAGENTA)
			selected_style.set_corner_radius_all(9999)
			selected_style.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
			selected_style.shadow_color.a = 0.5
			selected_style.shadow_size = 10
			
			# Unselected Style Flat Box
			unselected_style = StyleBoxFlat.new()
			unselected_style.bg_color = Color.from_string("#38333b", Color.BLACK)
			unselected_style.set_border_width_all(2)
			unselected_style.border_color = Color.from_string("#4c4451", Color.DARK_GRAY)
			unselected_style.set_corner_radius_all(9999)
			unselected_style.shadow_size = 0
			
			# Hover Unselected Style Box
			hover_unselected_style = unselected_style.duplicate()
			hover_unselected_style.border_color = Color.from_string("#cec3d3", Color.WHITE)
			
			# Button 1: KLASİK MOD
			classic_mode_btn = Button.new()
			classic_mode_btn.name = "ClassicModeBtn"
			classic_mode_btn.text = "KLASİK MOD"
			classic_mode_btn.custom_minimum_size = Vector2(280, 56)
			classic_mode_btn.add_theme_font_size_override("font_size", 18)
			mode_selection_hbox.add_child(classic_mode_btn)
			
			# Button 2: REFLEKS MODU
			reflex_mode_btn = Button.new()
			reflex_mode_btn.name = "ReflexModeBtn"
			reflex_mode_btn.text = "REFLEKS MODU"
			reflex_mode_btn.custom_minimum_size = Vector2(280, 56)
			reflex_mode_btn.add_theme_font_size_override("font_size", 18)
			mode_selection_hbox.add_child(reflex_mode_btn)
			
			# Add HBox to VBox
			n_vbox.add_child(mode_selection_hbox)
			# Place before BeginGameButton
			var begin_btn_idx = begin_game_button.get_index()
			n_vbox.move_child(mode_selection_hbox, begin_btn_idx)
			
			# Connect signals
			classic_mode_btn.pressed.connect(func():
				selected_game_mode = "classic"
				_update_mode_buttons()
			)
			reflex_mode_btn.pressed.connect(func():
				selected_game_mode = "reflex"
				_update_mode_buttons()
			)
			
			_setup_button_effects(classic_mode_btn)
			_setup_button_effects(reflex_mode_btn)
			
			_update_mode_buttons()
		
	var title_label = _find_node_recursive(welcome_panel, "TitleLabel")
	if title_label:
		title_label.add_theme_font_size_override("font_size", 44)
	
	var subtitle_label = _find_node_recursive(welcome_panel, "SubtitleLabel")
	if subtitle_label:
		subtitle_label.add_theme_font_size_override("font_size", 20)
		
	var name_title_label = _find_node_recursive(name_input_panel, "TitleLabel")
	if name_title_label:
		name_title_label.add_theme_font_size_override("font_size", 38)
		
	var p1_label = _find_node_recursive(name_input_panel, "P1Label")
	if p1_label:
		p1_label.add_theme_font_size_override("font_size", 20)
	var p2_label = _find_node_recursive(name_input_panel, "P2Label")
	if p2_label:
		p2_label.add_theme_font_size_override("font_size", 20)
		
	# Preview cards shrinking and text centering
	var left_card = _find_node_recursive(self, "LeftCard")
	var middle_card = _find_node_recursive(self, "MiddleCard")
	var right_card = _find_node_recursive(self, "RightCard")
	
	if left_card:
		left_card.custom_minimum_size = Vector2(100, 100)
		var l_text = _find_node_recursive(left_card, "LText")
		if l_text:
			l_text.anchor_right = 1.0
			l_text.anchor_bottom = 1.0
			l_text.offset_left = 0
			l_text.offset_top = 0
			l_text.offset_right = 0
			l_text.offset_bottom = 0
			l_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l_text.add_theme_font_size_override("font_size", 16)
	if middle_card:
		middle_card.custom_minimum_size = Vector2(100, 100)
		var m_text = _find_node_recursive(middle_card, "MText")
		if m_text:
			m_text.anchor_right = 1.0
			m_text.anchor_bottom = 1.0
			m_text.offset_left = 0
			m_text.offset_top = 0
			m_text.offset_right = 0
			m_text.offset_bottom = 0
			m_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			m_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			m_text.add_theme_font_size_override("font_size", 52)
	if right_card:
		right_card.custom_minimum_size = Vector2(100, 100)
		var r_text = _find_node_recursive(right_card, "RText")
		if r_text:
			r_text.anchor_right = 1.0
			r_text.anchor_bottom = 1.0
			r_text.offset_left = 0
			r_text.offset_top = 0
			r_text.offset_right = 0
			r_text.offset_bottom = 0
			r_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			r_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			r_text.add_theme_font_size_override("font_size", 16)
			
	if icon_box:
		icon_box.add_theme_font_size_override("font_size", 88)
		
	var l1 = _find_node_recursive(welcome_panel, "L1")
	if l1:
		l1.add_theme_font_size_override("font_size", 30)
	var l2 = _find_node_recursive(welcome_panel, "L2")
	if l2:
		l2.add_theme_font_size_override("font_size", 16)
	var m1 = _find_node_recursive(welcome_panel, "M1")
	if m1:
		m1.add_theme_font_size_override("font_size", 30)
	var m2 = _find_node_recursive(welcome_panel, "M2")
	if m2:
		m2.add_theme_font_size_override("font_size", 16)
		
	if start_button:
		start_button.custom_minimum_size = Vector2(580, 76)
		start_button.add_theme_font_size_override("font_size", 26)
		
	if begin_game_button:
		begin_game_button.custom_minimum_size = Vector2(580, 76)
		begin_game_button.add_theme_font_size_override("font_size", 26)

	var how_button = _find_node_recursive(self, "HowToPlayButton")
	if how_button:
		how_button.custom_minimum_size = Vector2(580, 66)
		how_button.add_theme_font_size_override("font_size", 22)

	if p1_name_input:
		p1_name_input.custom_minimum_size = Vector2(580, 66)
		p1_name_input.add_theme_font_size_override("font_size", 22)
	if p2_name_input:
		p2_name_input.custom_minimum_size = Vector2(580, 66)
		p2_name_input.add_theme_font_size_override("font_size", 22)

	var header = _find_node_recursive(self, "Header")
	if header:
		header.custom_minimum_size = Vector2(0, 80)
		header.size = Vector2(1152, 80)
		var logo_label = _find_node_recursive(header, "LogoLabel")
		if logo_label:
			logo_label.add_theme_font_size_override("font_size", 36)

	if level_win_panel:
		level_win_panel.custom_minimum_size = Vector2(400, 300)
			
	if developing_panel:
		developing_panel.custom_minimum_size = Vector2(400, 300)

func _update_mode_buttons() -> void:
	if classic_mode_btn == null or reflex_mode_btn == null:
		return
	if selected_game_mode == "classic":
		classic_mode_btn.add_theme_stylebox_override("normal", selected_style)
		classic_mode_btn.add_theme_stylebox_override("hover", selected_style)
		classic_mode_btn.add_theme_stylebox_override("pressed", selected_style)
		classic_mode_btn.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
		classic_mode_btn.add_theme_color_override("font_hover_color", Color.from_string("#2c0050", Color.BLACK))
		
		reflex_mode_btn.add_theme_stylebox_override("normal", unselected_style)
		reflex_mode_btn.add_theme_stylebox_override("hover", hover_unselected_style)
		reflex_mode_btn.add_theme_stylebox_override("pressed", unselected_style)
		reflex_mode_btn.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
		reflex_mode_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		classic_mode_btn.add_theme_stylebox_override("normal", unselected_style)
		classic_mode_btn.add_theme_stylebox_override("hover", hover_unselected_style)
		classic_mode_btn.add_theme_stylebox_override("pressed", unselected_style)
		classic_mode_btn.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
		classic_mode_btn.add_theme_color_override("font_hover_color", Color.WHITE)
		
		reflex_mode_btn.add_theme_stylebox_override("normal", selected_style)
		reflex_mode_btn.add_theme_stylebox_override("hover", selected_style)
		reflex_mode_btn.add_theme_stylebox_override("pressed", selected_style)
		reflex_mode_btn.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
		reflex_mode_btn.add_theme_color_override("font_hover_color", Color.from_string("#2c0050", Color.BLACK))

## Programmatically creates split-screen boundaries, divider lines, circular score bubbles, and combo badges
func _setup_arena_ui() -> void:
	if arena_ui:
		arena_ui.queue_free()
		
	arena_ui = Control.new()
	arena_ui.name = "ArenaUI"
	arena_ui.visible = false
	add_child(arena_ui)
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# 1. Split Screen Divider Line
	var divider = ColorRect.new()
	divider.name = "Divider"
	divider.color = Color(0.3, 0.27, 0.32, 0.4)
	divider.custom_minimum_size = Vector2(4, viewport_size.y)
	divider.size = Vector2(4, viewport_size.y)
	divider.position = Vector2(viewport_size.x / 2.0 - 2, 0)
	arena_ui.add_child(divider)
	
	# 2. Player 1 (Left Area) Border Accent Line (Muted Orchid)
	var p1_line = ColorRect.new()
	p1_line.name = "P1Line"
	p1_line.color = Color.from_string("#af93d4", Color.WHITE)
	p1_line.custom_minimum_size = Vector2(viewport_size.x / 2.0, 4)
	p1_line.size = Vector2(viewport_size.x / 2.0, 4)
	p1_line.position = Vector2(0, 0)
	arena_ui.add_child(p1_line)
	
	# 3. Player 2 (Right Area) Border Accent Line (Electric Yellow)
	var p2_line = ColorRect.new()
	p2_line.name = "P2Line"
	p2_line.color = Color.from_string("#ffff00", Color.WHITE)
	p2_line.custom_minimum_size = Vector2(viewport_size.x / 2.0, 4)
	p2_line.size = Vector2(viewport_size.x / 2.0, 4)
	p2_line.position = Vector2(viewport_size.x / 2.0, 0)
	arena_ui.add_child(p2_line)
	
	# 4. Player 1 Score Bubble (circular panel, 4px orchid border)
	p1_score_bubble = Panel.new()
	p1_score_bubble.name = "P1ScoreBubble"
	p1_score_bubble.custom_minimum_size = Vector2(160, 160)
	p1_score_bubble.size = Vector2(160, 160)
	p1_score_bubble.position = Vector2(viewport_size.x / 4.0 - 80, 40)
	
	var style1 = StyleBoxFlat.new()
	style1.bg_color = Color.from_string("#221e25", Color.BLACK)
	style1.set_border_width_all(4)
	style1.border_color = Color.from_string("#af93d4", Color.WHITE)
	style1.set_corner_radius_all(9999)
	style1.shadow_color = Color.from_string("#af93d4", Color.BLACK)
	style1.shadow_color.a = 0.2
	style1.shadow_size = 10
	p1_score_bubble.add_theme_stylebox_override("panel", style1)
	arena_ui.add_child(p1_score_bubble)
	
	p1_score_label = Label.new()
	p1_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p1_score_label.size = p1_score_bubble.size
	p1_score_label.text = "Oyuncu 1\n0"
	p1_score_label.add_theme_font_size_override("font_size", 18)
	p1_score_label.add_theme_color_override("font_color", Color.WHITE)
	p1_score_bubble.add_child(p1_score_label)
	
	# 5. Player 2 Score Bubble (circular panel, 4px yellow border)
	p2_score_bubble = Panel.new()
	p2_score_bubble.name = "P2ScoreBubble"
	p2_score_bubble.custom_minimum_size = Vector2(160, 160)
	p2_score_bubble.size = Vector2(160, 160)
	p2_score_bubble.position = Vector2(3.0 * viewport_size.x / 4.0 - 80, 40)
	
	var style2 = StyleBoxFlat.new()
	style2.bg_color = Color.from_string("#221e25", Color.BLACK)
	style2.set_border_width_all(4)
	style2.border_color = Color.from_string("#ffff00", Color.WHITE)
	style2.set_corner_radius_all(9999)
	style2.shadow_color = Color.from_string("#ffff00", Color.BLACK)
	style2.shadow_color.a = 0.25
	style2.shadow_size = 10
	p2_score_bubble.add_theme_stylebox_override("panel", style2)
	arena_ui.add_child(p2_score_bubble)
	
	p2_score_label = Label.new()
	p2_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p2_score_label.size = p2_score_bubble.size
	p2_score_label.text = "Oyuncu 2\n0"
	p2_score_label.add_theme_font_size_override("font_size", 18)
	p2_score_label.add_theme_color_override("font_color", Color.WHITE)
	p2_score_bubble.add_child(p2_score_label)
	
	# 6. Player 1 Combo Badge (pill-shaped, yellow bg, black text)
	p1_combo_badge = Panel.new()
	p1_combo_badge.name = "P1Combo"
	p1_combo_badge.custom_minimum_size = Vector2(90, 32)
	p1_combo_badge.size = Vector2(90, 32)
	p1_combo_badge.position = p1_score_bubble.position + Vector2(170, 64)
	p1_combo_badge.visible = false
	
	var combo_style = StyleBoxFlat.new()
	combo_style.bg_color = Color.from_string("#ffff00", Color.YELLOW)
	combo_style.set_corner_radius_all(9999)
	p1_combo_badge.add_theme_stylebox_override("panel", combo_style)
	arena_ui.add_child(p1_combo_badge)
	
	var p1_combo_lbl = Label.new()
	p1_combo_lbl.text = "Combo!"
	p1_combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_combo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p1_combo_lbl.size = p1_combo_badge.size
	p1_combo_lbl.add_theme_color_override("font_color", Color.BLACK)
	p1_combo_lbl.add_theme_font_size_override("font_size", 14)
	p1_combo_badge.add_child(p1_combo_lbl)
	
	# 7. Player 2 Combo Badge
	p2_combo_badge = Panel.new()
	p2_combo_badge.name = "P2Combo"
	p2_combo_badge.custom_minimum_size = Vector2(90, 32)
	p2_combo_badge.size = Vector2(90, 32)
	p2_combo_badge.position = p2_score_bubble.position + Vector2(170, 64)
	p2_combo_badge.visible = false
	p2_combo_badge.add_theme_stylebox_override("panel", combo_style)
	arena_ui.add_child(p2_combo_badge)
	
	var p2_combo_lbl = Label.new()
	p2_combo_lbl.text = "Combo!"
	p2_combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_combo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p2_combo_lbl.size = p2_combo_badge.size
	p2_combo_lbl.add_theme_color_override("font_color", Color.BLACK)
	p2_combo_lbl.add_theme_font_size_override("font_size", 14)
	p2_combo_badge.add_child(p2_combo_lbl)
	
	# 8. Target Container HBox (holds 3 panels for Reflex Mode, Level 3)
	target_hbox = HBoxContainer.new()
	target_hbox.name = "TargetHBox"
	target_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	target_hbox.add_theme_constant_override("separation", 12)
	target_hbox.visible = false # Only visible in reflex mode
	arena_ui.add_child(target_hbox)
	
	var target_style = StyleBoxFlat.new()
	target_style.bg_color = Color.from_string("#221e25", Color.BLACK)
	target_style.set_border_width_all(4)
	target_style.border_color = Color.from_string("#af93d4", Color.WHITE)
	target_style.set_corner_radius_all(9999)
	target_style.shadow_color = Color.from_string("#af93d4", Color.BLACK)
	target_style.shadow_color.a = 0.5
	target_style.shadow_size = 12
	
	target_containers.clear()
	for i in range(3):
		var panel = Panel.new()
		panel.name = "TargetContainer" + str(i + 1)
		panel.custom_minimum_size = Vector2(80, 80)
		panel.size = Vector2(80, 80)
		panel.add_theme_stylebox_override("panel", target_style)
		target_hbox.add_child(panel)
		
		var target_symbol = TargetSymbol.new()
		target_symbol.name = "TargetSymbol"
		target_symbol.custom_minimum_size = Vector2(80, 80)
		target_symbol.size = Vector2(80, 80)
		panel.add_child(target_symbol)
		
		target_containers.append(panel)
		
	# Fallback target_container reference to prevent crash if any legacy code calls it
	target_container = target_containers[1]

## Updates texts in score labels
func update_arena_scores(p1_n: String, p1_s: int, p2_n: String, p2_s: int) -> void:
	if p1_score_label:
		p1_score_label.text = p1_n + "\n" + str(p1_s)
	if p2_score_label:
		p2_score_label.text = p2_n + "\n" + str(p2_s)

func update_target_shape(symbol_ids: Array, monochrome: bool = false) -> void:
	if target_containers.size() >= 3:
		var show_three = (symbol_ids.size() >= 3)
		target_containers[0].visible = show_three
		target_containers[2].visible = show_three
		target_containers[1].visible = true
		
		if show_three:
			for i in range(3):
				var symbol = target_containers[i].get_node_or_null("TargetSymbol")
				if symbol:
					symbol.set_symbol_id(symbol_ids[i], false, monochrome)
		else:
			# Single target ID
			var symbol = target_containers[1].get_node_or_null("TargetSymbol")
			if symbol and symbol_ids.size() > 0:
				symbol.set_symbol_id(symbol_ids[0], false, monochrome)

func hide_target_shapes() -> void:
	for container in target_containers:
		if is_instance_valid(container):
			var symbol = container.get_node_or_null("TargetSymbol")
			if symbol:
				symbol.is_hidden = true
				symbol.queue_redraw()

func flash_score_bubble(player_num: int) -> void:
	var bubble = p1_score_bubble if player_num == 1 else p2_score_bubble
	if bubble == null:
		return
	
	bubble.pivot_offset = bubble.size / 2.0
	
	var t = create_tween()
	t.tween_property(bubble, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(bubble, "modulate", Color(1.5, 1.5, 1.5), 0.15)
	t.tween_property(bubble, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(bubble, "modulate", Color.WHITE, 0.15)

## Shows or hides combo badge with a scale pop tween
func show_combo_badge(player_num: int, show: bool) -> void:
	if player_num == 1 and p1_combo_badge:
		if p1_combo_badge.visible == show:
			return
		p1_combo_badge.visible = show
		if show:
			p1_combo_badge.scale = Vector2(0.5, 0.5)
			p1_combo_badge.pivot_offset = p1_combo_badge.size / 2.0
			var t = create_tween()
			t.tween_property(p1_combo_badge, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			t.tween_property(p1_combo_badge, "scale", Vector2(1.0, 1.0), 0.1)
	elif player_num == 2 and p2_combo_badge:
		if p2_combo_badge.visible == show:
			return
		p2_combo_badge.visible = show
		if show:
			p2_combo_badge.scale = Vector2(0.5, 0.5)
			p2_combo_badge.pivot_offset = p2_combo_badge.size / 2.0
			var t = create_tween()
			t.tween_property(p2_combo_badge, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			t.tween_property(p2_combo_badge, "scale", Vector2(1.0, 1.0), 0.1)

## Triggered when start button on welcome screen is pressed
func _on_start_pressed() -> void:
	if welcome_panel:
		welcome_panel.visible = false
	if name_input_panel:
		name_input_panel.visible = true

## Triggered when begin button on name input is pressed
func _on_begin_game_pressed() -> void:
	var p1_name = "Oyuncu 1"
	var p2_name = "Oyuncu 2"
	
	if p1_name_input and p1_name_input.text.strip_edges() != "":
		p1_name = p1_name_input.text.strip_edges()
	if p2_name_input and p2_name_input.text.strip_edges() != "":
		p2_name = p2_name_input.text.strip_edges()
		
	if name_input_panel:
		name_input_panel.visible = false
	
	var root = self.get_parent()
	var main_menu = _find_node_recursive(root, "MainMenu")
	if main_menu:
		main_menu.visible = false
		
	# Show the split-screen Arena UI
	if arena_ui:
		arena_ui.visible = true
		update_arena_scores(p1_name, 0, p2_name, 0)
		
		# Show/hide target container based on mode
		if target_hbox:
			target_hbox.visible = (selected_game_mode == "reflex")
			
		# Hide split-screen divider line in Reflex Mode
		var divider = arena_ui.get_node_or_null("Divider")
		if divider:
			divider.visible = (selected_game_mode == "classic")
		
	emit_signal("start_actual_game", p1_name, p2_name, selected_game_mode)

## Shows the LevelComplete screen with dynamic scoreboard rollup and winner glow
func show_level_complete(winner_name: String, level: int, p1_level_score: int, p2_level_score: int, p1_level_moves: int, p2_level_moves: int, p1_level_max_combo: int, p2_level_max_combo: int, winner_player: int) -> void:
	_current_level = level
	
	# Determine colors based on winner
	var glow_color: Color
	if winner_player == 1:
		glow_color = Color.from_string("#af93d4", Color.MAGENTA) # Orchid
	elif winner_player == 2:
		glow_color = Color.from_string("#ffff00", Color.YELLOW) # Electric Yellow
	else:
		glow_color = Color.from_string("#ddb7ff", Color.WHITE) # Tie lila
		
	# Update title text
	if winner_player == 0:
		win_title_label.text = "Beraberlik!"
	else:
		var w_name = p1_name_input.text.strip_edges() if winner_player == 1 else p2_name_input.text.strip_edges()
		if w_name == "":
			w_name = "Oyuncu 1" if winner_player == 1 else "Oyuncu 2"
		win_title_label.text = w_name + " Bu Seviyeyi Kazandı!"
		
	# Update congrats badges visibility
	p1_badge.visible = false
	p2_badge.visible = false
	
	# Fade in the winning badge
	if winner_player == 1:
		p1_badge.visible = true
		p1_badge.modulate.a = 0.0
		var bt = create_tween()
		bt.tween_property(p1_badge, "modulate:a", 1.0, 0.4)
	elif winner_player == 2:
		p2_badge.visible = true
		p2_badge.modulate.a = 0.0
		var bt = create_tween()
		bt.tween_property(p2_badge, "modulate:a", 1.0, 0.4)
		
	# Update stats summary labels
	combo_val_label.text = "x" + str(max(p1_level_max_combo, p2_level_max_combo)) + " Kombo"
	moves_val_label.text = str(p1_level_moves + p2_level_moves) + " Hamle"
	
	# Animate Player 1 score count up
	p1_score_val.text = "0"
	var t1 = create_tween()
	t1.tween_method(func(val): p1_score_val.text = str(int(val)), 0.0, float(p1_level_score), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Animate Player 2 score count up
	p2_score_val.text = "0"
	var t2 = create_tween()
	t2.tween_method(func(val): p2_score_val.text = str(int(val)), 0.0, float(p2_level_score), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Highlight Player 2 container border if Player 2 wins
	if p2_box_style:
		if winner_player == 2:
			p2_box_style.border_color = Color.from_string("#ffff00", Color.YELLOW)
			p2_box_style.shadow_color = Color.from_string("#ffff00", Color.YELLOW)
			p2_box_style.shadow_color.a = 0.3
			p2_box_style.shadow_size = 12
		else:
			p2_box_style.border_color = Color(1.0, 1.0, 0.0, 0.3)
			p2_box_style.shadow_size = 0
			
	# Dynamic championship glow tween transition
	var t = create_tween().set_parallel(true)
	t.tween_property(win_panel_style, "border_color", glow_color, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(win_panel_style, "shadow_color", Color(glow_color.r, glow_color.g, glow_color.b, 0.4), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	level_win_panel.queue_redraw()
	
	if level_win_panel:
		move_child(level_win_panel, get_child_count() - 1)
		level_win_panel.visible = true

## Transition to next level or show the tournament results
func _on_continue_pressed() -> void:
	if level_win_panel:
		level_win_panel.visible = false
		
	var max_level = 3 if selected_game_mode == "reflex" else 4
	if _current_level == max_level:
		show_tournament_complete()
	else:
		emit_signal("continue_game")

## Exit game / Show tournament completion
func _on_quit_pressed() -> void:
	show_tournament_complete()

## Center and align all UI nodes based on screen size
func _update_layout_positions() -> void:
	var root = self.get_parent()
	var main_menu = _find_node_recursive(root, "MainMenu")
	var viewport_size = get_viewport().get_visible_rect().size
	
	if main_menu:
		main_menu.size = viewport_size
		main_menu.position = Vector2.ZERO
		
	var background = _find_node_recursive(root, "Background")
	if background:
		background.size = viewport_size
		background.position = Vector2.ZERO
		
	if floating_grid:
		_start_grid_float_animation()
		
	var header = _find_node_recursive(root, "Header")
	if header:
		header.size = Vector2(viewport_size.x, 80)
		header.position = Vector2.ZERO
		
	if welcome_panel:
		welcome_panel.size = Vector2(900, 1000)
		welcome_panel.position = (viewport_size / 2.0) - (welcome_panel.size / 2.0)
	if name_input_panel:
		name_input_panel.size = Vector2(900, 850)
		name_input_panel.position = (viewport_size / 2.0) - (name_input_panel.size / 2.0)
		
	if how_to_play_panel:
		how_to_play_panel.size = Vector2(900, 600)
		how_to_play_panel.position = (viewport_size / 2.0) - (how_to_play_panel.size / 2.0)
		
	if level_win_panel:
		level_win_panel.anchor_right = 1.0
		level_win_panel.anchor_bottom = 1.0
		level_win_panel.offset_left = 0
		level_win_panel.offset_top = 0
		level_win_panel.offset_right = 0
		level_win_panel.offset_bottom = 0
		
		if central_panel:
			central_panel.size = Vector2(700, 560)
			central_panel.position = (viewport_size / 2.0) - (central_panel.size / 2.0)
			
		if win_float_card1:
			win_float_card1.position = Vector2(80, viewport_size.y * 0.25)
		if win_float_card2:
			win_float_card2.position = Vector2(viewport_size.x - 230, viewport_size.y * 0.7)
		if win_float_card3:
			win_float_card3.position = Vector2(viewport_size.x * 0.3, viewport_size.y * 0.75)

	if grand_win_panel:
		grand_win_panel.anchor_right = 1.0
		grand_win_panel.anchor_bottom = 1.0
		grand_win_panel.offset_left = 0
		grand_win_panel.offset_top = 0
		grand_win_panel.offset_right = 0
		grand_win_panel.offset_bottom = 0
		
		if grand_central_panel:
			grand_central_panel.size = Vector2(850, 640)
			grand_central_panel.position = (viewport_size / 2.0) - (grand_central_panel.size / 2.0)
			
		if grand_float_card1:
			grand_float_card1.size = Vector2(128, 192)
			grand_float_card1.position = Vector2(viewport_size.x * 0.15, viewport_size.y * 0.10)
		if grand_float_card2:
			grand_float_card2.size = Vector2(128, 192)
			grand_float_card2.position = Vector2(viewport_size.x * 0.05, viewport_size.y * 0.60)
		if grand_float_card3:
			grand_float_card3.size = Vector2(128, 192)
			grand_float_card3.position = Vector2(viewport_size.x * 0.90 - 128, viewport_size.y * 0.20)
		if grand_float_card4:
			grand_float_card4.size = Vector2(128, 192)
			grand_float_card4.position = Vector2(viewport_size.x * 0.80 - 128, viewport_size.y * 0.85 - 192)
		if grand_float_card5:
			grand_float_card5.size = Vector2(96, 144)
			grand_float_card5.position = Vector2(viewport_size.x * 0.60 - 96, viewport_size.y * 0.40)
			
		var sparkle1 = grand_win_panel.get_node_or_null("Sparkle1")
		if sparkle1:
			sparkle1.position = Vector2(40, 40)
		var sparkle2 = grand_win_panel.get_node_or_null("Sparkle2")
		if sparkle2:
			sparkle2.position = Vector2(viewport_size.x - 80, 80)
		var sparkle3 = grand_win_panel.get_node_or_null("Sparkle3")
		if sparkle3:
			sparkle3.position = Vector2(80, viewport_size.y - 120)
		var sparkle4 = grand_win_panel.get_node_or_null("Sparkle4")
		if sparkle4:
			sparkle4.position = Vector2(viewport_size.x - 120, viewport_size.y - 100)

	if developing_panel:
		developing_panel.size = Vector2(400, 300)
		developing_panel.position = (viewport_size / 2.0) - (developing_panel.size / 2.0)

	# Position split screen Arena UI components
	if arena_ui:
		var divider = arena_ui.get_node_or_null("Divider")
		if divider:
			divider.custom_minimum_size = Vector2(4, viewport_size.y)
			divider.size = Vector2(4, viewport_size.y)
			divider.position = Vector2(viewport_size.x / 2.0 - 2, 0)
			
		var p1_line = arena_ui.get_node_or_null("P1Line")
		if p1_line:
			p1_line.custom_minimum_size = Vector2(viewport_size.x / 2.0, 4)
			p1_line.size = Vector2(viewport_size.x / 2.0, 4)
			p1_line.position = Vector2(0, 0)
			
		var p2_line = arena_ui.get_node_or_null("P2Line")
		if p2_line:
			p2_line.custom_minimum_size = Vector2(viewport_size.x / 2.0, 4)
			p2_line.size = Vector2(viewport_size.x / 2.0, 4)
			p2_line.position = Vector2(viewport_size.x / 2.0, 0)
			
		if p1_score_bubble:
			p1_score_bubble.position = Vector2(viewport_size.x / 4.0 - 80, 40)
		if p2_score_bubble:
			p2_score_bubble.position = Vector2(3.0 * viewport_size.x / 4.0 - 80, 40)
			
		if p1_combo_badge and p1_score_bubble:
			p1_combo_badge.position = p1_score_bubble.position + Vector2(170, 64)
		if p2_combo_badge and p2_score_bubble:
			p2_combo_badge.position = p2_score_bubble.position + Vector2(170, 64)
		if target_hbox:
			target_hbox.custom_minimum_size = Vector2(264, 80)
			target_hbox.size = Vector2(264, 80)
			target_hbox.position = Vector2(viewport_size.x / 2.0 - 132, 70)

## Background floating grid cells configuration
func _setup_background_grid() -> void:
	if floating_grid == null:
		return
		
	floating_grid.modulate.a = 0.15 # opacity = 0.15 as requested
	floating_grid.columns = 12
	
	floating_grid.custom_minimum_size = Vector2(4000, 3200)
	floating_grid.size = Vector2(4000, 3200)
	
	for child in floating_grid.get_children():
		child.queue_free()
		
	var cell_style = StyleBoxFlat.new()
	cell_style.draw_center = false
	cell_style.border_color = Color(0.86, 0.71, 0.99, 0.35)
	cell_style.set_border_width_all(2)
	cell_style.set_corner_radius_all(20)
	
	for i in range(144):
		var cell = Panel.new()
		cell.custom_minimum_size = Vector2(300, 200)
		cell.add_theme_stylebox_override("panel", cell_style)
		floating_grid.add_child(cell)

## Glow circles configuration
func _setup_glow_circles_styling() -> void:
	if glow_circle1:
		var style1 = StyleBoxFlat.new()
		style1.bg_color = Color.from_string("#ba7ef4", Color.BLACK)
		style1.bg_color.a = 0.15
		style1.set_corner_radius_all(9999)
		style1.shadow_color = Color.from_string("#ba7ef4", Color.BLACK)
		style1.shadow_color.a = 0.1
		style1.shadow_size = 15
		glow_circle1.add_theme_stylebox_override("panel", style1)
		glow_circle1.custom_minimum_size = Vector2(150, 150)
		glow_circle1.size = Vector2(150, 150)
		glow_circle1.position = Vector2(-75, -75)
		glow_circle1.pivot_offset = Vector2(75, 75)
		
	if glow_circle2:
		var style2 = StyleBoxFlat.new()
		style2.bg_color = Color.from_string("#3d255e", Color.BLACK)
		style2.bg_color.a = 0.2
		style2.set_corner_radius_all(9999)
		style2.shadow_color = Color.from_string("#3d255e", Color.BLACK)
		style2.shadow_color.a = 0.15
		style2.shadow_size = 20
		glow_circle2.add_theme_stylebox_override("panel", style2)
		glow_circle2.custom_minimum_size = Vector2(150, 150)
		glow_circle2.size = Vector2(150, 150)
		glow_circle2.position = Vector2(900 - 75, 1000 - 75)
		glow_circle2.pivot_offset = Vector2(75, 75)

## Infinite süzülme (float) Tween animations
func _start_animations() -> void:
	# 1. Mascot Float
	if icon_box:
		icon_box.pivot_offset = icon_box.size / 2.0
		var base_y = icon_box.position.y
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(icon_box, "position:y", base_y - 12.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.parallel().tween_property(icon_box, "rotation_degrees", 3.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(icon_box, "position:y", base_y, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.parallel().tween_property(icon_box, "rotation_degrees", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. GlowCircle1 Pulse
	if glow_circle1:
		var pulse_tween1 = create_tween().set_loops()
		pulse_tween1.tween_property(glow_circle1, "scale", Vector2(1.15, 1.15), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween1.parallel().tween_property(glow_circle1, "modulate:a", 0.4, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween1.tween_property(glow_circle1, "scale", Vector2(0.95, 0.95), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween1.parallel().tween_property(glow_circle1, "modulate:a", 0.15, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# 3. GlowCircle2 Pulse
	if glow_circle2:
		var pulse_tween2 = create_tween().set_loops()
		pulse_tween2.tween_property(glow_circle2, "scale", Vector2(0.9, 0.9), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween2.parallel().tween_property(glow_circle2, "modulate:a", 0.1, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween2.tween_property(glow_circle2, "scale", Vector2(1.2, 1.2), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween2.parallel().tween_property(glow_circle2, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Background grid slow float animation
func _start_grid_float_animation() -> void:
	if floating_grid == null:
		return
		
	if _grid_tween:
		_grid_tween.kill()
		
	var viewport_size = get_viewport().get_visible_rect().size
	var base_pos = (viewport_size / 2.0) - (floating_grid.size / 2.0)
	floating_grid.position = base_pos
	floating_grid.rotation = 0.209 # 12 degrees
	
	_grid_tween = create_tween().set_loops()
	_grid_tween.tween_property(floating_grid, "position", base_pos + Vector2(60, 40), 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grid_tween.parallel().tween_property(floating_grid, "rotation", 0.209 + 0.04, 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grid_tween.tween_property(floating_grid, "position", base_pos, 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grid_tween.parallel().tween_property(floating_grid, "rotation", 0.209, 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Recursively binds squish scale/hover events to all buttons
func _setup_all_buttons_recursive(node: Node) -> void:
	if node is Button:
		_setup_button_effects(node)
	for child in node.get_children():
		_setup_all_buttons_recursive(child)

## Fluid button squish/glow transitions
func _setup_button_effects(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.item_rect_changed.connect(func(): btn.pivot_offset = btn.size / 2.0)
	
	btn.mouse_entered.connect(func():
		AudioManager.play_button_hover()
		var tween = create_tween().set_parallel(true)
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_property(btn, "self_modulate", Color(1.2, 1.1, 1.4), 0.12)
	)
	
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_property(btn, "self_modulate", Color.WHITE, 0.12)
	)
	
	btn.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_SINE)
	)
	
	btn.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_SINE)
	)

## Renders double overlapping cards mascot visual
func _setup_stacked_mascot_cards() -> void:
	if icon_box == null:
		return
		
	icon_box.text = ""
	icon_box.custom_minimum_size = Vector2(140, 140)
	icon_box.size = Vector2(140, 140)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	for child in icon_box.get_children():
		child.queue_free()
		
	# 1. Background Card (semi-transparent purple, -6 deg rotation)
	var bg_card = Panel.new()
	bg_card.custom_minimum_size = Vector2(100, 100)
	bg_card.size = Vector2(100, 100)
	bg_card.position = Vector2(20, 20)
	bg_card.pivot_offset = Vector2(50, 50)
	bg_card.rotation_degrees = -6
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.from_string("#d7bafe", Color.BLACK)
	bg_style.bg_color.a = 0.3
	bg_style.set_corner_radius_all(16)
	bg_card.add_theme_stylebox_override("panel", bg_style)
	icon_box.add_child(bg_card)
	
	# 2. Foreground Card (deep purple, border lila, +3 deg rotation)
	var fg_card = Panel.new()
	fg_card.custom_minimum_size = Vector2(100, 100)
	fg_card.size = Vector2(100, 100)
	fg_card.position = Vector2(20, 20)
	fg_card.pivot_offset = Vector2(50, 50)
	fg_card.rotation_degrees = 3
	
	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = Color.from_string("#4b0082", Color.BLACK)
	fg_style.set_border_width_all(2)
	fg_style.border_color = Color.from_string("#ddb7ff", Color.BLACK)
	fg_style.set_corner_radius_all(16)
	
	# Inner glowing shadow
	fg_style.shadow_color = Color.from_string("#ba7ef4", Color.BLACK)
	fg_style.shadow_color.a = 0.3
	fg_style.shadow_size = 12
	fg_card.add_theme_stylebox_override("panel", fg_style)
	icon_box.add_child(fg_card)
	
	# 3. Card Mascot Icon
	var fg_icon = Label.new()
	fg_icon.text = "✦"
	fg_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fg_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fg_icon.size = fg_card.size
	fg_icon.add_theme_font_size_override("font_size", 52)
	fg_icon.self_modulate = Color.from_string("#ddb7ff", Color.WHITE)
	fg_card.add_child(fg_icon)

## Programmatically builds the LevelWinPanel structure to match the design style
func _setup_level_win_panel() -> void:
	if level_win_panel == null:
		return
		
	# Clear static placeholder nodes in the tscn
	for child in level_win_panel.get_children():
		child.queue_free()
		
	# Root LevelWinPanel is now a full-screen overlay, set its StyleBox to solid `#161219`
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.from_string("#161219", Color.BLACK)
	level_win_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Create atmospheric background floating cards
	win_float_card1 = Panel.new()
	win_float_card1.name = "FloatCard1"
	win_float_card1.custom_minimum_size = Vector2(120, 160)
	win_float_card1.size = Vector2(120, 160)
	win_float_card1.rotation_degrees = -12
	win_float_card1.modulate.a = 0.08
	
	var f_style1 = StyleBoxFlat.new()
	f_style1.draw_center = false
	f_style1.set_border_width_all(2)
	f_style1.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	f_style1.set_corner_radius_all(16)
	win_float_card1.add_theme_stylebox_override("panel", f_style1)
	
	var f_lbl1 = Label.new()
	f_lbl1.text = "🎴"
	f_lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_lbl1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f_lbl1.size = win_float_card1.size
	f_lbl1.add_theme_font_size_override("font_size", 72)
	f_lbl1.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	win_float_card1.add_child(f_lbl1)
	level_win_panel.add_child(win_float_card1)
	
	win_float_card2 = Panel.new()
	win_float_card2.name = "FloatCard2"
	win_float_card2.custom_minimum_size = Vector2(150, 200)
	win_float_card2.size = Vector2(150, 200)
	win_float_card2.rotation_degrees = 15
	win_float_card2.modulate.a = 0.08
	
	var f_style2 = StyleBoxFlat.new()
	f_style2.draw_center = false
	f_style2.set_border_width_all(2)
	f_style2.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	f_style2.set_corner_radius_all(20)
	win_float_card2.add_theme_stylebox_override("panel", f_style2)
	
	var f_lbl2 = Label.new()
	f_lbl2.text = "🎴"
	f_lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_lbl2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f_lbl2.size = win_float_card2.size
	f_lbl2.add_theme_font_size_override("font_size", 96)
	f_lbl2.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	win_float_card2.add_child(f_lbl2)
	level_win_panel.add_child(win_float_card2)
	
	win_float_card3 = Panel.new()
	win_float_card3.name = "FloatCard3"
	win_float_card3.custom_minimum_size = Vector2(100, 130)
	win_float_card3.size = Vector2(100, 130)
	win_float_card3.rotation_degrees = -6
	win_float_card3.modulate.a = 0.08
	
	var f_style3 = StyleBoxFlat.new()
	f_style3.draw_center = false
	f_style3.set_border_width_all(2)
	f_style3.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	f_style3.set_corner_radius_all(14)
	win_float_card3.add_theme_stylebox_override("panel", f_style3)
	
	var f_lbl3 = Label.new()
	f_lbl3.text = "🎴"
	f_lbl3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_lbl3.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f_lbl3.size = win_float_card3.size
	f_lbl3.add_theme_font_size_override("font_size", 54)
	f_lbl3.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	win_float_card3.add_child(f_lbl3)
	level_win_panel.add_child(win_float_card3)
	
	# Start floating animations
	_start_win_floats()
	
	# Central Panel Container
	central_panel = Panel.new()
	central_panel.name = "CentralPanel"
	level_win_panel.add_child(central_panel)
	
	# Sparkle decorations
	var sparkle_left = Label.new()
	sparkle_left.name = "SparkleLeft"
	sparkle_left.text = "✨"
	sparkle_left.add_theme_font_size_override("font_size", 42)
	sparkle_left.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	sparkle_left.self_modulate.a = 0.5
	sparkle_left.anchor_left = 0.0
	sparkle_left.anchor_top = 0.0
	sparkle_left.offset_left = -30
	sparkle_left.offset_top = -35
	central_panel.add_child(sparkle_left)
	
	var sparkle_right = Label.new()
	sparkle_right.name = "SparkleRight"
	sparkle_right.text = "✨"
	sparkle_right.add_theme_font_size_override("font_size", 42)
	sparkle_right.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	sparkle_right.self_modulate.a = 0.5
	sparkle_right.anchor_left = 1.0
	sparkle_right.anchor_top = 0.0
	sparkle_right.offset_left = -15
	sparkle_right.offset_top = -35
	central_panel.add_child(sparkle_right)
	
	# Configure CentralPanel StyleBox
	win_panel_style = StyleBoxFlat.new()
	win_panel_style.bg_color = Color.from_string("#221e25", Color.BLACK)
	win_panel_style.set_corner_radius_all(24)
	win_panel_style.set_border_width_all(2)
	win_panel_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	win_panel_style.shadow_color = Color.from_string("#af93d4", Color.BLACK)
	win_panel_style.shadow_color.a = 0.4
	win_panel_style.shadow_size = 25
	central_panel.add_theme_stylebox_override("panel", win_panel_style)
	
	# Main container vbox (with padding)
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 40
	main_vbox.offset_top = 40
	main_vbox.offset_right = -40
	main_vbox.offset_bottom = -40
	main_vbox.add_theme_constant_override("separation", 28)
	central_panel.add_child(main_vbox)
	
	# 1. Headline section
	var head_vbox = VBoxContainer.new()
	head_vbox.add_theme_constant_override("separation", 6)
	main_vbox.add_child(head_vbox)
	
	win_title_label = Label.new()
	win_title_label.text = "P1 Bu Seviyeyi Kazandı!"
	win_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title_label.add_theme_font_size_override("font_size", 32)
	win_title_label.add_theme_color_override("font_color", Color.from_string("#e9e0ea", Color.WHITE))
	win_title_label.add_theme_constant_override("shadow_offset_x", 2)
	win_title_label.add_theme_constant_override("shadow_offset_y", 2)
	win_title_label.add_theme_color_override("shadow_color", Color(0.29, 0.0, 0.5, 0.3))
	head_vbox.add_child(win_title_label)
	
	win_subtitle_label = Label.new()
	win_subtitle_label.text = "ZAFER ANLARINI KUTLA"
	win_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_subtitle_label.add_theme_font_size_override("font_size", 14)
	win_subtitle_label.add_theme_color_override("font_color", Color.from_string("#ba7ef4", Color.MAGENTA))
	win_subtitle_label.add_theme_constant_override("tracking", 3)
	head_vbox.add_child(win_subtitle_label)
	
	# 2. Scoreboard section (Two columns)
	var score_hbox = HBoxContainer.new()
	score_hbox.add_theme_constant_override("separation", 24)
	score_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(score_hbox)
	
	# P1 Score Box
	var p1_box = Panel.new()
	p1_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p1_box_style = StyleBoxFlat.new()
	p1_box_style.bg_color = Color.from_string("#38333b", Color.BLACK)
	p1_box_style.set_border_width_all(2)
	p1_box_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	p1_box_style.set_corner_radius_all(12)
	p1_box.add_theme_stylebox_override("panel", p1_box_style)
	score_hbox.add_child(p1_box)
	
	var p1_layout = VBoxContainer.new()
	p1_layout.anchor_right = 1.0
	p1_layout.anchor_bottom = 1.0
	p1_layout.offset_top = 16
	p1_layout.offset_bottom = -16
	p1_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	p1_box.add_child(p1_layout)
	
	var p1_title = Label.new()
	p1_title.text = "PLAYER 1"
	p1_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_title.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.MAGENTA))
	p1_title.add_theme_font_size_override("font_size", 14)
	p1_layout.add_child(p1_title)
	
	p1_score_val = Label.new()
	p1_score_val.text = "0"
	p1_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_score_val.add_theme_font_size_override("font_size", 42)
	p1_score_val.add_theme_color_override("font_color", Color.WHITE)
	p1_layout.add_child(p1_score_val)
	
	var p1_puan_lbl = Label.new()
	p1_puan_lbl.text = "PUAN"
	p1_puan_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_puan_lbl.add_theme_font_size_override("font_size", 11)
	p1_puan_lbl.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	p1_layout.add_child(p1_puan_lbl)
	
	# P1 Congratulations Badge
	p1_badge = Panel.new()
	p1_badge.name = "P1WinBadge"
	p1_badge.size = Vector2(96, 26)
	p1_badge.anchor_left = 1.0
	p1_badge.anchor_right = 1.0
	p1_badge.offset_left = -96
	p1_badge.offset_top = 0
	p1_badge.offset_right = 0
	p1_badge.offset_bottom = 26
	
	var badge_style1 = StyleBoxFlat.new()
	badge_style1.bg_color = Color.from_string("#af93d4", Color.MAGENTA)
	badge_style1.corner_radius_top_left = 0
	badge_style1.corner_radius_top_right = 12
	badge_style1.corner_radius_bottom_right = 0
	badge_style1.corner_radius_bottom_left = 12
	p1_badge.add_theme_stylebox_override("panel", badge_style1)
	p1_box.add_child(p1_badge)
	
	var p1_badge_lbl = Label.new()
	p1_badge_lbl.text = "TEBRİKLER!"
	p1_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p1_badge_lbl.size = p1_badge.size
	p1_badge_lbl.add_theme_font_size_override("font_size", 10)
	p1_badge_lbl.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
	p1_badge.add_child(p1_badge_lbl)
	
	# P2 Score Box
	var p2_box = Panel.new()
	p2_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p2_box_style = StyleBoxFlat.new()
	p2_box_style.bg_color = Color.from_string("#38333b", Color.BLACK)
	p2_box_style.set_border_width_all(2)
	p2_box_style.border_color = Color(1.0, 1.0, 0.0, 0.3)
	p2_box_style.set_corner_radius_all(12)
	p2_box.add_theme_stylebox_override("panel", p2_box_style)
	score_hbox.add_child(p2_box)
	
	var p2_layout = VBoxContainer.new()
	p2_layout.anchor_right = 1.0
	p2_layout.anchor_bottom = 1.0
	p2_layout.offset_top = 16
	p2_layout.offset_bottom = -16
	p2_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	p2_box.add_child(p2_layout)
	
	var p2_title = Label.new()
	p2_title.text = "PLAYER 2"
	p2_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_title.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.YELLOW))
	p2_title.add_theme_font_size_override("font_size", 14)
	p2_layout.add_child(p2_title)
	
	p2_score_val = Label.new()
	p2_score_val.text = "0"
	p2_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_score_val.add_theme_font_size_override("font_size", 42)
	p2_score_val.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.YELLOW))
	p2_layout.add_child(p2_score_val)
	
	var p2_puan_lbl = Label.new()
	p2_puan_lbl.text = "PUAN"
	p2_puan_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_puan_lbl.add_theme_font_size_override("font_size", 11)
	p2_puan_lbl.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.YELLOW))
	p2_layout.add_child(p2_puan_lbl)
	
	# P2 Congratulations Badge
	p2_badge = Panel.new()
	p2_badge.name = "P2WinBadge"
	p2_badge.size = Vector2(96, 26)
	p2_badge.anchor_left = 1.0
	p2_badge.anchor_right = 1.0
	p2_badge.offset_left = -96
	p2_badge.offset_top = 0
	p2_badge.offset_right = 0
	p2_badge.offset_bottom = 26
	
	var badge_style2 = StyleBoxFlat.new()
	badge_style2.bg_color = Color.from_string("#ffff00", Color.YELLOW)
	badge_style2.corner_radius_top_left = 0
	badge_style2.corner_radius_top_right = 12
	badge_style2.corner_radius_bottom_right = 0
	badge_style2.corner_radius_bottom_left = 12
	p2_badge.add_theme_stylebox_override("panel", badge_style2)
	p2_box.add_child(p2_badge)
	
	var p2_badge_lbl = Label.new()
	p2_badge_lbl.text = "TEBRİKLER!"
	p2_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p2_badge_lbl.size = p2_badge.size
	p2_badge_lbl.add_theme_font_size_override("font_size", 10)
	p2_badge_lbl.add_theme_color_override("font_color", Color.BLACK)
	p2_badge.add_child(p2_badge_lbl)
	
	# 3. Stats summary section
	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 48)
	main_vbox.add_child(stats_hbox)
	
	var stats_separator = ColorRect.new()
	stats_separator.custom_minimum_size = Vector2(0, 1)
	stats_separator.color = Color(0.3, 0.27, 0.32, 0.4)
	main_vbox.add_child(stats_separator)
	main_vbox.move_child(stats_separator, main_vbox.get_child_count() - 2)
	
	# Column 1: Kazanılan Combo
	var combo_vbox = VBoxContainer.new()
	combo_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(combo_vbox)
	
	var combo_title = Label.new()
	combo_title.text = "KAZANILAN COMBO"
	combo_title.add_theme_font_size_override("font_size", 11)
	combo_title.add_theme_color_override("font_color", Color(0.81, 0.76, 0.83, 0.7))
	combo_vbox.add_child(combo_title)
	
	var combo_content_hbox = HBoxContainer.new()
	combo_content_hbox.add_theme_constant_override("separation", 8)
	combo_vbox.add_child(combo_content_hbox)
	
	var bolt_icon = Label.new()
	bolt_icon.text = "⚡"
	bolt_icon.add_theme_font_size_override("font_size", 18)
	bolt_icon.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.MAGENTA))
	combo_content_hbox.add_child(bolt_icon)
	
	combo_val_label = Label.new()
	combo_val_label.text = "x12 Kombo"
	combo_val_label.add_theme_font_size_override("font_size", 18)
	combo_val_label.add_theme_color_override("font_color", Color.WHITE)
	combo_content_hbox.add_child(combo_val_label)
	
	# Column 2: Toplam Hamle
	var moves_vbox = VBoxContainer.new()
	moves_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(moves_vbox)
	
	var moves_title = Label.new()
	moves_title.text = "TOPLAM HAMLE"
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moves_title.add_theme_font_size_override("font_size", 11)
	moves_title.add_theme_color_override("font_color", Color(0.81, 0.76, 0.83, 0.7))
	moves_vbox.add_child(moves_title)
	
	var moves_content_hbox = HBoxContainer.new()
	moves_content_hbox.add_theme_constant_override("separation", 8)
	moves_content_hbox.alignment = FlowContainer.ALIGNMENT_END
	moves_vbox.add_child(moves_content_hbox)
	
	var touch_icon = Label.new()
	touch_icon.text = "👆"
	touch_icon.add_theme_font_size_override("font_size", 18)
	touch_icon.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.MAGENTA))
	moves_content_hbox.add_child(touch_icon)
	
	moves_val_label = Label.new()
	moves_val_label.text = "42 Hamle"
	moves_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moves_val_label.add_theme_font_size_override("font_size", 18)
	moves_val_label.add_theme_color_override("font_color", Color.WHITE)
	moves_content_hbox.add_child(moves_val_label)
	
	# 4. Action buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(btn_hbox)
	
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "OYUNA DEVAM ET"
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.custom_minimum_size = Vector2(0, 56)
	
	var style_cont_normal = StyleBoxFlat.new()
	style_cont_normal.bg_color = Color.from_string("#af93d4", Color.MAGENTA)
	style_cont_normal.set_corner_radius_all(9999)
	style_cont_normal.shadow_color = Color(175/255.0, 147/255.0, 212/255.0, 0.4)
	style_cont_normal.shadow_size = 12
	
	var style_cont_hover = StyleBoxFlat.new()
	style_cont_hover.bg_color = Color.from_string("#c3a9e3", Color.MAGENTA)
	style_cont_hover.set_corner_radius_all(9999)
	style_cont_hover.shadow_color = Color(175/255.0, 147/255.0, 212/255.0, 0.6)
	style_cont_hover.shadow_size = 16
	
	continue_button.add_theme_stylebox_override("normal", style_cont_normal)
	continue_button.add_theme_stylebox_override("hover", style_cont_hover)
	continue_button.add_theme_stylebox_override("pressed", style_cont_normal)
	continue_button.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
	continue_button.add_theme_color_override("font_hover_color", Color.from_string("#2c0050", Color.BLACK))
	continue_button.add_theme_font_size_override("font_size", 16)
	btn_hbox.add_child(continue_button)
	
	quit_button = Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "OYUNU BİTİR"
	quit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit_button.custom_minimum_size = Vector2(0, 56)
	
	var style_quit_normal = StyleBoxFlat.new()
	style_quit_normal.draw_center = false
	style_quit_normal.set_border_width_all(2)
	style_quit_normal.border_color = Color.from_string("#4c4451", Color.DARK_GRAY)
	style_quit_normal.set_corner_radius_all(9999)
	
	var style_quit_hover = StyleBoxFlat.new()
	style_quit_hover.bg_color = Color.from_string("#38333b", Color.BLACK)
	style_quit_hover.set_border_width_all(2)
	style_quit_hover.border_color = Color.from_string("#cec3d3", Color.WHITE)
	style_quit_hover.set_corner_radius_all(9999)
	
	quit_button.add_theme_stylebox_override("normal", style_quit_normal)
	quit_button.add_theme_stylebox_override("hover", style_quit_hover)
	quit_button.add_theme_stylebox_override("pressed", style_quit_normal)
	quit_button.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	quit_button.add_theme_color_override("font_hover_color", Color.WHITE)
	quit_button.add_theme_font_size_override("font_size", 16)
	btn_hbox.add_child(quit_button)
	
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	_setup_button_effects(continue_button)
	_setup_button_effects(quit_button)

func _start_win_floats() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	_start_floating_card_animation(win_float_card1, viewport_size.y * 0.25, 0.0)
	_start_floating_card_animation(win_float_card2, viewport_size.y * 0.7, 2.0)
	_start_floating_card_animation(win_float_card3, viewport_size.y * 0.75, 4.0)

func _start_floating_card_animation(card: Control, base_y: float, delay: float) -> void:
	if card == null:
		return
	card.pivot_offset = card.size / 2.0
	var tween = create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	# Float up by 20px and rotate slightly
	tween.tween_property(card, "position:y", base_y - 20.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", card.rotation_degrees + 5.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Float back down
	tween.tween_property(card, "position:y", base_y, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", card.rotation_degrees, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Programmatically builds the GrandWinPanel structure to match the design style
func _setup_grand_win_panel() -> void:
	# Create overlay panel
	grand_win_panel = Panel.new()
	grand_win_panel.name = "GrandWinPanel"
	grand_win_panel.visible = false
	add_child(grand_win_panel)
	
	# Full-screen solid background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.from_string("#161219", Color.BLACK)
	grand_win_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Atmospheric background floating cards
	var create_float_card = func(rotation: float, opacity: float) -> Panel:
		var card = Panel.new()
		card.rotation_degrees = rotation
		card.modulate.a = opacity
		var style = StyleBoxFlat.new()
		style.draw_center = false
		style.set_border_width_all(2)
		style.border_color = Color.from_string("#4c4451", Color.DARK_GRAY)
		style.set_corner_radius_all(16)
		card.add_theme_stylebox_override("panel", style)
		return card
		
	grand_float_card1 = create_float_card.call(-12, 0.1)
	grand_float_card2 = create_float_card.call(15, 0.1)
	grand_float_card3 = create_float_card.call(-6, 0.1)
	grand_float_card4 = create_float_card.call(8, 0.1)
	grand_float_card5 = create_float_card.call(-15, 0.08)
	
	grand_win_panel.add_child(grand_float_card1)
	grand_win_panel.add_child(grand_float_card2)
	grand_win_panel.add_child(grand_float_card3)
	grand_win_panel.add_child(grand_float_card4)
	grand_win_panel.add_child(grand_float_card5)
	
	# Sparkle/Star decorations scattered in background
	var create_sparkle = func(text: String, size: int, color_str: String, opacity: float) -> Label:
		var lbl = Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", size)
		lbl.self_modulate = Color.from_string(color_str, Color.WHITE)
		lbl.self_modulate.a = opacity
		return lbl
		
	var sparkle1 = create_sparkle.call("✨", 36, "#ddb7ff", 0.4)
	sparkle1.name = "Sparkle1"
	grand_win_panel.add_child(sparkle1)
	
	var sparkle2 = create_sparkle.call("✦", 28, "#d7bafe", 0.4)
	sparkle2.name = "Sparkle2"
	grand_win_panel.add_child(sparkle2)
	
	var sparkle3 = create_sparkle.call("⭐", 24, "#ddb7ff", 0.3)
	sparkle3.name = "Sparkle3"
	grand_win_panel.add_child(sparkle3)
	
	var sparkle4 = create_sparkle.call("✦", 32, "#c5c5d8", 0.3)
	sparkle4.name = "Sparkle4"
	grand_win_panel.add_child(sparkle4)
	
	# Central Panel Container
	grand_central_panel = Panel.new()
	grand_central_panel.name = "GrandCentralPanel"
	grand_win_panel.add_child(grand_central_panel)
	
	grand_panel_style = StyleBoxFlat.new()
	grand_panel_style.bg_color = Color.from_string("#221e25", Color.BLACK)
	grand_panel_style.set_corner_radius_all(24)
	grand_panel_style.set_border_width_all(2)
	grand_panel_style.border_color = Color.from_string("#ddb7ff", Color.MAGENTA)
	grand_panel_style.border_color.a = 0.2
	
	# victory-glow shadow: size 80, orchid (#af93d4) at 0.25 alpha
	grand_panel_style.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
	grand_panel_style.shadow_color.a = 0.25
	grand_panel_style.shadow_size = 80
	grand_central_panel.add_theme_stylebox_override("panel", grand_panel_style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 40
	main_vbox.offset_top = 40
	main_vbox.offset_right = -40
	main_vbox.offset_bottom = -40
	main_vbox.add_theme_constant_override("separation", 28)
	grand_central_panel.add_child(main_vbox)
	
	# 1. Headline section
	var head_vbox = VBoxContainer.new()
	head_vbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(head_vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 12)
	head_vbox.add_child(title_hbox)
	
	grand_trophy_left = Label.new()
	grand_trophy_left.text = "🏆"
	grand_trophy_left.add_theme_font_size_override("font_size", 42)
	title_hbox.add_child(grand_trophy_left)
	
	grand_win_title = Label.new()
	grand_win_title.text = "TURNUVA ŞAMPİYONU:\nPLAYER 1!"
	grand_win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_win_title.add_theme_font_size_override("font_size", 30)
	grand_win_title.add_theme_color_override("font_color", Color.WHITE)
	grand_win_title.add_theme_constant_override("shadow_offset_x", 0)
	grand_win_title.add_theme_constant_override("shadow_offset_y", 0)
	grand_win_title.add_theme_color_override("shadow_color", Color.from_string("#ddb7ff", Color.MAGENTA))
	grand_win_title.add_theme_constant_override("shadow_outline_size", 12)
	title_hbox.add_child(grand_win_title)
	
	grand_trophy_right = Label.new()
	grand_trophy_right.text = "🏆"
	grand_trophy_right.add_theme_font_size_override("font_size", 42)
	title_hbox.add_child(grand_trophy_right)
	
	grand_win_subtitle = Label.new()
	grand_win_subtitle.text = "MUHTEŞEM BİR ZAFER!"
	grand_win_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_win_subtitle.add_theme_font_size_override("font_size", 14)
	grand_win_subtitle.add_theme_color_override("font_color", Color.from_string("#ba7ef4", Color.MAGENTA))
	grand_win_subtitle.add_theme_constant_override("tracking", 4)
	head_vbox.add_child(grand_win_subtitle)
	
	# 2. Scoreboard Section (Two columns)
	var score_hbox = HBoxContainer.new()
	score_hbox.add_theme_constant_override("separation", 24)
	score_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(score_hbox)
	
	# P1 Box
	grand_p1_box = Panel.new()
	grand_p1_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grand_p1_box_style = StyleBoxFlat.new()
	grand_p1_box_style.bg_color = Color.from_string("#38333b", Color.BLACK)
	grand_p1_box_style.set_border_width_all(2)
	grand_p1_box_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	grand_p1_box_style.set_corner_radius_all(12)
	grand_p1_box.add_theme_stylebox_override("panel", grand_p1_box_style)
	score_hbox.add_child(grand_p1_box)
	
	grand_p1_bg_icon = Label.new()
	grand_p1_bg_icon.text = "👑"
	grand_p1_bg_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grand_p1_bg_icon.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	grand_p1_bg_icon.anchor_right = 1.0
	grand_p1_bg_icon.offset_top = 8
	grand_p1_bg_icon.offset_right = -8
	grand_p1_bg_icon.add_theme_font_size_override("font_size", 72)
	grand_p1_bg_icon.self_modulate = Color.WHITE
	grand_p1_bg_icon.self_modulate.a = 0.15
	grand_p1_box.add_child(grand_p1_bg_icon)
	
	var p1_layout = VBoxContainer.new()
	p1_layout.anchor_right = 1.0
	p1_layout.anchor_bottom = 1.0
	p1_layout.offset_top = 16
	p1_layout.offset_bottom = -16
	p1_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	grand_p1_box.add_child(p1_layout)
	
	var p1_title_box = HBoxContainer.new()
	p1_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	p1_title_box.add_theme_constant_override("separation", 6)
	p1_layout.add_child(p1_title_box)
	
	var p1_crown_small = Label.new()
	p1_crown_small.text = "👑"
	p1_crown_small.add_theme_font_size_override("font_size", 14)
	p1_crown_small.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	p1_title_box.add_child(p1_crown_small)
	
	grand_p1_title = Label.new()
	grand_p1_title.text = "TOPLAM SKOR"
	grand_p1_title.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.MAGENTA))
	grand_p1_title.add_theme_font_size_override("font_size", 14)
	p1_title_box.add_child(grand_p1_title)
	
	grand_p1_score_val = Label.new()
	grand_p1_score_val.text = "0"
	grand_p1_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_p1_score_val.add_theme_font_size_override("font_size", 54)
	grand_p1_score_val.add_theme_color_override("font_color", Color.WHITE)
	grand_p1_score_val.add_theme_constant_override("shadow_offset_x", 0)
	grand_p1_score_val.add_theme_constant_override("shadow_offset_y", 0)
	grand_p1_score_val.add_theme_color_override("shadow_color", Color.from_string("#af93d4", Color.MAGENTA))
	grand_p1_score_val.add_theme_constant_override("shadow_outline_size", 10)
	p1_layout.add_child(grand_p1_score_val)
	
	grand_p1_puan_lbl = Label.new()
	grand_p1_puan_lbl.text = "PLAYER 1"
	grand_p1_puan_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_p1_puan_lbl.add_theme_font_size_override("font_size", 18)
	grand_p1_puan_lbl.add_theme_color_override("font_color", Color.from_string("#e9e0ea", Color.WHITE))
	p1_layout.add_child(grand_p1_puan_lbl)
	
	grand_p1_badge = Panel.new()
	grand_p1_badge.name = "P1WinBadge"
	grand_p1_badge.size = Vector2(96, 26)
	grand_p1_badge.anchor_left = 1.0
	grand_p1_badge.anchor_right = 1.0
	grand_p1_badge.offset_left = -96
	grand_p1_badge.offset_top = 0
	grand_p1_badge.offset_right = 0
	grand_p1_badge.offset_bottom = 26
	
	var badge_style1 = StyleBoxFlat.new()
	badge_style1.bg_color = Color.from_string("#af93d4", Color.MAGENTA)
	badge_style1.corner_radius_top_left = 0
	badge_style1.corner_radius_top_right = 12
	badge_style1.corner_radius_bottom_right = 0
	badge_style1.corner_radius_bottom_left = 12
	grand_p1_badge.add_theme_stylebox_override("panel", badge_style1)
	grand_p1_box.add_child(grand_p1_badge)
	
	var p1_badge_lbl = Label.new()
	p1_badge_lbl.text = "TEBRİKLER!"
	p1_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p1_badge_lbl.size = grand_p1_badge.size
	p1_badge_lbl.add_theme_font_size_override("font_size", 10)
	p1_badge_lbl.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
	grand_p1_badge.add_child(p1_badge_lbl)
	
	# P2 Box
	grand_p2_box = Panel.new()
	grand_p2_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grand_p2_box_style = StyleBoxFlat.new()
	grand_p2_box_style.bg_color = Color.from_string("#38333b", Color.BLACK)
	grand_p2_box_style.set_border_width_all(2)
	grand_p2_box_style.border_color = Color(1.0, 1.0, 0.0, 0.3)
	grand_p2_box_style.set_corner_radius_all(12)
	grand_p2_box.add_theme_stylebox_override("panel", grand_p2_box_style)
	score_hbox.add_child(grand_p2_box)
	
	grand_p2_bg_icon = Label.new()
	grand_p2_bg_icon.text = "😊"
	grand_p2_bg_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grand_p2_bg_icon.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	grand_p2_bg_icon.anchor_right = 1.0
	grand_p2_bg_icon.offset_top = 8
	grand_p2_bg_icon.offset_right = -8
	grand_p2_bg_icon.add_theme_font_size_override("font_size", 72)
	grand_p2_bg_icon.self_modulate = Color.WHITE
	grand_p2_bg_icon.self_modulate.a = 0.15
	grand_p2_box.add_child(grand_p2_bg_icon)
	
	var p2_layout = VBoxContainer.new()
	p2_layout.anchor_right = 1.0
	p2_layout.anchor_bottom = 1.0
	p2_layout.offset_top = 16
	p2_layout.offset_bottom = -16
	p2_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	grand_p2_box.add_child(p2_layout)
	
	var p2_title_box = HBoxContainer.new()
	p2_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	p2_title_box.add_theme_constant_override("separation", 6)
	p2_layout.add_child(p2_title_box)
	
	var p2_smiley_small = Label.new()
	p2_smiley_small.text = "😊"
	p2_smiley_small.add_theme_font_size_override("font_size", 14)
	p2_smiley_small.self_modulate = Color.from_string("#ffff00", Color.YELLOW)
	p2_title_box.add_child(p2_smiley_small)
	
	grand_p2_title = Label.new()
	grand_p2_title.text = "TOPLAM SKOR"
	grand_p2_title.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.YELLOW))
	grand_p2_title.add_theme_font_size_override("font_size", 14)
	p2_title_box.add_child(grand_p2_title)
	
	grand_p2_score_val = Label.new()
	grand_p2_score_val.text = "0"
	grand_p2_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_p2_score_val.add_theme_font_size_override("font_size", 54)
	grand_p2_score_val.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.YELLOW))
	p2_layout.add_child(grand_p2_score_val)
	
	grand_p2_puan_lbl = Label.new()
	grand_p2_puan_lbl.text = "PLAYER 2"
	grand_p2_puan_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_p2_puan_lbl.add_theme_font_size_override("font_size", 18)
	grand_p2_puan_lbl.add_theme_color_override("font_color", Color.from_string("#e9e0ea", Color.WHITE))
	p2_layout.add_child(grand_p2_puan_lbl)
	
	grand_p2_badge = Panel.new()
	grand_p2_badge.name = "P2WinBadge"
	grand_p2_badge.size = Vector2(96, 26)
	grand_p2_badge.anchor_left = 1.0
	grand_p2_badge.anchor_right = 1.0
	grand_p2_badge.offset_left = -96
	grand_p2_badge.offset_top = 0
	grand_p2_badge.offset_right = 0
	grand_p2_badge.offset_bottom = 26
	
	var badge_style2 = StyleBoxFlat.new()
	badge_style2.bg_color = Color.from_string("#ffff00", Color.YELLOW)
	badge_style2.corner_radius_top_left = 0
	badge_style2.corner_radius_top_right = 12
	badge_style2.corner_radius_bottom_right = 0
	badge_style2.corner_radius_bottom_left = 12
	grand_p2_badge.add_theme_stylebox_override("panel", badge_style2)
	grand_p2_box.add_child(grand_p2_badge)
	
	var p2_badge_lbl = Label.new()
	p2_badge_lbl.text = "TEBRİKLER!"
	p2_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p2_badge_lbl.size = grand_p2_badge.size
	p2_badge_lbl.add_theme_font_size_override("font_size", 10)
	p2_badge_lbl.add_theme_color_override("font_color", Color.BLACK)
	grand_p2_badge.add_child(p2_badge_lbl)
	
	# 3. Stats Summary Row
	var stats_hbox = HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.add_theme_constant_override("separation", 32)
	main_vbox.add_child(stats_hbox)
	
	var stats_separator = ColorRect.new()
	stats_separator.custom_minimum_size = Vector2(0, 1)
	stats_separator.color = Color(0.3, 0.27, 0.32, 0.4)
	main_vbox.add_child(stats_separator)
	main_vbox.move_child(stats_separator, main_vbox.get_child_count() - 2)
	
	var style_icon = Label.new()
	style_icon.text = "🎴"
	style_icon.add_theme_font_size_override("font_size", 18)
	style_icon.self_modulate = Color.from_string("#cec3d3", Color.WHITE)
	stats_hbox.add_child(style_icon)
	
	grand_stats_label1 = Label.new()
	grand_stats_label1.text = "Toplam Eşleştirilen Kart: 124"
	grand_stats_label1.add_theme_font_size_override("font_size", 14)
	grand_stats_label1.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	stats_hbox.add_child(grand_stats_label1)
	
	var vertical_line = ColorRect.new()
	vertical_line.custom_minimum_size = Vector2(1, 24)
	vertical_line.color = Color(0.3, 0.27, 0.32, 0.4)
	stats_hbox.add_child(vertical_line)
	
	var bolt_icon = Label.new()
	bolt_icon.text = "⚡"
	bolt_icon.add_theme_font_size_override("font_size", 18)
	bolt_icon.self_modulate = Color.from_string("#af93d4", Color.MAGENTA)
	stats_hbox.add_child(bolt_icon)
	
	grand_stats_label2 = Label.new()
	grand_stats_label2.text = "Turnuva Boyunca Yapılan Kombo: x48"
	grand_stats_label2.add_theme_font_size_override("font_size", 14)
	grand_stats_label2.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	stats_hbox.add_child(grand_stats_label2)
	
	# 4. Action Button ("ANA MENÜYE DÖN")
	grand_menu_button = Button.new()
	grand_menu_button.name = "MenuButton"
	grand_menu_button.text = "ANA MENÜYE DÖN"
	grand_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grand_menu_button.custom_minimum_size = Vector2(320, 56)
	
	var style_menu_normal = StyleBoxFlat.new()
	style_menu_normal.bg_color = Color.from_string("#af93d4", Color.MAGENTA)
	style_menu_normal.set_corner_radius_all(9999)
	style_menu_normal.shadow_color = Color(175/255.0, 147/255.0, 212/255.0, 0.3)
	style_menu_normal.shadow_size = 12
	
	var style_menu_hover = StyleBoxFlat.new()
	style_menu_hover.bg_color = Color.from_string("#c3a9e3", Color.MAGENTA)
	style_menu_hover.set_corner_radius_all(9999)
	style_menu_hover.shadow_color = Color(175/255.0, 147/255.0, 212/255.0, 0.5)
	style_menu_hover.shadow_size = 16
	
	grand_menu_button.add_theme_stylebox_override("normal", style_menu_normal)
	grand_menu_button.add_theme_stylebox_override("hover", style_menu_hover)
	grand_menu_button.add_theme_stylebox_override("pressed", style_menu_normal)
	grand_menu_button.add_theme_color_override("font_color", Color.from_string("#2c0050", Color.BLACK))
	grand_menu_button.add_theme_color_override("font_hover_color", Color.from_string("#2c0050", Color.BLACK))
	grand_menu_button.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(grand_menu_button)
	
	grand_menu_button.pressed.connect(_on_menu_pressed)
	
	grand_menu_button.pivot_offset = grand_menu_button.custom_minimum_size / 2.0
	grand_menu_button.item_rect_changed.connect(func(): grand_menu_button.pivot_offset = grand_menu_button.size / 2.0)
	
	grand_menu_button.mouse_entered.connect(func():
		AudioManager.play_button_hover()
		var tween = create_tween().set_parallel(true)
		tween.tween_property(grand_menu_button, "scale", Vector2(1.10, 1.10), 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_property(grand_menu_button, "self_modulate", Color(1.2, 1.1, 1.4), 0.12)
	)
	grand_menu_button.mouse_exited.connect(func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(grand_menu_button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_property(grand_menu_button, "self_modulate", Color.WHITE, 0.12)
	)
	grand_menu_button.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(grand_menu_button, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_SINE)
	)
	grand_menu_button.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(grand_menu_button, "scale", Vector2(1.10, 1.10), 0.08).set_trans(Tween.TRANS_SINE)
	)

func _start_grand_win_floats() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	_start_grand_floating_card_animation(grand_float_card1, viewport_size.y * 0.10, -12.0, 0.0)
	_start_grand_floating_card_animation(grand_float_card2, viewport_size.y * 0.60, 15.0, 2.0)
	_start_grand_floating_card_animation(grand_float_card3, viewport_size.y * 0.20, -6.0, 1.0)
	_start_grand_floating_card_animation(grand_float_card4, viewport_size.y * 0.85 - 192, 8.0, 3.0)
	_start_grand_floating_card_animation(grand_float_card5, viewport_size.y * 0.40, -15.0, 4.0)

func _start_grand_floating_card_animation(card: Control, base_y: float, base_rot: float, delay: float) -> void:
	if card == null:
		return
	card.pivot_offset = card.size / 2.0
	var tween = create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(card, "position:y", base_y - 20.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", base_rot + 5.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "modulate:a", 0.2, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position:y", base_y, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", base_rot, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card, "modulate:a", 0.1, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_trophy_animations() -> void:
	if grand_trophy_left:
		grand_trophy_left.pivot_offset = grand_trophy_left.size / 2.0
		var base_y = grand_trophy_left.position.y
		var t1 = create_tween().set_loops()
		t1.tween_property(grand_trophy_left, "position:y", base_y - 10.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t1.parallel().tween_property(grand_trophy_left, "scale", Vector2(1.1, 1.1), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t1.tween_property(grand_trophy_left, "position:y", base_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t1.parallel().tween_property(grand_trophy_left, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	if grand_trophy_right:
		grand_trophy_right.pivot_offset = grand_trophy_right.size / 2.0
		var base_y = grand_trophy_right.position.y
		var t2 = create_tween().set_loops()
		t2.tween_interval(0.5)
		t2.tween_property(grand_trophy_right, "position:y", base_y - 10.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t2.parallel().tween_property(grand_trophy_right, "scale", Vector2(1.1, 1.1), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t2.tween_property(grand_trophy_right, "position:y", base_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t2.parallel().tween_property(grand_trophy_right, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_shimmer_animation() -> void:
	if grand_win_title:
		grand_win_title.pivot_offset = grand_win_title.size / 2.0
		var t = create_tween().set_loops()
		t.tween_method(func(val):
			grand_win_title.add_theme_color_override("shadow_color", Color(0.86, 0.71, 0.99, val))
			grand_win_title.add_theme_constant_override("shadow_outline_size", int(val * 20.0))
		, 0.2, 0.6, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(func(val):
			grand_win_title.add_theme_color_override("shadow_color", Color(0.86, 0.71, 0.99, val))
			grand_win_title.add_theme_constant_override("shadow_outline_size", int(val * 20.0))
		, 0.6, 0.2, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func show_tournament_complete() -> void:
	AudioManager.stop_bgm()
	AudioManager.play_celebration()
	var root = self.get_parent()
	var game = root as Game
	var stats = game.get_tournament_results()
	
	var p1_final_score = stats["p1_score"]
	var p2_final_score = stats["p2_score"]
	var p1_final_moves = stats["p1_moves"]
	var p2_final_moves = stats["p2_moves"]
	var p1_final_combo = stats["p1_combo"]
	var p2_final_combo = stats["p2_combo"]
	var p1_final_matched = stats["p1_matched"]
	var p2_final_matched = stats["p2_matched"]
	var winner = stats["winner"]
	
	var p1_name = p1_name_input.text.strip_edges()
	if p1_name == "":
		p1_name = "Oyuncu 1"
	var p2_name = p2_name_input.text.strip_edges()
	if p2_name == "":
		p2_name = "Oyuncu 2"
		
	if winner == 1:
		grand_win_title.text = "TURNUVA ŞAMPİYONU:\n" + p1_name.to_upper() + "!"
		grand_p1_badge.visible = true
		grand_p2_badge.visible = false
		
		grand_p1_box_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
		grand_p1_box_style.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
		grand_p1_box_style.shadow_color.a = 0.4
		grand_p1_box_style.shadow_size = 12
		grand_p1_bg_icon.visible = true
		
		grand_p2_box_style.border_color = Color(1.0, 1.0, 0.0, 0.3)
		grand_p2_box_style.shadow_size = 0
		grand_p2_bg_icon.visible = false
		
		grand_panel_style.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
		grand_panel_style.shadow_color.a = 0.25
	elif winner == 2:
		grand_win_title.text = "TURNUVA ŞAMPİYONU:\n" + p2_name.to_upper() + "!"
		grand_p1_badge.visible = false
		grand_p2_badge.visible = true
		
		grand_p2_box_style.border_color = Color.from_string("#ffff00", Color.YELLOW)
		grand_p2_box_style.shadow_color = Color.from_string("#ffff00", Color.YELLOW)
		grand_p2_box_style.shadow_color.a = 0.4
		grand_p2_box_style.shadow_size = 12
		grand_p2_bg_icon.visible = true
		
		grand_p1_box_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
		grand_p1_box_style.border_color.a = 0.3
		grand_p1_box_style.shadow_size = 0
		grand_p1_bg_icon.visible = false
		
		grand_panel_style.shadow_color = Color.from_string("#ffff00", Color.YELLOW)
		grand_panel_style.shadow_color.a = 0.25
	else:
		grand_win_title.text = "TURNUVA ŞAMPİYONU:\nBERABERLİK!"
		grand_p1_badge.visible = false
		grand_p2_badge.visible = false
		
		grand_p1_box_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
		grand_p1_box_style.shadow_size = 0
		grand_p1_bg_icon.visible = false
		
		grand_p2_box_style.border_color = Color(1.0, 1.0, 0.0, 0.3)
		grand_p2_box_style.shadow_size = 0
		grand_p2_bg_icon.visible = false
		
		grand_panel_style.shadow_color = Color.from_string("#ddb7ff", Color.MAGENTA)
		grand_panel_style.shadow_color.a = 0.25
		
	grand_p1_puan_lbl.text = p1_name
	grand_p2_puan_lbl.text = p2_name
	
	grand_p1_score_val.text = "0"
	var t1 = create_tween()
	t1.tween_method(func(val): grand_p1_score_val.text = str(int(val)), 0.0, float(p1_final_score), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	grand_p2_score_val.text = "0"
	var t2 = create_tween()
	t2.tween_method(func(val): grand_p2_score_val.text = str(int(val)), 0.0, float(p2_final_score), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var total_matched = p1_final_matched + p2_final_matched
	var max_combo = max(p1_final_combo, p2_final_combo)
	grand_stats_label1.text = "Toplam Eşleştirilen Kart: " + str(total_matched)
	grand_stats_label2.text = "Turnuva Boyunca Yapılan Kombo: x" + str(max_combo)
	
	if arena_ui:
		arena_ui.visible = false
	if level_win_panel:
		level_win_panel.visible = false
	if developing_panel:
		developing_panel.visible = false
		
	move_child(grand_win_panel, get_child_count() - 1)
	
	grand_win_panel.modulate.a = 0.0
	grand_win_panel.visible = true
	
	grand_central_panel.scale = Vector2(0.95, 0.95)
	grand_central_panel.pivot_offset = grand_central_panel.size / 2.0
	
	var ent = create_tween().set_parallel(true)
	ent.tween_property(grand_win_panel, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ent.tween_property(grand_central_panel, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	_start_grand_win_floats()
	_start_trophy_animations()
	_start_shimmer_animation()

func _on_menu_pressed() -> void:
	var root = self.get_parent()
	var game = root as Game
	if game:
		game.reset_tournament()
		
	if grand_win_panel:
		grand_win_panel.visible = false
	if level_win_panel:
		level_win_panel.visible = false
	if developing_panel:
		developing_panel.visible = false
	if arena_ui:
		arena_ui.visible = false
		
	var main_menu = _find_node_recursive(root, "MainMenu")
	if main_menu:
		main_menu.visible = true
	if welcome_panel:
		welcome_panel.visible = true
	if name_input_panel:
		name_input_panel.visible = false
		
	if p1_name_input:
		p1_name_input.text = ""
	if p2_name_input:
		p2_name_input.text = ""

func _setup_how_to_play_panel() -> void:
	var root = self.get_parent()
	var main_menu = _find_node_recursive(root, "MainMenu")
	if main_menu == null:
		return
		
	# Create panel
	how_to_play_panel = Panel.new()
	how_to_play_panel.name = "HowToPlayPanel"
	how_to_play_panel.custom_minimum_size = Vector2(900, 600)
	how_to_play_panel.size = Vector2(900, 600)
	how_to_play_panel.visible = false
	
	# Apply theme styling matching name_input_panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color.from_string("#1a1520", Color.BLACK)
	panel_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color.from_string("#af93d4", Color.BLACK)
	panel_style.shadow_color.a = 0.25
	panel_style.shadow_size = 15
	how_to_play_panel.add_theme_stylebox_override("panel", panel_style)
	main_menu.add_child(how_to_play_panel)
	
	# ScrollContainer to support scrolling content comfortably
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 440)
	scroll.size = Vector2(820, 440)
	scroll.position = Vector2(40, 40)
	# Hide horizontal scrollbar, enable vertical scrollbar
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	how_to_play_panel.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 24)
	content_vbox.custom_minimum_size = Vector2(800, 0)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Nasıl Oynanır?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.WHITE))
	content_vbox.add_child(title)
	
	# Introduction
	var intro = Label.new()
	intro.text = "Card Clash, hafıza ve hızı bir araya getiren 1v1 rekabetçi bir kart oyunudur. Oyunda iki farklı oyun modu bulunmaktadır:"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 16)
	content_vbox.add_child(intro)
	
	# Separator
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 2)
	sep1.color = Color(0.3, 0.27, 0.32, 0.4)
	content_vbox.add_child(sep1)
	
	# Klasik Mod Section
	var classic_title = Label.new()
	classic_title.text = "1. KLASİK MOD (Hafıza Tabanlı Rekabet)"
	classic_title.add_theme_font_size_override("font_size", 20)
	classic_title.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.WHITE))
	content_vbox.add_child(classic_title)
	
	var classic_desc = Label.new()
	classic_desc.text = "• Her iki oyuncu kendi tarafındaki kartlarla aynı anda oynar (P1 Solda, P2 Sağda).\n• Sıra bekleme yoktur; her oyuncu kendi hızında kartları açarak eşleştirmeye çalışır.\n• Açılan iki kartın şekli aynıysa eşleşir ve oyuncu puan kazanır.\n• Üst üste hızlı/doğru eşleşmeler yapmak 'Combo' çarpanı kazandırır ve puanınızı katlar.\n• Yanlış eşleşme yapıldığında açılan kartlar kapanır, ancak diğer oyuncuyu etkilemez."
	classic_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	classic_desc.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(classic_desc)
	
	# Separator
	var sep2 = ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 2)
	sep2.color = Color(0.3, 0.27, 0.32, 0.4)
	content_vbox.add_child(sep2)
	
	# Refleks Modu Section
	var reflex_title = Label.new()
	reflex_title.text = "2. REFLEKS MODU (Hız & Ortak Havuz)"
	reflex_title.add_theme_font_size_override("font_size", 20)
	reflex_title.add_theme_color_override("font_color", Color.from_string("#ffff00", Color.WHITE))
	content_vbox.add_child(reflex_title)
	
	var reflex_desc = Label.new()
	reflex_desc.text = "• Ekranın ortasında ortak 40 karttan oluşan tek bir grid bulunur.\n• Oyuncular aynı anda (gerçek zamanlı olarak) bu grid üzerinde gezinir.\n• Ekranın en üstünde hedeflenen şekil gösterilir. Bu şekli ilk bulan puanı (10 Puan) kazanır!\n• Yanlış karta basarsanız 1.5 saniye boyunca hareket edemezsiniz (Donma Cezası).\n• Eşleşme sağlandığında yerdeki kart kaybolur, kalan kartlar karıştırılır ve yeni hedef belirlenir.\n• Seviye 2 Kuralı: Mor kartların üzerindeki şekiller renksiz (beyaz) çizilir, dikkatli olun!\n• Seviye 3 Kuralı: Üstte 3 hedef şekil gösterilir ve 3 saniye sonra gizlenir. 10 saniye içinde bulmaya çalışmalısınız. Süre biterse veya hedefler bulunursa yeni hedefler belirlenip grid karıştırılır."
	reflex_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	reflex_desc.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(reflex_desc)
	
	# Separator
	var sep3 = ColorRect.new()
	sep3.custom_minimum_size = Vector2(0, 2)
	sep3.color = Color(0.3, 0.27, 0.32, 0.4)
	content_vbox.add_child(sep3)
	
	# Controls Section
	var controls_title = Label.new()
	controls_title.text = "KONTROLLER"
	controls_title.add_theme_font_size_override("font_size", 20)
	controls_title.add_theme_color_override("font_color", Color.WHITE)
	content_vbox.add_child(controls_title)
	
	var controls_desc = Label.new()
	controls_desc.text = "• Oyuncu 1: Yönlendirme için [W][A][S][D] tuşlarını, kart seçmek/açmak için [Boşluk (Space)] tuşunu kullanır.\n• Oyuncu 2: Yönlendirme için [Yön Tuşları (Oklar)] tuşlarını, kart seçmek/açmak için [Giriş (Enter)] tuşunu kullanır."
	controls_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	controls_desc.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(controls_desc)
	
	# Back Button (Geri Dön)
	var back_btn = Button.new()
	back_btn.text = "Geri Dön"
	back_btn.custom_minimum_size = Vector2(240, 50)
	back_btn.size = Vector2(240, 50)
	back_btn.position = Vector2(450 - 120, 530)
	back_btn.add_theme_font_size_override("font_size", 18)
	how_to_play_panel.add_child(back_btn)
	
	back_btn.pressed.connect(func():
		how_to_play_panel.visible = false
		welcome_panel.visible = true
	)
	_setup_button_effects(back_btn)

func _on_how_to_play_pressed() -> void:
	if welcome_panel:
		welcome_panel.visible = false
	if how_to_play_panel:
		how_to_play_panel.visible = true

class TargetSymbol extends Control:
	var id: int = -1
	var is_hidden: bool = false
	var is_monochrome: bool = false
	
	func set_symbol_id(symbol_id: int, hidden: bool = false, monochrome: bool = false) -> void:
		id = symbol_id
		is_hidden = hidden
		is_monochrome = monochrome
		queue_redraw()
		
	func _draw() -> void:
		var center = size / 2.0
		if id < 0 or is_hidden:
			# Draw card back lavender star symbol
			var orchid_color = Color.from_string("#af93d4", Color.MAGENTA)
			draw_line(center - Vector2(16, 0), center + Vector2(16, 0), orchid_color, 3.0)
			draw_line(center - Vector2(0, 16), center + Vector2(0, 16), orchid_color, 3.0)
			draw_circle(center, 5.0, orchid_color)
			return
			
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
			symbol_color = colors[id % colors.size()]
		var symbol_type = id % 30
		
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


# Settings UI nodes
var settings_btn: Button
var settings_panel: Panel
var settings_bg_overlay: ColorRect

func _create_settings_ui() -> void:
	# 1. Settings Button (Top-Right Floating Button)
	settings_btn = Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "⚙"
	settings_btn.custom_minimum_size = Vector2(56, 56)
	settings_btn.size = Vector2(56, 56)
	
	# Top right anchors
	settings_btn.anchor_left = 1.0
	settings_btn.anchor_right = 1.0
	settings_btn.anchor_top = 0.0
	settings_btn.anchor_bottom = 0.0
	settings_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	settings_btn.grow_vertical = Control.GROW_DIRECTION_END
	settings_btn.offset_left = -76
	settings_btn.offset_top = 20
	settings_btn.offset_right = -20
	settings_btn.offset_bottom = 76
	
	# Style the Settings Button
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color.from_string("#221e25", Color.BLACK)
	btn_normal.set_border_width_all(2)
	btn_normal.border_color = Color.from_string("#4c4451", Color.DARK_GRAY)
	btn_normal.set_corner_radius_all(9999) # Round
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	btn_hover.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
	btn_hover.shadow_color.a = 0.3
	btn_hover.shadow_size = 8
	
	settings_btn.add_theme_stylebox_override("normal", btn_normal)
	settings_btn.add_theme_stylebox_override("hover", btn_hover)
	settings_btn.add_theme_stylebox_override("pressed", btn_normal)
	settings_btn.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	settings_btn.add_theme_color_override("font_hover_color", Color.from_string("#af93d4", Color.WHITE))
	settings_btn.add_theme_font_size_override("font_size", 28)
	
	add_child(settings_btn)
	_setup_button_effects(settings_btn)
	
	# 2. Semi-transparent background overlay when settings is open
	settings_bg_overlay = ColorRect.new()
	settings_bg_overlay.name = "SettingsBgOverlay"
	settings_bg_overlay.color = Color(0, 0, 0, 0.5)
	settings_bg_overlay.visible = false
	settings_bg_overlay.anchor_right = 1.0
	settings_bg_overlay.anchor_bottom = 1.0
	add_child(settings_bg_overlay)
	
	# Make overlay intercept clicks to close settings
	settings_bg_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_toggle_settings(false)
	)
	
	# 3. Settings Panel
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.custom_minimum_size = Vector2(450, 340)
	settings_panel.size = Vector2(450, 340)
	settings_panel.visible = false
	
	settings_panel.anchor_left = 0.5
	settings_panel.anchor_right = 0.5
	settings_panel.anchor_top = 0.5
	settings_panel.anchor_bottom = 0.5
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_panel.offset_left = -225
	settings_panel.offset_right = 225
	settings_panel.offset_top = -170
	settings_panel.offset_bottom = 170
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color.from_string("#1a1520", Color.BLACK)
	panel_style.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color.BLACK
	panel_style.shadow_color.a = 0.4
	panel_style.shadow_size = 20
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(settings_panel)
	
	# VBox container for settings items
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 40
	vbox.offset_top = 30
	vbox.offset_right = -40
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 24)
	settings_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "SES AYARLARI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.from_string("#af93d4", Color.WHITE))
	vbox.add_child(title)
	
	# BGM Section
	var bgm_vbox = VBoxContainer.new()
	bgm_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(bgm_vbox)
	
	var bgm_label = Label.new()
	bgm_label.text = "Müzik Ses Seviyesi"
	bgm_label.add_theme_font_size_override("font_size", 15)
	bgm_label.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	bgm_vbox.add_child(bgm_label)
	
	var bgm_slider = HSlider.new()
	bgm_slider.name = "BgmSlider"
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	bgm_slider.value = AudioManager.bgm_volume
	bgm_vbox.add_child(bgm_slider)
	bgm_slider.value_changed.connect(func(value):
		AudioManager.set_bgm_volume(value)
	)
	
	# SFX Section
	var sfx_vbox = VBoxContainer.new()
	sfx_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(sfx_vbox)
	
	var sfx_label = Label.new()
	sfx_label.text = "Ses Efektleri Seviyesi"
	sfx_label.add_theme_font_size_override("font_size", 15)
	sfx_label.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	sfx_vbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.name = "SfxSlider"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = AudioManager.sfx_volume
	sfx_vbox.add_child(sfx_slider)
	sfx_slider.value_changed.connect(func(value):
		AudioManager.set_sfx_volume(value)
	)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = "KAPAT"
	close_btn.custom_minimum_size = Vector2(180, 42)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var close_normal = StyleBoxFlat.new()
	close_normal.bg_color = Color.from_string("#38333b", Color.BLACK)
	close_normal.set_border_width_all(2)
	close_normal.border_color = Color.from_string("#4c4451", Color.DARK_GRAY)
	close_normal.set_corner_radius_all(9999)
	
	var close_hover = close_normal.duplicate()
	close_hover.border_color = Color.from_string("#af93d4", Color.MAGENTA)
	close_hover.shadow_color = Color.from_string("#af93d4", Color.MAGENTA)
	close_hover.shadow_color.a = 0.2
	close_hover.shadow_size = 6
	
	close_btn.add_theme_stylebox_override("normal", close_normal)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_normal)
	close_btn.add_theme_color_override("font_color", Color.from_string("#cec3d3", Color.WHITE))
	close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	close_btn.add_theme_font_size_override("font_size", 15)
	
	vbox.add_child(close_btn)
	_setup_button_effects(close_btn)
	
	close_btn.pressed.connect(func():
		_toggle_settings(false)
	)
	
	settings_btn.pressed.connect(func():
		_toggle_settings(!settings_panel.visible)
	)

func _toggle_settings(is_open: bool) -> void:
	settings_panel.visible = is_open
	settings_bg_overlay.visible = is_open
	if is_open:
		# Draw on top of everything
		move_child(settings_bg_overlay, get_child_count() - 1)
		move_child(settings_panel, get_child_count() - 1)
		# Update slider values to match current volume in case they changed
		var bgm_slider = settings_panel.find_child("BgmSlider", true, false) as HSlider
		if bgm_slider:
			bgm_slider.value = AudioManager.bgm_volume
		var sfx_slider = settings_panel.find_child("SfxSlider", true, false) as HSlider
		if sfx_slider:
			sfx_slider.value = AudioManager.sfx_volume
