extends CharacterBody2D

@onready
var sprite := $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
var last_dir = 0

var syncPos = Vector2(0, 0)
var syncOld = false
var syncRot = 0
var syncVel = Vector2(0, 0)
var syncDelta = 0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var facing_dir = Vector2(1, 1)
var anim = "default"
@export var bullet: PackedScene

var p_id
var is_local = false

var add_velocity = Vector2(0, 0)

var can_shoot = true

var max_hp = 100
var hp = max_hp

var DieParticleScene = preload("res://scenes/player_explode.tscn")

func _ready():
	Events.connect("player_quit", player_quit)
	
	if multiplayer.get_unique_id() == p_id:
		is_local = true
	
	$MultiplayerSynchronizer.set_multiplayer_authority(p_id)
	$Username.text = Game.players[p_id].name
	
	if is_local:
		$Camera2D.enabled = true
		$AudioListener2D.make_current()
		respawn()
		$PlayHPBar.hide()
		$Username.hide()
	else:
		sync_start(p_id)
		
@rpc("any_peer", "call_local", "reliable")
func set_hp(new_value):
	hp = new_value
	$PlayHPBar.hp_changed(new_value)
	if multiplayer.get_unique_id() == p_id:
		Events.emit_signal("hp_changed", new_value)
	if new_value <= 0:
		die()
		respawn()
	
func respawn():
	var spawn_nodes = get_tree().get_nodes_in_group("player_spawn_point")
	var spawn_point = spawn_nodes[randi_range(0, spawn_nodes.size()-1)]
	global_position = spawn_point.global_position
	if is_local:
		set_hp.rpc(100)

@rpc("any_peer", "call_local", "reliable")
func die():
	$SFX/Die.play()

	var n = DieParticleScene.instantiate()
	n.global_position = $ParticlePos.global_position
	get_tree().root.get_node("Main/Particles").add_child(n)

func _physics_process(delta):
	if is_local:

		# Add the gravity.
		if not is_on_floor():
			#if velocity.y < 1:
			#	velocity.y += gravity * 1.5 * delta
			#else:
			velocity.y += gravity * delta
				
			#var rot = clamp(0.005*velocity.abs().y, 0.5, 1.5)
			#rot = (1-(rot - 0.5))+0.5 # invert rotation accelertoin
			#sprite.rotate(deg_to_rad(360*1.5*delta*last_dir*rot))
		#else:
			#sprite.rotation_degrees = 0
		
		$WepRotation.look_at(get_global_mouse_position())
		
		# Handle Jump.
		if Input.is_action_just_pressed("action_jump") and is_on_floor() and !Game.is_ui_open:
			velocity.y = JUMP_VELOCITY
		
		syncPos = global_position
		syncRot = $WepRotation.rotation_degrees
		syncOld = false

		if Input.is_action_just_pressed("Shoot"):
			if can_shoot:
				shoot.rpc($WepRotation/BulletSpawn.global_position, $WepRotation.rotation_degrees, p_id)
				can_shoot = false
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		
		var direction = Input.get_axis("action_move_left", "action_move_right")
		if direction and !Game.is_ui_open:
			velocity.x = direction * SPEED
			last_dir = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		velocity += add_velocity
		add_velocity = Vector2(0, 0)
		syncVel = velocity
		move_and_slide()
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
		
		if !syncOld:
			#if p_id != 1: print(syncDelta, ' | ', global_position.distance_to(syncPos))
			Events.emit_signal("ping_updated", syncDelta)
			syncDelta = 0
			global_position = global_position.lerp(syncPos, .5)
			velocity = syncVel
			syncOld = true
		else:
			syncDelta += delta
			
		$WepRotation.rotation_degrees = lerpf($WepRotation.rotation_degrees, syncRot, 0.5)

		move_and_slide()
	
	
	if (abs(velocity.x) > 0.5):
		facing_dir.x = sign(velocity.x)
	if (abs(velocity.y) > 0.5):
		facing_dir.y = sign(velocity.y)
	
	if !is_on_floor():
		if facing_dir.y > 0:
			anim = "jump_up"
		else:
			anim = "jump_down"
	elif abs(velocity.x) > 0.5:
		anim = "run"
	elif is_on_floor():
		anim = "default"

	if facing_dir.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	$AnimatedSprite2D.play(anim)
	
	if global_position.y > 1000:
		if is_local:
			set_hp.rpc(0)
			var msg = "[color=Slateblue]" + Game.get_local_player().name + " fell into the void"
			Events.chat_sent.emit(msg)

func player_quit(id):
	if p_id == id:
		#$MultiplayerSynchronizer.public_visibility = false
		queue_free()

@rpc("any_peer", "call_local", "reliable")
func shoot(pos, rot, from_pid):
	var b = bullet.instantiate()
	b.from_pid = from_pid
	b.global_position = pos
	b.rotation_degrees = rot
	get_tree().root.get_node("Main/Projectiles").add_child(b)
	$SFX/BowShoot.play()


@rpc("any_peer", "call_local", "reliable")
func hurt(damage, from_pid, to_pid):
	$AnimationPlayer.play("hurt")

	$SFX/PlayerHurt.play()
	
	if multiplayer.get_unique_id() == from_pid:
		$SFX/BowHit.play()
	
	if is_local:
		if hp - damage <= 0:
			var msg = "[color=crimson]" + Game.players[from_pid].name + " has killed " + Game.players[to_pid].name
			Events.chat_sent.emit(msg)
		set_hp.rpc(hp - damage)


	

func _on_player_hitbox_area_entered(area):
	if area.name == 'projectile_hitbox':
		var arrow = area.get_parent()
		if p_id != arrow.from_pid:
			if p_id == multiplayer.get_unique_id():
				hurt.rpc(arrow.damage, arrow.from_pid, p_id)
				add_velocity += arrow.velocity.normalized() * 500
			arrow.queue_free()


func _on_shoot_cooldown_timeout():
	can_shoot = true


func sync_start(target_pid):
	$MultiplayerSynchronizer.set_visibility_for(target_pid, true)
	update_sync.rpc_id(target_pid, multiplayer.get_unique_id(), true)
	$MultiplayerSynchronizer.update_visibility(target_pid)

@rpc("any_peer", "reliable")
func update_sync(source_pid, value):
	$MultiplayerSynchronizer.set_visibility_for(source_pid, value)
	set_hp.rpc_id(source_pid, hp)

func stop_sync(target_pid):
	$MultiplayerSynchronizer.set_visibility_for(target_pid, false)
	update_sync.rpc_id(target_pid, multiplayer.get_unique_id(), false)
	$MultiplayerSynchronizer.update_visibility(target_pid)
