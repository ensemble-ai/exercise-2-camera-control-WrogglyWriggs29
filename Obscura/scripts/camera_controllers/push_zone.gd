class_name PushZone
extends CameraControllerBase

enum DIRECTION {UP, DOWN, LEFT, RIGHT}

@export var push_ratio: float
@export var pushbox_top_left: Vector2
@export var pushbox_bottom_right: Vector2
@export var speedup_zone_top_left: Vector2
@export var speedup_zone_bottom_right: Vector2

var sped_up_in = [false, false, false, false]

func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	const WALL_DIST = 0.5
	var r = target.RADIUS
	var tpos := target.global_position
	var cpos := global_position
	var left_lim = cpos.x + pushbox_top_left.x
	var right_lim = cpos.x + pushbox_bottom_right.x
	var top_lim = cpos.z + pushbox_top_left.y
	var bottom_lim = cpos.z + pushbox_bottom_right.y

	var left_speed = cpos.x + speedup_zone_top_left.x + r
	var right_speed = cpos.x + speedup_zone_bottom_right.x - r
	var top_speed = cpos.z + speedup_zone_top_left.y + r
	var bottom_speed = cpos.z + speedup_zone_bottom_right.y - r

	sped_up_in = [false, false, false, false]

	if tpos.x > right_speed:
		if tpos.x >= right_lim - WALL_DIST:
			speedup_in(DIRECTION.UP, delta)
			speedup_in(DIRECTION.DOWN, delta)
		if tpos.x > right_lim:
			var offset = tpos.x - (cpos.x + pushbox_bottom_right.x)
			global_position.x += r + offset
		else:
			speedup_in(DIRECTION.RIGHT, delta)
	elif tpos.x < left_speed:
		if tpos.x <= left_lim + WALL_DIST:
			speedup_in(DIRECTION.UP, delta)
			speedup_in(DIRECTION.DOWN, delta)
		if tpos.x < left_lim:
			var offset = (cpos.x + pushbox_top_left.x) - tpos.x
			global_position.x -= r + offset
		else:
			speedup_in(DIRECTION.LEFT, delta)

	if tpos.z < top_speed:
		if tpos.z <= top_lim + WALL_DIST:
			speedup_in(DIRECTION.LEFT, delta)
			speedup_in(DIRECTION.RIGHT, delta)
		if tpos.z < top_lim:
			var offset = (cpos.z + pushbox_top_left.y) - tpos.z
			global_position.z -= r + offset
		else:
			speedup_in(DIRECTION.UP, delta)
	elif tpos.z > bottom_speed:
		if tpos.z >= bottom_lim - WALL_DIST:
			speedup_in(DIRECTION.LEFT, delta)
			speedup_in(DIRECTION.RIGHT, delta)
		if tpos.z > bottom_lim:
			var offset = tpos.z - (cpos.z + pushbox_bottom_right.y)
			global_position.z += r + offset
		else:
			speedup_in(DIRECTION.DOWN, delta)


	super(delta)

func speedup_in(direction: DIRECTION, delta: float) -> void:
	if sped_up_in[direction]:
		return
	var vel = Vector3.ZERO
	match direction:
		DIRECTION.UP:
			vel = Vector3(0, 0, min(target.velocity.z, 0) * push_ratio)
		DIRECTION.DOWN:
			vel = Vector3(0, 0, max(target.velocity.z, 0) * push_ratio)
		DIRECTION.LEFT:
			vel = Vector3(min(target.velocity.x, 0) * push_ratio, 0, 0)
		DIRECTION.RIGHT:
			vel = Vector3(max(target.velocity.x, 0) * push_ratio, 0, 0)
	if vel != Vector3.ZERO:
		sped_up_in[direction] = true
	global_position += vel * delta

func sum(v: Vector3) -> float:
	return v.x + v.y + v.z

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	add_box(immediate_mesh, pushbox_top_left, pushbox_bottom_right)
	add_box(immediate_mesh, speedup_zone_top_left, speedup_zone_bottom_right)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()

func add_box(mesh, top_left: Vector2, bottom_right: Vector2) -> void:
	var top_left_vert := Vector3(top_left.x, 0, top_left.y)
	var top_right_vert := Vector3(bottom_right.x, 0, top_left.y)
	var bottom_left_vert := Vector3(top_left.x, 0, bottom_right.y)
	var bottom_right_vert := Vector3(bottom_right.x, 0, bottom_right.y)
	
	mesh.surface_add_vertex(top_left_vert)
	mesh.surface_add_vertex(top_right_vert)
	
	mesh.surface_add_vertex(top_right_vert)
	mesh.surface_add_vertex(bottom_right_vert)
	
	mesh.surface_add_vertex(bottom_right_vert)
	mesh.surface_add_vertex(bottom_left_vert)
	
	mesh.surface_add_vertex(bottom_left_vert)
	mesh.surface_add_vertex(top_left_vert)
