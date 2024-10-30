class_name AutoScroll
extends CameraControllerBase

@export var top_left: Vector2
@export var bottom_right: Vector2
@export var autoscroll_speed: Vector3

func _ready() -> void:
	super()
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic()
	
	global_position += autoscroll_speed * delta

	var tl_pos := Vector2(top_left.x + global_position.x, top_left.y + global_position.z)
	var br_pos := Vector2(bottom_right.x + global_position.x, bottom_right.y + global_position.z)

	var tpos := Vector2(target.global_position.x, target.global_position.z)
	var trad := target.RADIUS
	if tpos.x - trad < tl_pos.x:
		target.global_position.x = tl_pos.x + trad
	if tpos.x + trad > br_pos.x:
		target.global_position.x = br_pos.x - trad
	if tpos.y - trad < tl_pos.y:
		target.global_position.z = tl_pos.y + trad
	if tpos.y + trad > br_pos.y:
		target.global_position.z = br_pos.y - trad

	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	var top_left_vert := Vector3(top_left.x, 0, top_left.y)
	var top_right_vert := Vector3(bottom_right.x, 0, top_left.y)
	var bottom_left_vert := Vector3(top_left.x, 0, bottom_right.y)
	var bottom_right_vert := Vector3(bottom_right.x, 0, bottom_right.y)

	immediate_mesh.surface_add_vertex(top_left_vert)
	immediate_mesh.surface_add_vertex(top_right_vert)

	immediate_mesh.surface_add_vertex(top_right_vert)
	immediate_mesh.surface_add_vertex(bottom_right_vert)

	immediate_mesh.surface_add_vertex(bottom_right_vert)
	immediate_mesh.surface_add_vertex(bottom_left_vert)

	immediate_mesh.surface_add_vertex(bottom_left_vert)
	immediate_mesh.surface_add_vertex(top_left_vert)
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
