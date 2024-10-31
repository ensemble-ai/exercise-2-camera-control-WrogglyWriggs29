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

	super(delta)

func _physics_process(delta: float) -> void:
	if target.velocity != Vector3.ZERO:
		stop_time_elapsed = 0.0
	else:
		stop_time_elapsed += delta

	var tpos := target.global_position
	var cpos := global_position
	var diff := tpos - cpos
	var diff2d := Vector2(diff.x, diff.z)
	var dir_to_target := diff.normalized()

	var camera_speed = lead_speed * target.speed / 50

	var input_dir = target.input_dir
	if diff2d.length() > leash_distance:
		var tpos_pred := tpos + target.velocity * delta
		var direction := Vector3(dir_to_target.x, 0, dir_to_target.z).normalized()
		var new_pos: Vector3 = tpos_pred - direction * max(leash_distance - 0.01, 0)

		global_position.x = new_pos.x
		global_position.z = new_pos.z

	elif input_dir != Vector2.ZERO:
		global_position += camera_speed * Vector3(input_dir.x, 0, input_dir.y) * delta

	elif stop_time_elapsed > catchup_delay_duration:
		global_position += catchup_speed * Vector3(dir_to_target.x, 0, dir_to_target.z) * delta

func draw_logic() -> void:
	const LENGTH: float = 5.0

	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

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
