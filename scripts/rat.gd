extends Node2D

const COIN_SCENE = preload("res://scenes/coins.tscn")
@export var hits_to_kill: int = 1
@export var coins_dropped: int = 2
@export var speed: float = 55.0
@export var attack_cooldown: float = 1.0
@export var hit_frame_start: int = 1
@export var hit_frame_end: int = 3


var dead := false
var direction = 1
var attacking = false
var can_attack = true
var player: Node2D = null
var player_in_range = false

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var ledge_right = $ledgeRight
@onready var ledge_left = $ledgeLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_hitbox = $AttackHitbox

func attack() -> void:
	attacking = true
	if player:
		direction = 1 if player.global_position.x > global_position.x else -1
	animated_sprite.flip_h = direction < 0
	attack_hitbox.scale.x = direction
	animated_sprite.play("hit animation")
func _on_frame_changed() -> void:
	var biting = attacking \
		and animated_sprite.animation == "hit animation" \
		and animated_sprite.frame >= hit_frame_start \
		and animated_sprite.frame <= hit_frame_end
	attack_hitbox.set_deferred("monitoring", biting)

func _on_bite_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
func _on_animation_finished() -> void:
	if animated_sprite.animation == "hit animation":
		attacking = false
		attack_hitbox.set_deferred("monitoring", false)
		animated_sprite.play("run animation")
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func _ready() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_bite_hit)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("run animation")


func _process(delta: float) -> void:
	if dead or attacking:
		queue_free()
		return

	if player_in_range and can_attack:
		attack()
		return
	if ray_cast_right.is_colliding():
		direction = 1
	if ray_cast_left.is_colliding():
		direction = -1
	if direction == 1 and not ledge_right.is_colliding():
		direction = -1
	elif direction == -1 and not ledge_left.is_colliding():
		direction = 1
	animated_sprite.flip_h = direction < 0
	position.x += direction * speed * delta


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("add_coin"):
		player = body
		player_in_range = true



func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false



func _on_head_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.has_method("add_coin") and body.velocity.y > 0 and not body.is_hit:
		body.velocity.y = -250
		_kill()

func die() -> void:
	if dead:
		return
	hits_to_kill -= 1
	if hits_to_kill <= 0:
		_kill()

func _kill() -> void:
	dead = true
	attacking = false

	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

	drop_coins()

	animated_sprite.play("death animation")
	await animated_sprite.animation_finished
	queue_free()

func drop_coins() -> void:
	for i in range(coins_dropped):
		var coin = COIN_SCENE.instantiate()
		coin.position = position + Vector2((i - (coins_dropped - 1) / 2.0) * 10, -6)
		get_parent().add_child.call_deferred(coin)
