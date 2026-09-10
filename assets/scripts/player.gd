extends Sprite2D

@export var radius: float = 300.0
@export var speed: float = 3

var angle: float = 0.0


func _ready() -> void:
	position = Vector2(cos(angle), sin(angle)) * radius


func _unhandled_input(event: InputEvent) -> void:
	var is_mouse_click: bool = (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	)

	var is_spacebar: bool = (
		event is InputEventKey
		and event.keycode == KEY_SPACE
		and event.pressed
		and not event.is_echo()
	)

	if is_mouse_click or is_spacebar:
		speed = -speed


func _process(delta: float) -> void:
	angle += speed * delta
	position = Vector2(cos(angle), sin(angle)) * radius
