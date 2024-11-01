extends Node

@export var cameras: Array[CameraControllerBase]

var current_controller: int = 0


func _ready():
	for camera in cameras:
		if null != camera:
			camera.current = false
	if (len(cameras) > current_controller + 1):
		cameras[current_controller].make_current()


func _process(_delta):
	if Input.is_action_just_pressed("cycle_camera_controller"):
		current_controller += 1
		if len(cameras) < current_controller + 1:
			current_controller = 0
		
		for index in len(cameras):
			if null != cameras[index]:
				if index == current_controller:
					cameras[current_controller].make_current()
					# init the camera with the target's position
					cameras[current_controller].position = cameras[current_controller].target.position
				else:
					cameras[index].current = false
		#make sure we have an active controller
		if cameras[current_controller] == null:
			for index in len(cameras):
				if null != cameras[index]:
					current_controller = index
					cameras[current_controller].make_current()
		
		print(current_controller)
