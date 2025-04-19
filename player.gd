extends CharacterBody2D

const SPEED = 440.0
const JUMP_VELOCITY = -700.0
const ROTATION_SPEED = 200.0 # degrees per second
const GRAVITY = 980.0

var is_jumping = false

@onready var rotating_node = $Sprite2D
@onready var camera = $Camera2D
@onready var ground = get_node("/root/PlayScene/Ground")

func _ready():
	camera.limit_left = int(global_position.x)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Auto-move
	velocity.x = SPEED

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		print("Jumped!")

	# Rotate while in air
	if not is_on_floor():
		rotating_node.rotation_degrees = fmod(rotating_node.rotation_degrees + ROTATION_SPEED * delta, 360)

	# Snap rotation on land
	if is_on_floor() and not is_jumping and velocity.y >= 0:
		print("Landed from falling. Snap rotation.")
		snap_rotation()
	elif is_on_floor() and is_jumping and velocity.y >= 0:
		print("Landed from jumping. Snap rotation.")
		is_jumping = false
		snap_rotation()

	# Move and check collisions
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			var normal = collision.get_normal()

			if collider is TileMapLayer and collider.name == "Level":
				var collision_pos = collision.get_position()
				var tile_pos = collider.local_to_map(collider.to_local(collision_pos))
				var tile_data = collider.get_cell_tile_data(tile_pos)

				if tile_data:
					var is_deadly = tile_data.get_custom_data("is_deadly") == true
					
					if is_deadly:
						print("☠️ Deadly tile touched! Restarting.")
						get_tree().reload_current_scene()
						break
					
					# Check if this is a safe top collision
					if normal.y < -0.5:
						print("✅ Safe top collision on non-deadly tile.")
						continue
					else:
						print("☠️ Side/bottom collision with non-deadly tile. Restarting.")
						get_tree().reload_current_scene()
						break
			else:
				# Collided with something else (not tilemap)
				if normal.y > -0.7:
					print("☠️ Side/bottom collision with object. Restarting.")
					get_tree().reload_current_scene()
					break

	# Move the ground with player
	ground.position.x = global_position.x - 200

func snap_rotation():
	var angles = [0, 90, 180, 360]
	var current = fmod(rotating_node.rotation_degrees, 360)
	if current < 0:
		current += 360
	var closest = angles[0]
	var min_diff = abs(current - closest)
	for angle in angles:
		var diff = abs(current - angle)
		if diff < min_diff:
			min_diff = diff
			closest = angle
	rotating_node.rotation_degrees = closest
