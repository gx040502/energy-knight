extends Control

## Draws a grid-based minimap. Knows nothing about rooms, players or cameras —
## it only ever receives a dungeon grid and a current cell coordinate.

@export var background_color: Color = Color(0.05, 0.05, 0.07, 0.55)
@export var visited_color: Color = Color(0.55, 0.55, 0.62)
@export var start_color: Color = Color(0.35, 0.75, 0.40)
@export var current_color: Color = Color(1.0, 0.95, 0.60)
@export var cell_margin: float = 2.0

var _grid: Array = []
var _dimensions: Vector2i = Vector2i.ZERO
var _visited: Dictionary = {}
var _current_cell: Vector2i = Vector2i(-1, -1)
var _cell_size: float = 0.0
var _origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	resized.connect(_on_resized)


func setup(grid: Array, dimensions: Vector2i) -> void:
	_grid = grid
	_dimensions = dimensions
	_visited.clear()
	_current_cell = Vector2i(-1, -1)
	_recalculate_metrics()
	queue_redraw()


func set_current_cell(cell: Vector2i) -> void:
	_current_cell = cell
	_visited[cell] = true
	queue_redraw()


func _on_resized() -> void:
	_recalculate_metrics()
	queue_redraw()


func _recalculate_metrics() -> void:
	if _dimensions.x <= 0 or _dimensions.y <= 0:
		_cell_size = 0.0
		return
	# Fit the whole grid inside the Control, keeping cells square.
	_cell_size = minf(size.x / float(_dimensions.x), size.y / float(_dimensions.y))
	_origin = (size - Vector2(_dimensions) * _cell_size) * 0.5


func _draw() -> void:
	if _cell_size <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), background_color, true)

	for x: int in _dimensions.x:
		for y: int in _dimensions.y:
			var cell: Vector2i = Vector2i(x, y)
			if not _visited.has(cell):
				continue  # Undiscovered rooms stay hidden — free fog of war.
			var symbol: String = str(_grid[x][y])
			if symbol == "0":
				continue

			var top_left: Vector2 = _origin + Vector2(cell) * _cell_size + Vector2(cell_margin, cell_margin)
			var cell_rect: Rect2 = Rect2(top_left, Vector2.ONE * (_cell_size - cell_margin * 2.0))
			draw_rect(cell_rect, _color_for(cell, symbol), true)


func _color_for(cell: Vector2i, symbol: String) -> Color:
	if cell == _current_cell:
		return current_color
	if symbol == "S":
		return start_color
	return visited_color
