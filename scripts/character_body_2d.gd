extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = -275.0
const FIREBALL_SCENE = preload("res://fireball.tscn")
const FIREBALL_COOLDOWN = 10.0

var can_shoot = true
var is_hit = false
var health = 3
var invincible = false
var coins = 0

func _physics_process(delta: float) -> void:
		# Handle fireball
	if Input.is_action_just_pressed("shoot") and can_shoot and not is_hit:
		shoot_fireball()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# get the input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
			animated_sprite.flip_h = true

# play animations
	if not is_hit:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle animation")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")


	# apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_label = $CanvasLayer/HealthLabel
@onready var coin_label = $CanvasLayer2/CoinLabel

func _ready() -> void:
	update_health_label()
	update_coin_label()

func update_health_label() -> void:
	health_label.text = "Lives: " + str(health)


func take_damage() -> void:
	if invincible:
		return
	health -= 1
	update_health_label()
	is_hit = true
	animated_sprite.play("hit")
	animated_sprite.modulate = Color(1, 0.3, 0.3)
	if health <=0:
		Engine.time_scale = 0.5
		await get_tree().create_timer(0.6).timeout
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		return
	invincible = true
	velocity.y = -200
	await get_tree().create_timer(0.5).timeout
	is_hit = false
	animated_sprite.modulate = Color.WHITE
	await get_tree().create_timer(1.0).timeout
	invincible = false

func update_coin_label() -> void:
	coin_label.text = "Coins: " + str(coins)

func add_coin() -> void:
	coins +=1
	update_coin_label()

func shoot_fireball() -> void:
	can_shoot = false

	var fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = -1 if animated_sprite.flip_h else 1
	fireball.position = position + Vector2(fireball.direction * 16, -8)
	get_parent().add_child(fireball)

	await get_tree().create_timer(FIREBALL_COOLDOWN).timeout
	can_shoot = true
