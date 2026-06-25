extends Node2D

# Pinguins x Focas — protótipo 2D original.
# Mecânicas prontas:
# - Pinguim sobe/desce preso por cordas na catapulta.
# - Toque para lançar no timing desejado.
# - Toque durante o voo para mergulhar.
# - Focas recebem dano por impacto.
# - Blocos de gelo quebram.
# - Sistema simples de vitória/derrota e estrelas.

enum GameState { AIMING, FLYING, LEVEL_CLEAR, LEVEL_FAIL }

const VIEW_W := 1280.0
const VIEW_H := 720.0
const LEVEL_W := 2450.0
const GROUND_Y := 625.0
const CATAPULT_POS := Vector2(190.0, 520.0)
const PENGUIN_RADIUS := 28.0
const GRAVITY := 980.0
const MAX_BOUNCES := 3

var state: int = GameState.AIMING
var rng := RandomNumberGenerator.new()

var camera_x := 0.0
var aim_time := 0.0
var aim_y := 430.0
var aim_min_y := 345.0
var aim_max_y := 520.0
var aim_speed := 2.35

var penguins_left := 3
var launched_penguins := 0
var bounces_left := MAX_BOUNCES
var has_dived := false
var projectile_pos := CATAPULT_POS
var projectile_vel := Vector2.ZERO
var projectile_spin := 0.0
var score := 0

var seals: Array = []
var blocks: Array = []
var stars_earned := 0
var message_timer := 0.0
var floating_messages: Array = []

var ui_restart_rect := Rect2(520, 475, 240, 64)
var ui_next_rect := Rect2(520, 545, 240, 64)

func _ready() -> void:
	rng.randomize()
	reset_level()
	set_process(true)
	set_physics_process(true)

func reset_level() -> void:
	state = GameState.AIMING
	camera_x = 0.0
	aim_time = 0.0
	penguins_left = 3
	launched_penguins = 0
	bounces_left = MAX_BOUNCES
	has_dived = false
	projectile_pos = CATAPULT_POS
	projectile_vel = Vector2.ZERO
	projectile_spin = 0.0
	score = 0
	stars_earned = 0
	floating_messages.clear()
	_build_level()
	queue_redraw()

func _build_level() -> void:
	seals = [
		{"pos": Vector2(1050, 575), "hp": 90.0, "max_hp": 90.0, "alive": true, "radius": 34.0},
		{"pos": Vector2(1280, 575), "hp": 110.0, "max_hp": 110.0, "alive": true, "radius": 36.0},
		{"pos": Vector2(1510, 502), "hp": 125.0, "max_hp": 125.0, "alive": true, "radius": 38.0},
		{"pos": Vector2(1765, 575), "hp": 145.0, "max_hp": 145.0, "alive": true, "radius": 40.0}
	]
	blocks = [
		{"rect": Rect2(1425, 555, 170, 38), "hp": 80.0, "max_hp": 80.0, "alive": true},
		{"rect": Rect2(1450, 515, 38, 78), "hp": 65.0, "max_hp": 65.0, "alive": true},
		{"rect": Rect2(1534, 515, 38, 78), "hp": 65.0, "max_hp": 65.0, "alive": true},
		{"rect": Rect2(1630, 565, 190, 32), "hp": 90.0, "max_hp": 90.0, "alive": true},
		{"rect": Rect2(1870, 555, 120, 38), "hp": 85.0, "max_hp": 85.0, "alive": true},
	]

func _process(delta: float) -> void:
	if state == GameState.AIMING:
		aim_time += delta
		var wave := (sin(aim_time * aim_speed) + 1.0) * 0.5
		aim_y = lerp(aim_min_y, aim_max_y, wave)
		projectile_pos = Vector2(CATAPULT_POS.x, aim_y)
	elif state == GameState.FLYING:
		var target_camera := clamp(projectile_pos.x - 390.0, 0.0, LEVEL_W - VIEW_W)
		camera_x = lerp(camera_x, target_camera, clamp(delta * 5.0, 0.0, 1.0))

	_update_floating_messages(delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if state != GameState.FLYING:
		return

	projectile_vel.y += GRAVITY * delta
	projectile_pos += projectile_vel * delta
	projectile_spin += projectile_vel.length() * delta * 0.015

	_check_block_collisions()
	_check_seal_collisions()
	_check_ground_collision()
	_check_out_of_bounds()

	if _alive_seals_count() == 0:
		finish_level(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap(event.position)

func _handle_tap(screen_pos: Vector2) -> void:
	match state:
		GameState.AIMING:
			launch_penguin()
		GameState.FLYING:
			dive_penguin()
		GameState.LEVEL_CLEAR, GameState.LEVEL_FAIL:
			if ui_restart_rect.has_point(screen_pos):
				reset_level()
			elif ui_next_rect.has_point(screen_pos):
				reset_level()

func launch_penguin() -> void:
	if penguins_left <= 0:
		finish_level(false)
		return

	state = GameState.FLYING
	launched_penguins += 1
	bounces_left = MAX_BOUNCES
	has_dived = false

	# Timing: quanto mais alto estiver o pinguim na corda, mais alto o arco.
	var height_factor := 1.0 - inverse_lerp(aim_min_y, aim_max_y, aim_y)
	var force_x := 780.0 + height_factor * 135.0
	var force_y := -650.0 - height_factor * 250.0
	projectile_vel = Vector2(force_x, force_y)
	_add_float_text("LANÇADO!", CATAPULT_POS + Vector2(20, -150), Color(1.0, 0.9, 0.35))

func dive_penguin() -> void:
	if has_dived:
		return
	has_dived = true
	projectile_vel.x *= 0.92
	projectile_vel.y = max(projectile_vel.y, 80.0) + 820.0
	_add_float_text("MERGULHO!", projectile_pos + Vector2(0, -65), Color(0.76, 0.58, 1.0))

func _check_ground_collision() -> void:
	if projectile_pos.y + PENGUIN_RADIUS < GROUND_Y:
		return

	projectile_pos.y = GROUND_Y - PENGUIN_RADIUS
	var impact := projectile_vel.length()
	if bounces_left > 0 and impact > 260.0:
		bounces_left -= 1
		projectile_vel.y = -abs(projectile_vel.y) * 0.48
		projectile_vel.x *= 0.72
		_add_float_text("QUIQUE %d" % bounces_left, projectile_pos + Vector2(0, -60), Color(0.8, 0.95, 1.0))
	else:
		end_current_penguin()

func _check_out_of_bounds() -> void:
	if projectile_pos.x > LEVEL_W + 200.0 or projectile_pos.y > VIEW_H + 250.0:
		end_current_penguin()

func _check_seal_collisions() -> void:
	for seal in seals:
		if not seal.alive:
			continue
		var dist := projectile_pos.distance_to(seal.pos)
		var combined := PENGUIN_RADIUS + float(seal.radius)
		if dist <= combined:
			var impact := projectile_vel.length()
			var damage := impact * 0.16 + (70.0 if has_dived else 0.0)
			seal.hp -= damage
			score += int(damage)
			var normal := (projectile_pos - seal.pos).normalized()
			if normal == Vector2.ZERO:
				normal = Vector2.UP
			projectile_pos = seal.pos + normal * combined
			projectile_vel = projectile_vel.bounce(normal) * 0.52
			bounces_left = max(0, bounces_left - 1)
			if seal.hp <= 0.0:
				seal.alive = false
				score += 400
				_add_float_text("FOCA DERRUBADA!", seal.pos + Vector2(0, -72), Color(1.0, 0.7, 0.9))
			else:
				_add_float_text("-%d" % int(damage), seal.pos + Vector2(0, -62), Color(1.0, 0.85, 0.5))

func _check_block_collisions() -> void:
	for block in blocks:
		if not block.alive:
			continue
		var rect: Rect2 = block.rect
		var closest := Vector2(
			clamp(projectile_pos.x, rect.position.x, rect.position.x + rect.size.x),
			clamp(projectile_pos.y, rect.position.y, rect.position.y + rect.size.y)
		)
		if projectile_pos.distance_to(closest) <= PENGUIN_RADIUS:
			var impact := projectile_vel.length()
			var damage := impact * (0.10 + (0.05 if has_dived else 0.0))
			block.hp -= damage
			score += int(damage * 0.6)
			var normal := (projectile_pos - closest).normalized()
			if normal == Vector2.ZERO:
				normal = Vector2.UP
			projectile_pos = closest + normal * (PENGUIN_RADIUS + 1.0)
			projectile_vel = projectile_vel.bounce(normal) * 0.55
			bounces_left = max(0, bounces_left - 1)
			if block.hp <= 0.0:
				block.alive = false
				score += 120
				_add_float_text("GELO QUEBRADO", rect.position + rect.size * 0.5 + Vector2(0, -50), Color(0.65, 0.95, 1.0))

func end_current_penguin() -> void:
	if state != GameState.FLYING:
		return

	penguins_left -= 1
	if _alive_seals_count() == 0:
		finish_level(true)
	elif penguins_left <= 0:
		finish_level(false)
	else:
		state = GameState.AIMING
		camera_x = lerp(camera_x, 0.0, 0.45)
		projectile_pos = CATAPULT_POS
		projectile_vel = Vector2.ZERO
		has_dived = false
		bounces_left = MAX_BOUNCES

func finish_level(won: bool) -> void:
	if won:
		state = GameState.LEVEL_CLEAR
		if launched_penguins <= 1:
			stars_earned = 3
		elif launched_penguins <= 2:
			stars_earned = 2
		else:
			stars_earned = 1
	else:
		state = GameState.LEVEL_FAIL
		stars_earned = 0

func _alive_seals_count() -> int:
	var total := 0
	for seal in seals:
		if seal.alive:
			total += 1
	return total

func _add_float_text(text: String, world_pos: Vector2, color: Color) -> void:
	floating_messages.append({"text": text, "pos": world_pos, "life": 1.25, "color": color})

func _update_floating_messages(delta: float) -> void:
	for msg in floating_messages:
		msg.life -= delta
		msg.pos.y -= 35.0 * delta
	floating_messages = floating_messages.filter(func(m): return m.life > 0.0)

func _draw() -> void:
	_draw_screen_background()
	draw_set_transform(Vector2(-camera_x, 0), 0.0, Vector2.ONE)
	_draw_world()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_ui()

func _draw_screen_background() -> void:
	for i in range(18):
		var t := float(i) / 17.0
		var c := Color(0.07 + t * 0.04, 0.04 + t * 0.10, 0.18 + t * 0.22)
		draw_rect(Rect2(0, i * VIEW_H / 18.0, VIEW_W, VIEW_H / 18.0 + 1.0), c)

func _draw_world() -> void:
	# Lua e montanhas geladas.
	draw_circle(Vector2(1040, 105), 52, Color(0.95, 0.92, 1.0, 0.82))
	_draw_mountain(Vector2(520, GROUND_Y), 330, 245, Color(0.20, 0.16, 0.35))
	_draw_mountain(Vector2(980, GROUND_Y), 420, 320, Color(0.18, 0.13, 0.32))
	_draw_mountain(Vector2(1730, GROUND_Y), 510, 285, Color(0.16, 0.11, 0.30))

	# Chão.
	draw_rect(Rect2(-100, GROUND_Y, LEVEL_W + 300, 180), Color(0.90, 0.96, 1.0))
	draw_line(Vector2(-100, GROUND_Y), Vector2(LEVEL_W + 300, GROUND_Y), Color(0.72, 0.88, 1.0), 4)

	_draw_catapult()
	for block in blocks:
		if block.alive:
			_draw_ice_block(block)
	for seal in seals:
		if seal.alive:
			_draw_seal(seal)
	if state == GameState.FLYING or state == GameState.AIMING:
		_draw_penguin(projectile_pos, projectile_spin, has_dived)
	_draw_float_texts()

func _draw_mountain(base: Vector2, width: float, height: float, color: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(base.x - width * 0.5, base.y),
		Vector2(base.x, base.y - height),
		Vector2(base.x + width * 0.5, base.y)
	])
	draw_colored_polygon(pts, color)
	var snow := PackedVector2Array([
		Vector2(base.x - width * 0.13, base.y - height * 0.70),
		Vector2(base.x, base.y - height),
		Vector2(base.x + width * 0.16, base.y - height * 0.66),
		Vector2(base.x + width * 0.03, base.y - height * 0.76)
	])
	draw_colored_polygon(snow, Color(0.88, 0.94, 1.0, 0.92))

func _draw_catapult() -> void:
	var wood := Color(0.44, 0.24, 0.12)
	var dark_wood := Color(0.25, 0.13, 0.08)
	var rope := Color(0.95, 0.78, 0.45)
	var left_anchor := CATAPULT_POS + Vector2(-42, -85)
	var right_anchor := CATAPULT_POS + Vector2(44, -85)

	draw_line(CATAPULT_POS + Vector2(-70, 100), left_anchor, dark_wood, 18)
	draw_line(CATAPULT_POS + Vector2(70, 100), right_anchor, dark_wood, 18)
	draw_line(CATAPULT_POS + Vector2(-78, 102), CATAPULT_POS + Vector2(78, 102), wood, 24)
	draw_line(CATAPULT_POS + Vector2(-40, 58), CATAPULT_POS + Vector2(42, 58), wood, 14)

	if state == GameState.AIMING:
		draw_line(left_anchor, projectile_pos, rope, 4)
		draw_line(right_anchor, projectile_pos, rope, 4)
		draw_circle(left_anchor, 9, rope)
		draw_circle(right_anchor, 9, rope)

func _draw_penguin(pos: Vector2, spin: float, diving: bool) -> void:
	var body := Color(0.05, 0.07, 0.11)
	var belly := Color(0.95, 0.98, 1.0)
	var beak := Color(1.0, 0.66, 0.10)
	var accent := Color(0.52, 0.32, 1.0)

	draw_circle(pos, 31, body)
	draw_circle(pos + Vector2(0, 10), 22, belly)
	draw_circle(pos + Vector2(-11, -9), 4.5, Color.WHITE)
	draw_circle(pos + Vector2(11, -9), 4.5, Color.WHITE)
	draw_circle(pos + Vector2(-11, -9), 2.0, Color.BLACK)
	draw_circle(pos + Vector2(11, -9), 2.0, Color.BLACK)
	var beak_pts := PackedVector2Array([pos + Vector2(-9, 0), pos + Vector2(9, 0), pos + Vector2(0, 12)])
	draw_colored_polygon(beak_pts, beak)
	var wing_offset := 21.0 if not diving else 27.0
	draw_line(pos + Vector2(-20, 8), pos + Vector2(-wing_offset, 29), accent, 7)
	draw_line(pos + Vector2(20, 8), pos + Vector2(wing_offset, 29), accent, 7)
	# Pequeno traço de velocidade no mergulho.
	if diving:
		draw_line(pos + Vector2(-42, -38), pos + Vector2(-16, -18), Color(0.82, 0.72, 1.0, 0.75), 5)
		draw_line(pos + Vector2(42, -38), pos + Vector2(16, -18), Color(0.82, 0.72, 1.0, 0.75), 5)

func _draw_seal(seal: Dictionary) -> void:
	var pos: Vector2 = seal.pos
	var hp_ratio := clamp(float(seal.hp) / float(seal.max_hp), 0.0, 1.0)
	var body := Color(0.52, 0.58, 0.68)
	var belly := Color(0.80, 0.87, 0.94)
	var dark := Color(0.11, 0.12, 0.16)
	draw_circle(pos, float(seal.radius), body)
	draw_circle(pos + Vector2(0, 12), float(seal.radius) * 0.62, belly)
	draw_circle(pos + Vector2(-13, -9), 4.5, Color.WHITE)
	draw_circle(pos + Vector2(13, -9), 4.5, Color.WHITE)
	draw_circle(pos + Vector2(-13, -9), 2.2, dark)
	draw_circle(pos + Vector2(13, -9), 2.2, dark)
	draw_circle(pos + Vector2(0, 3), 4.0, dark)
	draw_line(pos + Vector2(-28, 18), pos + Vector2(-48, 30), body, 9)
	draw_line(pos + Vector2(28, 18), pos + Vector2(48, 30), body, 9)
	# Barra de vida.
	var bar := Rect2(pos.x - 42, pos.y - float(seal.radius) - 22, 84, 8)
	draw_rect(bar, Color(0, 0, 0, 0.35))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), Color(0.65, 0.45, 1.0))

func _draw_ice_block(block: Dictionary) -> void:
	var rect: Rect2 = block.rect
	var hp_ratio := clamp(float(block.hp) / float(block.max_hp), 0.0, 1.0)
	var base := Color(0.64, 0.88, 1.0)
	var damaged := Color(0.45, 0.58, 0.72)
	var c := damaged.lerp(base, hp_ratio)
	draw_rect(rect, c)
	draw_rect(rect, Color(0.95, 1.0, 1.0, 0.45), false, 3)
	draw_line(rect.position + Vector2(12, 10), rect.position + rect.size - Vector2(18, 12), Color(1, 1, 1, 0.45), 2)
	draw_line(rect.position + Vector2(rect.size.x - 16, 8), rect.position + Vector2(18, rect.size.y - 10), Color(0.26, 0.50, 0.72, 0.32), 2)

func _draw_float_texts() -> void:
	var font := ThemeDB.fallback_font
	for msg in floating_messages:
		var alpha := clamp(float(msg.life), 0.0, 1.0)
		var color: Color = msg.color
		color.a = alpha
		draw_string(font, msg.pos, msg.text, HORIZONTAL_ALIGNMENT_CENTER, 220, 24, color)

func _draw_ui() -> void:
	var font := ThemeDB.fallback_font
	var panel := Color(0.04, 0.03, 0.08, 0.55)
	var purple := Color(0.48, 0.28, 1.0)
	var text := Color(0.94, 0.91, 1.0)
	draw_rect(Rect2(22, 18, 382, 96), panel, true, -1.0)
	draw_string(font, Vector2(42, 52), "Pinguins x Focas", HORIZONTAL_ALIGNMENT_LEFT, 360, 30, Color(1, 1, 1))
	draw_string(font, Vector2(42, 88), "Pinguins: %d  |  Focas: %d  |  Pontos: %d" % [penguins_left, _alive_seals_count(), score], HORIZONTAL_ALIGNMENT_LEFT, 360, 22, text)

	if state == GameState.AIMING:
		draw_string(font, Vector2(430, 52), "Toque quando o pinguim estiver na melhor altura da corda.", HORIZONTAL_ALIGNMENT_LEFT, 780, 25, text)
		draw_string(font, Vector2(430, 86), "Depois do lançamento, toque novamente para mergulhar.", HORIZONTAL_ALIGNMENT_LEFT, 780, 22, Color(0.78, 0.70, 1.0))
	elif state == GameState.FLYING:
		draw_string(font, Vector2(430, 58), "Toque para mergulhar!  Quiques restantes: %d" % bounces_left, HORIZONTAL_ALIGNMENT_LEFT, 680, 28, Color(1.0, 0.9, 0.42))

	if state == GameState.LEVEL_CLEAR or state == GameState.LEVEL_FAIL:
		_draw_result_panel(font, purple, text)

func _draw_result_panel(font: Font, purple: Color, text: Color) -> void:
	var title := "FASE CONCLUÍDA!" if state == GameState.LEVEL_CLEAR else "TENTE NOVAMENTE"
	var subtitle := "Você derrubou todas as focas." if state == GameState.LEVEL_CLEAR else "Os pinguins acabaram antes de derrubar todas as focas."
	draw_rect(Rect2(360, 165, 560, 420), Color(0.04, 0.03, 0.09, 0.92), true, -1.0)
	draw_rect(Rect2(360, 165, 560, 420), Color(0.62, 0.42, 1.0, 0.85), false, 4)
	draw_string(font, Vector2(390, 225), title, HORIZONTAL_ALIGNMENT_CENTER, 500, 42, Color.WHITE)
	draw_string(font, Vector2(390, 270), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 500, 24, text)

	var star_y := 337.0
	for i in range(3):
		var filled := i < stars_earned
		var c := Color(1.0, 0.78, 0.14) if filled else Color(0.28, 0.24, 0.34)
		_draw_star(Vector2(570 + i * 70, star_y), 28, c)

	draw_string(font, Vector2(430, 405), "Pontuação: %d" % score, HORIZONTAL_ALIGNMENT_CENTER, 420, 26, text)
	_draw_button(ui_restart_rect, "REINICIAR", purple, font)
	_draw_button(ui_next_rect, "JOGAR DE NOVO", Color(0.30, 0.20, 0.62), font)

func _draw_button(rect: Rect2, label: String, color: Color, font: Font) -> void:
	draw_rect(rect, color, true, -1.0)
	draw_rect(rect, Color(1, 1, 1, 0.30), false, 2)
	draw_string(font, rect.position + Vector2(0, 40), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 24, Color.WHITE)

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + float(i) * PI / 5.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)
