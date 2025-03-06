extends Node2D

@onready var character = get_parent()
@onready var sprite = character.get_node("Sprite2D")
var light_occluder = null
var occluder_polygons = {}
var last_position = Vector2.ZERO

func _ready():
	# Create a LightOccluder2D node
	light_occluder = LightOccluder2D.new()
	character.add_child(light_occluder)
	
	# Generate occluder polygons for each animation state
	var animation_player = character.get_node("AnimationPlayer")
	for state in character.state_animations.keys():
		print("Generating occluder for state: ", state)
		var animation_name = character.state_animations[state]
		
		# Store the first frame of each animation
		animation_player.play(animation_name)
		animation_player.seek(0, true)
		await get_tree().process_frame
		
		# Create polygon for this animation state
		var polygon = create_polygon_from_sprite()
		if polygon:
			occluder_polygons[state] = polygon
	
	# Set initial occluder polygon
	update_occluder(character.current_state)
	
	# Connect to state changes
	character.state_changed.connect(_on_state_changed)
	
	# Add process to continuously update occluder position
	set_process(true)

func _physics_process(_delta):
	# Update the occluder position every frame to match sprite
	if light_occluder and light_occluder.occluder:
		_update_occluder_position()

func _on_state_changed(new_state):
	update_occluder(new_state)

func update_occluder(state):
	if occluder_polygons.has(state):
		light_occluder.occluder = occluder_polygons[state]
		_update_occluder_position()
		print("Updated occluder for state: ", state)

func _update_occluder_position():
	# Reset position to zero (relative to character)
	light_occluder.position = Vector2.ZERO
	
	# If our sprite has an offset, apply it to the occluder
	if sprite:
		var new_position = sprite.position
		light_occluder.position = new_position
		
		# Only print when the position actually changes
		if last_position != new_position:
			print("Updating occluder position to match sprite: ", new_position)
			last_position = new_position
	
	# Handle flipping
	if sprite.flip_h:
		light_occluder.scale.x = -1
	else:
		light_occluder.scale.x = 1

# Creates a polygon from the current sprite state
func create_polygon_from_sprite():
	# Get the sprite's texture
	var texture = sprite.texture
	if texture == null:
		print("No texture found on sprite")
		return null
	
	# Create a BitMap from the texture
	var bitmap = BitMap.new()
	var image = texture.get_image()
	bitmap.create_from_image_alpha(image, 0.01)
	
	# Get polygons from the bitmap
	var bitmap_rect = Rect2(Vector2.ZERO, bitmap.get_size())
	var polygons = bitmap.opaque_to_polygons(bitmap_rect)
	
	if polygons.size() == 0:
		print("No polygons generated from sprite")
		return null
	
	# Create an OccluderPolygon2D
	var occluder_polygon = OccluderPolygon2D.new()
	
	# Get the first (usually largest) polygon
	var points = polygons[0]
	
	# If sprite is centered, adjust polygon points
	if sprite.centered:
		var center_offset = texture.get_size() / 2
		var centered_points = []
		for point in points:
			centered_points.append(point - center_offset)
		points = centered_points
	
	# Set the polygon points
	occluder_polygon.polygon = points
	
	print("Created occluder polygon with ", points.size(), " points")
	return occluder_polygon

# Debug function to visualize the polygon
func debug_draw_polygon():
	if light_occluder and light_occluder.occluder:
		var debug_polygon = Polygon2D.new()
		debug_polygon.polygon = light_occluder.occluder.polygon
		debug_polygon.color = Color(1, 0, 0, 0.5)  # Semi-transparent red
		debug_polygon.position = light_occluder.position
		debug_polygon.scale = light_occluder.scale
		character.add_child(debug_polygon)
		print("Added debug polygon at ", debug_polygon.position)
		return debug_polygon
	return null
