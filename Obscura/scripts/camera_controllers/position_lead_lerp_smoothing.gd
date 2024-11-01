class_name PositionLeadLerpSmoothing
extends CameraControllerBase

@export var lead_speed: float
@export var catchup_delay_duration: float
@export var catchup_speed: float
@export var leash_distance: float

var stop_time_elapsed: float = 0.0

func _ready() -> void:
	super()
	position = target.position
	
func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic()

	var input := target.input_dir
	var tpos := target.global_position

	# update clock
	if input != Vector2.ZERO:
		stop_time_elapsed = 0.0
	else:
		stop_time_elapsed += delta

	# catch up if no movement input has been provided for enough time
	if stop_time_elapsed > catchup_delay_duration:
		catchup_to(tpos, delta)
	# otherwise speed up in the direction of the input
	elif input != Vector2.ZERO:
		speedup_in_direction(xz_to_3d(input).normalized(), delta)

	# apply leash
	if xz_to(tpos).length() > leash_distance:
		apply_leash(tpos)
	
	super(delta)

func catchup_to(tpos: Vector3, delta: float) -> void:
	var to_target := xz_to(tpos)
	var offset := catchup_speed * to_target.normalized() * delta

	# don't overshoot the target
	if offset.length() > to_target.length():
		global_position = tpos
	else:
		global_position += offset

func speedup_in_direction(dir: Vector3, delta: float) -> void:
	# account for hyperdrive
	var camera_speed = lead_speed * target.speed / 50
	global_position += camera_speed * dir * delta

func apply_leash(tpos: Vector3) -> void:
	var direction := xz_to(tpos).normalized()
	var new_pos: Vector3 = tpos - direction * leash_distance

	global_position.x = new_pos.x
	global_position.z = new_pos.z

# get the vector from the camera to v projected to the xz plane
func xz_to(v: Vector3) -> Vector3:
	var to := v - global_position
	to.y = 0
	return to

# convert an 2d vector like (x, z) to 3d
func xz_to_3d(v: Vector2) -> Vector3:
	return Vector3(v.x, 0, v.y)


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