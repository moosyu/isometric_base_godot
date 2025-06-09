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
var land_atlas_array: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
var foliage_atlas_array: Array[Vector2i] = [Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2)]
var dirt_atlas_array: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0)]
var foliage_decoration_atlas_array: Array[Vector2i] = [Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4)]

func _ready() -> void:
	noise_height_texture.noise.seed = 1
	noise = noise_height_texture.noise
	generate_world()
	generate_foliage()

func generate_world():
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
			
func generate_foliage():
	for x in range(-width, width -1):
		for y in range(-height, height - 1):
			var ground_item_current = ground_layer.get_cell_atlas_coords(Vector2i(x, y))
			if foliage_atlas_array.has(ground_item_current) and rng.randi_range(0, 10) > 8:
				foliage_layer.set_cell(Vector2i(x, y), source_id, foliage_decoration_atlas_array.pick_random())

func orienting():
	var edge_water_tiles: Array[Vector2i]
	for x in range(-width, width):
		for y in range(-height, height):
			if ground_layer.get_cell_atlas_coords(Vector2i(x, y)) == water_atlas:
				var current_tile_surrounding = ground_layer.get_surrounding_cells(Vector2i(x, y))
				for z in range(current_tile_surrounding.size()):
					if ground_layer.get_cell_atlas_coords(current_tile_surrounding[z]) != water_atlas:
						edge_water_tiles.append(Vector2i(x, y))
						break

	for z in range(edge_water_tiles.size()):
		ground_layer.set_cell(edge_water_tiles[z], source_id, Vector2i(3, 6))


func _on_button_pressed() -> void:
	orienting()
