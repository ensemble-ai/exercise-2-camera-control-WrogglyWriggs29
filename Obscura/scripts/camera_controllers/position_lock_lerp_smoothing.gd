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
	
	var tpos2 := Vector2(target.global_position.x, target.global_position.z)
	var cpos2 := Vector2(global_position.x, global_position.z)
	var distance = tpos2 - cpos2
	var length = distance.length()
	var direction = distance.normalized()

	if length > leash_distance:
		var new_pos: Vector2 = tpos2 - direction * max((leash_distance - 0.4), 0)
		position.x = new_pos.x
		position.z = new_pos.y
	elif target.velocity == Vector3.ZERO:
		var cvel: Vector2 = direction * catchup_speed * delta
		if cvel.length() > length:
			cvel = distance
		position.x += cvel.x
		position.z += cvel.y
	else:
		var follow = follow_speed * target.velocity.length()
		var cvel: Vector2 = direction * follow * delta
		if cvel.length() > length:
			cvel = distance
		position.x += cvel.x
		position.z += cvel.y


	super(delta)

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