extends Node2D

@export var speed: float = 40.0
@export var patrol_distance: float = 80.0

var direction := 1
var start_x := 0.0
var dead := false

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	start_x = position.x

func _process(delta: float) -> void:
	if dead:
		return

	position.x += direction * speed * delta

	if position.x > start_x + patrol_distance:
		direction = -1
	elif position.x < start_x - patrol_distance:
		direction = 1

	animated_sprite.flip_h = direction < 0

func die() -> void:
	if dead:
		return
	dead = true
	# fade out, then remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
