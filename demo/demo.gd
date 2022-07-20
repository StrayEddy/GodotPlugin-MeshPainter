extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ImageManager.create_mpaint_file("test.mpaint")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$CameraPivot.rotate_y(delta/2)
	$Label.text = str(Engine.get_frames_per_second())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
