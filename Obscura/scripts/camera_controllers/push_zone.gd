class_name PushZone
extends CameraControllerBase

enum DIRECTION {UP, DOWN, LEFT, RIGHT}

@export var push_ratio: float
@export var pushbox_top_left: Vector2
@export var pushbox_bottom_right: Vector2
@export var speedup_zone_top_left: Vector2
@export var speedup_zone_bottom_right: Vector2

func _ready() -> void:
	super()
	position = target.position
	
func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	# detect the directions in which the target is pushing
	var push_dirs: Array[bool] = detect_pushing(global_position, target.global_position, target.RADIUS)
	apply_push(push_dirs, delta)

	# apply the pushbox (snap camera s.t. target is within it)
	apply_box(target.global_position, global_position, target.RADIUS)

	super(delta)

func apply_box(tpos: Vector3, cpos: Vector3, r: float) -> void:
	# need to recalculate the limits in case the player pushed the camera
	var limits := get_limits(cpos, r)

	# snap the camera in each direction
	if tpos.z < limits[DIRECTION.UP]:
		global_position.z += tpos.z - limits[DIRECTION.UP]
	elif tpos.z > limits[DIRECTION.DOWN]:
		global_position.z += tpos.z - limits[DIRECTION.DOWN]

	if tpos.x < limits[DIRECTION.LEFT]:
		global_position.x += tpos.x - limits[DIRECTION.LEFT]
	elif tpos.x > limits[DIRECTION.RIGHT]:
		global_position.x += tpos.x - limits[DIRECTION.RIGHT]

# each limit is the position of the target when it touches the edge of the pushbox
func get_limits(cpos: Vector3, r: float) -> Array[float]:
	var limits: Array[float] = [0, 0, 0, 0]

	limits[DIRECTION.UP] = cpos.z + pushbox_top_left.y + r
	limits[DIRECTION.DOWN] = cpos.z + pushbox_bottom_right.y - r
	limits[DIRECTION.LEFT] = cpos.x + pushbox_top_left.x + r
	limits[DIRECTION.RIGHT] = cpos.x + pushbox_bottom_right.x - r

	return limits

func get_speedzone_limits(cpos: Vector3, r: float) -> Array[float]:
	var limits: Array[float] = [0, 0, 0, 0]

	limits[DIRECTION.UP] = cpos.z + speedup_zone_top_left.y + r
	limits[DIRECTION.DOWN] = cpos.z + speedup_zone_bottom_right.y - r
	limits[DIRECTION.LEFT] = cpos.x + speedup_zone_top_left.x + r
	limits[DIRECTION.RIGHT] = cpos.x + speedup_zone_bottom_right.x - r

	return limits


func detect_pushing(cpos: Vector3, tpos: Vector3, r: float) -> Array[bool]:
	var limits := get_limits(cpos, r)
	var speedzone_limits := get_speedzone_limits(cpos, r)

	var push_in: Array[bool] = [false, false, false, false]

	# orthogonal pushing when against a wall
	if tpos.x >= limits[DIRECTION.RIGHT] || tpos.x <= limits[DIRECTION.LEFT]:
		push_in = detect_push_in(DIRECTION.UP, push_in)
		push_in = detect_push_in(DIRECTION.DOWN, push_in)

	if tpos.z <= limits[DIRECTION.UP] || tpos.z >= limits[DIRECTION.DOWN]:
		push_in = detect_push_in(DIRECTION.LEFT, push_in)
		push_in = detect_push_in(DIRECTION.RIGHT, push_in)

	# pushing in speedup zones
	if tpos.x > speedzone_limits[DIRECTION.RIGHT]:
		push_in = detect_push_in(DIRECTION.RIGHT, push_in)
	elif tpos.x < speedzone_limits[DIRECTION.LEFT]: # elif to avoid double pushing when speedup zones overlap
		push_in = detect_push_in(DIRECTION.LEFT, push_in)

	if tpos.z < speedzone_limits[DIRECTION.UP]:
		push_in = detect_push_in(DIRECTION.UP, push_in)
	elif tpos.z > speedzone_limits[DIRECTION.DOWN]:
		push_in = detect_push_in(DIRECTION.DOWN, push_in)
	
	return push_in


# detect if the target's velocity indicates that it's pushing in a certain direction
func detect_push_in(dir: DIRECTION, sped_up_in: Array[bool]) -> Array:
	if sped_up_in[dir]:
		return sped_up_in

	var tvel := Vector2(target.velocity.x, target.velocity.z)
	match dir:
		DIRECTION.UP:
			if tvel.y < 0:
				sped_up_in[dir] = true
		DIRECTION.DOWN:
			if tvel.y > 0:
				sped_up_in[dir] = true
		DIRECTION.RIGHT:
			if tvel.x > 0:
				sped_up_in[dir] = true
		DIRECTION.LEFT:
			if tvel.x < 0:
				sped_up_in[dir] = true

	return sped_up_in

# move the camera in the directions the target is pushing
func apply_push(dirs: Array[bool], delta: float) -> void:
	var tvel := target.velocity

	if dirs[DIRECTION.UP] && tvel.z < 0:
		global_position.z += tvel.z * push_ratio * delta

	if dirs[DIRECTION.DOWN] && tvel.z > 0:
		global_position.z += tvel.z * push_ratio * delta

	if dirs[DIRECTION.LEFT] && tvel.x < 0:
		global_position.x += tvel.x * push_ratio * delta

	if dirs[DIRECTION.RIGHT] && tvel.x > 0:
		global_position.x += tvel.x * push_ratio * delta

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# draw pushbox
	add_box(immediate_mesh, pushbox_top_left, pushbox_bottom_right)
	# draw speedup zone
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
