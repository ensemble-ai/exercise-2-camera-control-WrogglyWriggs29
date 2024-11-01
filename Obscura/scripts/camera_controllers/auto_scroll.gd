class_name AutoScroll
extends CameraControllerBase

@export var top_left: Vector2
@export var bottom_right: Vector2
@export var autoscroll_speed: Vector3

enum DIRECTION {UP, DOWN, LEFT, RIGHT}

func _ready() -> void:
	super()
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic()
	
	# apply autoscroll
	global_position += autoscroll_speed * delta

	var tpos := target.global_position
	var r := target.RADIUS

	var limits := get_limits(global_position, r)

	# snap the target in each direction
	if tpos.z < limits[DIRECTION.UP]:
		target.global_position.z = limits[DIRECTION.UP]
	elif tpos.z > limits[DIRECTION.DOWN]:
		target.global_position.z = limits[DIRECTION.DOWN]

	if tpos.x < limits[DIRECTION.LEFT]:
		target.global_position.x = limits[DIRECTION.LEFT]
	elif tpos.x > limits[DIRECTION.RIGHT]:
		target.global_position.x = limits[DIRECTION.RIGHT]

	super(delta)

# each limit is the position of the target when it touches the edge of the bounding box
func get_limits(cpos: Vector3, r: float) -> Array[float]:
	var limits: Array[float] = [0, 0, 0, 0]

	limits[DIRECTION.UP] = cpos.z + top_left.y + r
	limits[DIRECTION.DOWN] = cpos.z + bottom_right.y - r
	limits[DIRECTION.LEFT] = cpos.x + top_left.x + r
	limits[DIRECTION.RIGHT] = cpos.x + bottom_right.x - r

	return limits

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# draw limits
	add_box(immediate_mesh, top_left, bottom_right)
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()

func add_box(mesh, tl: Vector2, br: Vector2) -> void:
	var top_left_vert := Vector3(tl.x, 0, tl.y)
	var top_right_vert := Vector3(br.x, 0, tl.y)
	var bottom_left_vert := Vector3(tl.x, 0, br.y)
	var bottom_right_vert := Vector3(br.x, 0, br.y)
	
	mesh.surface_add_vertex(top_left_vert)
	mesh.surface_add_vertex(top_right_vert)
	
	mesh.surface_add_vertex(top_right_vert)
	mesh.surface_add_vertex(bottom_right_vert)
	
	mesh.surface_add_vertex(bottom_right_vert)
	mesh.surface_add_vertex(bottom_left_vert)
	
	mesh.surface_add_vertex(bottom_left_vert)
	mesh.surface_add_vertex(top_left_vert)