extends Node2D

const  speed = 45

var direction = 1
var coin_scene = preload("res://scenes/coins.tscn")

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var ledge_Right = $ledgeRight
@onready var ledge_Left = $ledgeLeft
@onready var animated_sprite = $AnimatedSprite2D

func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true

	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	if direction == 1 and not ledge_Right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true

	elif direction == -1 and not ledge_Left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * speed * delta


func _on_head_body_entered(body: Node2D) -> void:
	if body.has_method("add_coin") and body.velocity.y > 0 and not body.is_hit:
		body.velocity.y = -250
		drop_coins()
		queue_free()

func drop_coins() -> void:
	for i in range(5):
		var coin = coin_scene.instantiate()
		coin.position = position + Vector2((1 - 2)*10, - 6)
		get_parent().add_child.call_deferred(coin)
