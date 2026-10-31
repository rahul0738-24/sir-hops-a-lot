extends Area2D

const speed = 200.0
var direction  = 1

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	sprite.flip_h = direction < 0
	get_tree().create_timer(7.0).timeout.connect(queue_free)

func _process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target.has_method("die"):
		target.die()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("add_coin"):
		queue_free()
