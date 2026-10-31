extends Node2D

const COIN_SCENE = preload("res://scenes/coins.tscn")

const WALK_ANIM = "walk animation"
const DEATH_ANIM = "death animation"
const ATTACK_ANIM = "attack animation"

@export var speed: float = 35.0
@export var hits_to_kill: int = 1
@export var coins_dropped: int = 3
@export var attack_cooldown: float = 1.5
# which frames of the attack animation the flail can hurt on
@export var hit_frame_start: int = 4
@export var hit_frame_end: int = 9

var direction := 1
var dead := false
var attacking := false
var can_attack := true
var player: Node2D = null
var player_in_range := false

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var ledge_right = $ledgeRight
@onready var ledge_left = $ledgeLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var flail_hitbox = $FlailHitbox

func _ready() -> void:
	animated_sprite.play(WALK_ANIM)
	flail_hitbox.monitoring = false

	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)
	flail_hitbox.body_entered.connect(_on_flail_hit)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if dead or attacking:
		return

	if player_in_range and can_attack:
		attack()
		return

	# turn around at walls
	if ray_cast_right.is_colliding():
		direction = -1
	if ray_cast_left.is_colliding():
		direction = 1

	# turn around at ledges
	if direction == 1 and not ledge_right.is_colliding():
		direction = -1
	elif direction == -1 and not ledge_left.is_colliding():
		direction = 1

	animated_sprite.flip_h = direction < 0
	flail_hitbox.scale.x = direction
	position.x += direction * speed * delta

# ---------- attack ----------

func attack() -> void:
	attacking = true

	# face the player
	if player:
		direction = 1 if player.global_position.x > global_position.x else -1
	animated_sprite.flip_h = direction < 0
	flail_hitbox.scale.x = direction

	animated_sprite.play(ATTACK_ANIM)

func _on_frame_changed() -> void:
	if dead:
		return
	var swinging = attacking \
		and animated_sprite.animation == ATTACK_ANIM \
		and animated_sprite.frame >= hit_frame_start \
		and animated_sprite.frame <= hit_frame_end
	flail_hitbox.set_deferred("monitoring", swinging)

func _on_flail_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()

func _on_animation_finished() -> void:
	if dead:
		return
	if animated_sprite.animation == ATTACK_ANIM:
		attacking = false
		flail_hitbox.set_deferred("monitoring", false)
		animated_sprite.play(WALK_ANIM)
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func _on_detection_entered(body: Node2D) -> void:
	if body.has_method("add_coin"):
		player = body
		player_in_range = true

func _on_detection_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false

# ---------- getting hurt ----------

# stomped by the player
func _on_head_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.has_method("add_coin") and body.velocity.y > 0 and not body.is_hit:
		body.velocity.y = -250
		_kill()

# called by the fireball
func die() -> void:
	if dead:
		return
	hits_to_kill -= 1
	if hits_to_kill <= 0:
		_kill()
	else:
		animated_sprite.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.15).timeout
		animated_sprite.modulate = Color.WHITE

func _kill() -> void:
	dead = true
	attacking = false

	# stop it hurting the player or being hit again
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

	drop_coins()

	animated_sprite.play(DEATH_ANIM)
	await animated_sprite.animation_finished
	queue_free()

func drop_coins() -> void:
	for i in range(coins_dropped):
		var coin = COIN_SCENE.instantiate()
		coin.position = position + Vector2((i - (coins_dropped - 1) / 2.0) * 10, -6)
		get_parent().add_child.call_deferred(coin)
