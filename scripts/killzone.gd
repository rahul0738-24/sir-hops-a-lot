extends Area2D

@export var instant_kill = true
@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if instant_kill:
		print("you died!")
		Engine.time_scale = 0.5
		body.get_node("CollisionShape2D").queue_free()
		body.get_node("AnimatedSprite2D").play("hit")
		body.is_hit = true
		timer.start()
	else:
		body.take_damage()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
