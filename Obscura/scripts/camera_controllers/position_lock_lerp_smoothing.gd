class_name PositionLockLerpSmoothing
extends CameraControllerBase

@export var follow_speed: float
@export var catchup_speed: float
@export var leash_distance: float

func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic()
	
	var tpos := target.global_position
	var input := target.input_dir

	# without input, catch up to the target
	if input == Vector2.ZERO:
		move_towards(tpos, catchup_speed, delta)
	
	# with input, follow the target
	else:
		var follow = follow_speed * target.velocity.length()
		move_towards(tpos, follow, delta)

	if xz_to(tpos).length() > leash_distance:
		apply_leash(tpos)

	super(delta)

func apply_leash(tpos: Vector3) -> void:
	var direction := xz_to(tpos).normalized()
	var new_pos: Vector3 = tpos - direction * leash_distance

	global_position.x = new_pos.x
	global_position.z = new_pos.z

# move the camera towards a target without overshooting
func move_towards(tpos: Vector3, speed: float, delta: float) -> void:
	var to := xz_to(tpos)
	var offset := speed * to.normalized() * delta
	
	if offset.length() > to.length():
		global_position = tpos
	else:
		global_position += offset

# get the vector from the camera to a target on the xz plane
func xz_to(v: Vector3) -> Vector3:
	var to := v - global_position
	to.y = 0
	return to
	
func draw_logic() -> void:
	const LENGTH: float = 5.0

	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# draw cross
	immediate_mesh.surface_add_vertex(Vector3(-LENGTH, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(LENGTH, 0, 0))
	
	immediate_mesh.surface_add_vertex(Vector3(0, 0, -LENGTH))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, LENGTH))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()