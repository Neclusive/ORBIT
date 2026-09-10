extends Node2D

@export var speed_min: float = 350.0
@export var speed_max: float = 450.0
@export var base_thickness: float = 22.0
@export var arc_segments: int = 64
@export var radial_segments: int = 8

@export var min_arc_angle: float = 45.0
@export var max_arc_angle: float = 135.0
@export var spawn_interval: float = 1.3

@export_range(0, 100) var sticky_spawn_chance: int = 30
@export var sticky_lifetime_min: float = 3.0
@export var sticky_lifetime_max: float = 7.0
@export var sticky_fade_duration: float = 0.5

@export var gradient_texture: GradientTexture1D = preload("res://assets/arc_gradient.tres")
@export var sticky_gradient_texture: GradientTexture1D = preload("res://assets/sticky_arc_gradient.tres")

@onready var player_area: Area2D = $"../Player/Area2D"

@onready var score_label: Label = $Score
@onready var high_score_label: Label = $"../../Game_Over/Control/Hi_Score"


const SCORE_RADIUS: float = 450.0
const MAX_HAZARDS: int = 64

class NeonArcData:
	var radius: float = 0.0
	var speed: float = 0.0
	var start_angle: float = 0.0
	var end_angle: float = 0.0
	var thickness: float = 22.0
	var active: bool = false
	var has_scored: bool = false
	var is_sticky: bool = false
	var is_anchored: bool = false
	var life_time: float = 0.0

var hazards: Array[NeonArcData] = []
var spawn_timer: float = 0.0
var score: int = 0

func _ready() -> void:
	randomize()

	for i: int in range(MAX_HAZARDS):
		hazards.append(NeonArcData.new())
	load_high_score()
	update_score_label()

func _process(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_width: float = viewport_size.x

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_arc()
		spawn_timer = 0.0

	for arc in hazards:
		if not arc.active:
			continue

		if arc.is_anchored:
			arc.life_time -= delta
			if arc.life_time <= 0.0:
				arc.active = false
				continue
		else:
			arc.radius += arc.speed * delta

			if arc.is_sticky and (arc.radius + (arc.thickness * 0.5)) >= SCORE_RADIUS:
				arc.radius = SCORE_RADIUS - (arc.thickness * 0.5)
				arc.is_anchored = true
				if not arc.has_scored:
					score += 2
					arc.has_scored = true
					update_score_label()

		if not arc.is_sticky and arc.radius >= SCORE_RADIUS and not arc.has_scored:
			score += 1
			arc.has_scored = true
			update_score_label()

		if not arc.is_sticky and arc.radius * 2.0 > screen_width:
			arc.active = false

	# Check player collision against all arcs
	if player_area != null and check_player_collision(player_area.global_position):
		on_player_hit()
		
	queue_redraw()

func check_player_collision(pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(pos)
	var distance: float = local_pos.length()
	var angle_deg: float = fposmod(rad_to_deg(local_pos.angle()), 360.0)

	for arc in hazards:
		if not arc.active:
			continue

		var inner_r: float = arc.radius
		var outer_r: float = arc.radius + arc.thickness

		if distance >= inner_r and distance <= outer_r:
			var start_deg: float = fposmod(arc.start_angle, 360.0)
			var end_deg: float = fposmod(arc.end_angle, 360.0)
			var sweep: float = fposmod(end_deg - start_deg, 360.0)
			if sweep == 0.0 and start_deg != end_deg:
				sweep = 360.0
			
			if fposmod(angle_deg - start_deg, 360.0) <= sweep:
				return true
	return false

func on_player_hit() -> void:
	# 1. Update and persist high score immediately on death
	if score > high_score:
		high_score = score
		save_high_score()

	# 2. Pause game physics and rendering timer
	Engine.time_scale = 1.0
	get_tree().paused = true

	# 3. Show Game Over panel and update final score displays
	var game_over_node = $"../../Game_Over"
	if game_over_node:
		game_over_node.visible = true

	update_score_label()

func has_active_sticky_arc() -> bool:
	for arc in hazards:
		if arc.active and arc.is_sticky:
			return true
	return false

func spawn_arc() -> void:
	for arc in hazards:
		if not arc.active:
			arc.radius = 0.0
			arc.speed = randf_range(speed_min, speed_max)
			
			var start_deg: float = randf_range(0.0, 360.0)
			var arc_size_deg: float = randf_range(min_arc_angle, max_arc_angle)
			
			arc.start_angle = start_deg
			arc.end_angle = start_deg + arc_size_deg
			arc.thickness = base_thickness
			arc.active = true
			arc.has_scored = false
			arc.is_anchored = false
			
			if not has_active_sticky_arc() and randi_range(1, 100) <= sticky_spawn_chance:
				arc.is_sticky = true
				arc.life_time = randf_range(sticky_lifetime_min, sticky_lifetime_max)
			else:
				arc.is_sticky = false
				arc.life_time = 0.0
			break

func update_score_label() -> void:
	if score > high_score:
		high_score = score
		save_high_score()

	if score_label:
		score_label.text = str(score)
		
	if high_score_label:
		high_score_label.text = "High Score: " + str(high_score)
		
	Engine.time_scale = minf(1.0 + (float(score) / 100.0), 2)

func _draw() -> void:
	for arc in hazards:
		if not arc.active:
			continue

		var tex: GradientTexture1D = sticky_gradient_texture if (arc.is_sticky and sticky_gradient_texture != null) else gradient_texture
		
		var alpha: float = 1.0
		if arc.is_sticky and arc.is_anchored:
			alpha = clamp(arc.life_time / sticky_fade_duration, 0.0, 1.0)

		draw_ring_sector(
			Vector2.ZERO,
			arc.radius,
			arc.radius + arc.thickness,
			arc.start_angle,
			arc.end_angle,
			tex,
			alpha
		)

func draw_ring_sector(center: Vector2, inner_r: float, outer_r: float, start_deg: float, end_deg: float, tex_1d: GradientTexture1D, alpha_mod: float) -> void:
	var start_rad: float = deg_to_rad(start_deg)
	var end_rad: float = deg_to_rad(end_deg)
	var angle_span: float = end_rad - start_rad
	
	var angular_steps: int = max(4, int(arc_segments * (angle_span / TAU)))
	var rad_steps: int = max(1, radial_segments)
	
	var grad: Gradient = tex_1d.gradient if tex_1d != null else null

	for r_step in range(rad_steps):
		var r_t0: float = float(r_step) / float(rad_steps)
		var r_t1: float = float(r_step + 1) / float(rad_steps)
		
		var r_inner: float = lerp(inner_r, outer_r, r_t0)
		var r_outer: float = lerp(inner_r, outer_r, r_t1)

		var col_inner: Color = grad.sample(r_t0) if grad != null else Color.WHITE
		var col_outer: Color = grad.sample(r_t1) if grad != null else Color.WHITE
		
		col_inner.a *= alpha_mod
		col_outer.a *= alpha_mod

		for a_step in range(angular_steps):
			var a_t0: float = float(a_step) / float(angular_steps)
			var a_t1: float = float(a_step + 1) / float(angular_steps)
			
			var angle0: float = start_rad + a_t0 * angle_span
			var angle1: float = start_rad + a_t1 * angle_span

			var dir0: Vector2 = Vector2(cos(angle0), sin(angle0))
			var dir1: Vector2 = Vector2(cos(angle1), sin(angle1))

			var quad_points := PackedVector2Array([
				center + dir0 * r_inner,
				center + dir1 * r_inner,
				center + dir1 * r_outer,
				center + dir0 * r_outer
			])

			var quad_colors := PackedColorArray([
				col_inner,
				col_inner,
				col_outer,
				col_outer
			])

			draw_polygon(quad_points, quad_colors)

#SAVING
const SAVE_FILE_PATH: String = "user://highscore.cfg"
var high_score: int = 0

func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("Game", "high_score", high_score)
	config.save(SAVE_FILE_PATH)

func load_high_score() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_FILE_PATH)
	
	if error == OK:
		high_score = config.get_value("Game", "high_score", 0)
	else:
		high_score = 0
