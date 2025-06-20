extends PathFollow2D

@export var type: String = ""

signal base_damage(damage)
signal enemy_defeated(enemy_type)
signal enemy_escaped()
signal isdead()

var speed = 0
var hp = 0
var enemy_damage = 0
var dead = false

var previous_position = Vector2.ZERO

@onready var sprite = $CharacterBody2D/AnimatedSprite2D

func _ready() -> void:
	previous_position = position
	init_status()
	add_to_group("enemies")

func init_status():
	speed = GameData.enemies_data[type]["speed"]
	hp = GameData.enemies_data[type]["hp"]
	enemy_damage = GameData.enemies_data[type]["damage"]

func _physics_process(delta: float) -> void:
	var current_position = position
	var new_position = position
	var direction = (position - previous_position).normalized()
	
	previous_position = new_position
	
	update_animation(direction)

	if progress_ratio == 1.0 and !dead:
		emit_signal("base_damage", enemy_damage)

		if dead == false:
			emit_signal("enemy_escaped", type)
			dead = true
			queue_free()
	
	if dead == false:
		move(delta)

func move(delta):
	set_progress(get_progress() + speed * delta )

func update_animation(direction: Vector2):
	
	if !dead:
		if direction == Vector2.ZERO:
			return
		var anim = "WalkRight"
		
		if abs(direction.x) > abs(direction.y):
			anim = "WalkRight" if direction.x > 0 else "WalkLeft"
		else:
			anim = "WalkDown" if direction.y > 0 else "WalkUp"
		sprite.play(anim)

var collision_shape = true

func on_hit(damage):
	hp -= damage
	GameData.total_damage += damage
	
	if hp <= 0 and dead == false:
		GameData.enemies_defeated += 1
		
		dead = true
		emit_signal("enemy_defeated", type)
		
		$CharacterBody2D/CollisionShape2D.call_deferred("set_disabled", true)
		
		sprite.play("Dead")
		
		await sprite.animation_finished
		collision_shape = false
		emit_signal("isdead")
		
		queue_free()
		return true
		
	return false
		
