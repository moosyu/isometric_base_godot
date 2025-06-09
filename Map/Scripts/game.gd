extends Node2D

@onready var ground_layer: TileMapLayer = $Layers/GroundLayer
@onready var foliage_layer: TileMapLayer = $Layers/FoliageLayer
@export var noise_height_texture: NoiseTexture2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var noise: Noise
var width: int = 50
var height: int = 50

var source_id = 0
var water_atlas = Vector2i(0, 10)
var land_atlas_array: Array[Vector2i] = [
	Vector2i(0, 2),
	Vector2i(1, 2),
	Vector2i(2, 2)
	]
var foliage_atlas_array: Array[Vector2i] = [
	Vector2i(7, 2),
	Vector2i(8, 2),
	Vector2i(9, 2),
	Vector2i(10, 2)
	]
var dirt_atlas_array: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(4, 0),
	Vector2i(5, 0),
	Vector2i(6, 0),
	Vector2i(7, 0),
	Vector2i(8, 0),
	Vector2i(9, 0),
	Vector2i(10, 0)
	]
var foliage_decoration_atlas_array: Array[Vector2i] = [
	Vector2i(8, 3),
	Vector2i(9, 3),
	Vector2i(10, 3),
	Vector2i(0, 4),
	Vector2i(1, 4),
	Vector2i(2, 4),
	Vector2i(3, 4),
	Vector2i(4, 4),
	Vector2i(5, 4)
	]

	#1
#2		8
	#4
#Top = 1
#Right = 8
#Bottom = 4
#Left = 2

var water_edge_tiles: Dictionary = {
	0: Vector2i(0, 11),   # no adjacent land
	1: Vector2i(1, 10),   # top only
	2: Vector2i(2, 10),   # left only
	3: Vector2i(5, 10),   # top + left
	4: Vector2i(4, 10),   # bottom only
	5: Vector2i(7, 12),   # top + bottom
	6: Vector2i(7, 10),   # left + bottom 
	7: Vector2i(8, 12),  # top + left + bottom
	8: Vector2i(3, 10),   # right only
	9: Vector2i(8, 10),   # right + top
	10: Vector2i(9, 12), # right + left
	11: Vector2i(10, 12), # top + left + right
	12: Vector2i(6, 10),  # bottom + right
	13: Vector2i(5, 12),   # top + bottom + right
	14: Vector2i(6, 12),   # left + bottom + right
	15: Vector2i(9, 10),  # all sides land
}

func _ready() -> void:
	noise_height_texture.noise.seed = 1
	noise = noise_height_texture.noise
	generate_world()
	generate_foliage()
	print(Vector2i(0,0) - Vector2i(0,-1))
	print(Vector2i(0,0) - Vector2i(0,1))
	print(Vector2i(0,0) - Vector2i(1,0))
	print(Vector2i(0,0) - Vector2i(-1,0))

func generate_world() -> void:
	for x in range(-width, width):
		for y in range(-height, height):
			var noise_val = noise.get_noise_2d(x, y)
			var atlas_pos: Vector2i

			if noise_val < -0.1:
				atlas_pos = water_atlas
			elif noise_val < 0.0:
				atlas_pos = dirt_atlas_array.pick_random()
			elif noise_val <= 0.2:
				atlas_pos = land_atlas_array.pick_random()
			elif noise_val < 0.45:
				atlas_pos = foliage_atlas_array.pick_random()
			else:
				atlas_pos = Vector2i(9, 9)

			ground_layer.set_cell(Vector2i(x, y), source_id, atlas_pos)
			
func generate_foliage() -> void:
	for x in range(-width, width -1):
		for y in range(-height, height - 1):
			var ground_item_current = ground_layer.get_cell_atlas_coords(Vector2i(x, y))
			if foliage_atlas_array.has(ground_item_current) and rng.randi_range(0, 10) > 8:
				foliage_layer.set_cell(Vector2i(x, y), source_id, foliage_decoration_atlas_array.pick_random())

# returns all of the tiles that are water and sit on the edge of land
func orienting() -> Array[Vector2i]:
	var edge_water_tiles: Array[Vector2i]
	for x in range(-width, width):
		for y in range(-height, height):
			if ground_layer.get_cell_atlas_coords(Vector2i(x, y)) == water_atlas:
				var current_tile_surrounding = ground_layer.get_surrounding_cells(Vector2i(x, y))
				for z in range(current_tile_surrounding.size()):
					if ground_layer.get_cell_atlas_coords(current_tile_surrounding[z]) != water_atlas:
						edge_water_tiles.append(Vector2i(x, y))
						break
	return edge_water_tiles

func apply_water_edges(tile_positions: Array[Vector2i]) -> Dictionary:
	var water_tiles_assigned_bitmap: Dictionary
	for x in range(tile_positions.size()):
		var tile_sides: Array[Vector2i] = ground_layer.get_surrounding_cells(tile_positions[x])
		var bitmask_count: int = 0
		for y in range(tile_sides.size()):
			if ground_layer.get_cell_atlas_coords(tile_sides[y]) != water_atlas:
				var diff = tile_positions[x] - tile_sides[y]
				if diff == Vector2i(0,1):
					bitmask_count += 1
				elif diff == Vector2i(0,-1):
					bitmask_count += 4
				elif diff == Vector2i(1,0):
					bitmask_count += 2
				elif diff == Vector2i(-1,0):
					bitmask_count += 8
				else:
					print("ruh roh, bitmask counting broke!!")
		
		if water_tiles_assigned_bitmap.has(bitmask_count):
			water_tiles_assigned_bitmap[bitmask_count].append(tile_positions[x])
		else:
			water_tiles_assigned_bitmap[bitmask_count] = [tile_positions[x]]

	return water_tiles_assigned_bitmap

func _on_button_pressed() -> void:
	var edge_bitmap_dict = apply_water_edges(orienting())

	for bitmask_count in edge_bitmap_dict.keys():
		# base water is fallback just increase.
		var atlas_coords = water_edge_tiles.get(bitmask_count, Vector2i(0, 10))
		for tile_pos in edge_bitmap_dict[bitmask_count]:
			ground_layer.set_cell(tile_pos, source_id, atlas_coords)
