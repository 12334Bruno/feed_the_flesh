extends KinematicBody2D

# Movement constatns
var SPEED = 90

# Movement
var direction = Vector2.ZERO
var last_direction = direction
var velocity = Vector2.ZERO

# Items
var held_items = []
var on_item = null

# World constatns
var TILE_SIZE = 16

# Load scenes
onready var Main = get_parent().get_parent()
#onready var Grass = preload("res://World/Environment/Grass.tscn").instance()

func _physics_process(delta):
	highlight()
	take_player_input()
	update_player_movement(delta)
	interact()


func _unhandled_input(event):
	
	# Check for interactable objects/items 
	if event.is_action_pressed("ui_interact"):
		
		var player_grid_pos = Main.Grass.world_to_map(global_position)
		var items = Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x]
		
		# Snap released item to grid
		
		if held_items:
			
			if ((len(items) > 0 and items[0].item_name == held_items[0].item_name) or len(items) == 0):
					for item in held_items:
						Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].append(item)
						item.global_position = player_grid_pos * TILE_SIZE
						item.visible = true
						item.picked_up = false
					held_items = []
			
		elif len(items) > 0:
			# Check if item is interactable
			if items[0].get("interactable"):
				
				if Input.is_action_just_pressed("ui_take_one_item"):
					held_items.append(items[0])
					Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].erase(items[0])
				else:
					held_items = [] + items
					for i in items:
						i.visible = false
					items[0].visible = true
					Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].clear()
		else:
			# Check for walls in direction of last movement
			# Change player position to center (leg hitbox doesn't work)
			player_grid_pos = Main.Grass.world_to_map(global_position+Vector2(0,-TILE_SIZE/2))
			var wall_pos = Vector2(player_grid_pos.x+round(last_direction.x), player_grid_pos.y+round(last_direction.y))
			
			var wall = Main.wall_tiles[wall_pos.y][wall_pos.x]
			if wall and (last_direction.x == 0 or last_direction.y == 0):
				# Create new walls
				for i in range(3):
					for j in range(3):
						var tile_pos = Vector2(wall_pos.x-1+j,wall_pos.y-1+i)
						if (!(Main.wall_tiles[tile_pos.y][tile_pos.x]) and 
						player_grid_pos != tile_pos and 
						Main.Grass.get_cellv(tile_pos) != 1):
							Main.spawn_instance("wall", tile_pos, 0)
							Main.wall_tiles[wall_pos.y][wall_pos.x] = true
				# Delete old wall -> Fill with corrupt grass
				Main.spawn_instance("wall", wall_pos, -1)
				Main.wall_tiles[wall_pos.y][wall_pos.x] = false
				Main.spawn_instance("grass", wall_pos, 1)
				

func take_player_input():
	# Take player direction input
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = Vector2(x_input, y_input).normalized()
	
	# Set last_direction when moving 
	if x_input != 0 or y_input != 0:
		last_direction = direction

func interact():
	if held_items:
		held_items[0].global_position = Vector2(global_position.x, global_position.y -8) 


func update_player_movement(delta):
	velocity = direction * SPEED
	velocity = move_and_slide(velocity)

# Highlight 
func highlight():
	var player_grid_pos = Main.Grass.world_to_map(global_position)
	var items = Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x]
	# Set highlight if player is on interactable item 
	if len(items) > 0:
		# Check if item is interactable
		if items[0].get("interactable"):
			
			# Remove highlight from old item and add to new
			if on_item != items[0] and on_item != null:
				on_item.material.set_shader_param("width", 0.0)
			on_item = items[0]
			items[0].material.set_shader_param("width", 1.0)

	elif on_item != null:
		# Turn of highlight if the player isn't on a item
		on_item.material.set_shader_param("width", 0.0)
		on_item = null

