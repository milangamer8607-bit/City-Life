extends Node3D

var player: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D
var hud: Label
var money := 2500
var wanted := 0
var in_car := false
var job_cooldown := 0.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_car()
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	environment.sky.sky_material = sky_mat
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.68, 0.78)
	environment.ambient_light_energy = 0.8
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.2
	add_child(sun)
	_make_box("Ground", Vector3(0,-0.5,0), Vector3(220,1,220), Color(0.22,0.27,0.24), true)
	# A broad crossroad and city blocks built from simple meshes (no external assets).
	_make_box("Main road", Vector3(0,0.02,0), Vector3(18,0.08,210), Color(0.12,0.13,0.15), false)
	_make_box("Cross road", Vector3(0,0.03,0), Vector3(210,0.08,18), Color(0.12,0.13,0.15), false)
	for i in range(-4,5):
		for j in range(-4,5):
			if abs(i) <= 1 or abs(j) <= 1:
				continue
			var x := float(i)*35.0
			var z := float(j)*35.0
			var height := randf_range(8.0, 28.0)
			var color := Color(randf_range(0.28,0.52), randf_range(0.30,0.50), randf_range(0.34,0.56))
			_make_box("Building", Vector3(x,height/2,z), Vector3(randf_range(12,20),height,randf_range(12,20)), color, true)
	# Road markings
	for k in range(-9,10):
		_make_box("Lane marking", Vector3(0,0.09,float(k)*10), Vector3(0.25,0.03,4), Color(0.9,0.83,0.52), false)
		_make_box("Lane marking", Vector3(float(k)*10,0.09,0), Vector3(4,0.03,0.25), Color(0.9,0.83,0.52), false)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var root: Node3D
	if collision:
		root = StaticBody3D.new()
	else:
		root = Node3D.new()
	root.name = label
	root.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	mesh.material_override = mat
	root.add_child(mesh)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		root.add_child(shape_node)
	add_child(root)
	return root

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(3,1,3)
	var body := _visual_box(Vector3(0,0.85,0), Vector3(0.7,1.7,0.45), Color(0.12,0.36,0.85))
	player.add_child(body)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	col.shape = shape
	col.position.y = 0.85
	player.add_child(col)
	add_child(player)
	camera = Camera3D.new()
	camera.position = Vector3(0,4.5,7.5)
	camera.rotation_degrees = Vector3(-24,0,0)
	camera.current = true
	player.add_child(camera)

func _build_car() -> void:
	car = CharacterBody3D.new()
	car.name = "Car"
	car.position = Vector3(0,0.65,8)
	var chassis := _visual_box(Vector3(0,0.35,0), Vector3(2.0,0.65,4.0), Color(0.78,0.12,0.09))
	car.add_child(chassis)
	var cabin := _visual_box(Vector3(0,0.9,-0.25), Vector3(1.45,0.65,1.8), Color(0.15,0.23,0.3))
	car.add_child(cabin)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2,1.3,4)
	col.shape = shape
	col.position.y = 0.5
	car.add_child(col)
	add_child(car)

func _visual_box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mesh.material_override = mat
	return mesh

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(22,18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(hud)
	var help := Label.new()
	help.text = "WASD: Bewegen/Fahren   E: Job oder Auto nutzen   F: Aussteigen   ESC: Maus freigeben"
	help.position = Vector2(22,660)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)
	_update_hud("Willkommen in City Life")

func _update_hud(message: String = "") -> void:
	var stars := "★".repeat(wanted) + "☆".repeat(5-wanted)
	hud.text = "CITY LIFE  |  $ %s  |  Fahndung: %s\n%s" % [str(money), stars, message]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if not in_car:
			player.rotate_y(-event.relative.x * 0.003)
			camera.rotate_x(-event.relative.y * 0.002)
			camera.rotation.x = clamp(camera.rotation.x, -1.0, 0.25)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	job_cooldown = maxf(0.0, job_cooldown-delta)
	if in_car:
		_drive_car(delta)
	else:
		_walk_player(delta)
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("exit_vehicle") and in_car:
		_exit_car()

func _walk_player(delta: float) -> void:
	var input := Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction := (player.global_transform.basis * Vector3(input.x,0,input.y)).normalized()
	if direction:
		player.velocity.x = direction.x * 5.5
		player.velocity.z = direction.z * 5.5
	else:
		player.velocity.x = move_toward(player.velocity.x,0,18*delta)
		player.velocity.z = move_toward(player.velocity.z,0,18*delta)
	player.velocity.y -= 22.0*delta
	player.move_and_slide()
	camera.global_position = player.global_position + player.global_transform.basis * Vector3(0,4.4,7.2)
	camera.look_at(player.global_position + Vector3(0,1,0), Vector3.UP)

func _drive_car(delta: float) -> void:
	var throttle := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var steer := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	car.rotate_y(-steer * delta * 1.25 * clampf(absf(throttle)+0.25,0.25,1.0))
	var forward := -car.global_transform.basis.z
	car.velocity.x = forward.x * throttle * 17.0
	car.velocity.z = forward.z * throttle * 17.0
	car.velocity.y = 0
	car.move_and_slide()
	camera.global_position = car.global_position + car.global_transform.basis * Vector3(0,5.0,9.0)
	camera.look_at(car.global_position + Vector3(0,1,0), Vector3.UP)

func _interact() -> void:
	if job_cooldown > 0:
		return
	if not in_car and player.global_position.distance_to(car.global_position) < 4.0:
		in_car = true
		player.visible = false
		player.set_physics_process(false)
		_update_hud("Auto übernommen! F zum Aussteigen")
		return
	money += 350
	job_cooldown = 4.0
	_update_hud("Lieferauftrag erledigt: +$350")

func _exit_car() -> void:
	in_car = false
	player.visible = true
	player.set_physics_process(true)
	player.global_position = car.global_position + car.global_transform.basis * Vector3(2.2,0,0)
	player.velocity = Vector3.ZERO
	_update_hud("Du bist ausgestiegen. E: Job starten")
