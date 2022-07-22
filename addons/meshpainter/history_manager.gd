tool
extends Node

# buffer 0 to 3, from oldest to newest
# _ready			[]
# add_history 		[*buffer_0]
# add_history 		[*buffer_1, buffer_0]
# add_history 		[*buffer_2, buffer_1, buffer_0]
# undo				[buffer_2, *buffer_1, buffer_0]
# undo				[buffer_2, buffer_1, *buffer_0]
# redo				[buffer_2, *buffer_1, buffer_0]
# add_history		[*buffer_1, buffer_0] -> [*buffer_3, buffer_1, buffer_0]

class_name HistoryManager

const history_capacity = 5

var brush_buffer_history :Array
var color_buffer_history :Array
var history_index :int

func _ready() -> void:
	clear()

func clear():
	brush_buffer_history = []
	color_buffer_history = []
	history_index = 0

func clear_history_ahead():
	for i in range(0, history_index):
		brush_buffer_history.pop_front()
		color_buffer_history.pop_front()

func add_history(brush_buffer :Array, color_buffer :Array):
	if history_index > 0:
		clear_history_ahead()
		history_index = 0
	brush_buffer_history.push_front(brush_buffer.duplicate())
	color_buffer_history.push_front(color_buffer.duplicate())

func undo():
	if history_index < brush_buffer_history.size() - 1:
		history_index += 1

func redo():
	if history_index > 0:
		history_index -= 1

func get_brush_buffer() -> Array:
	if brush_buffer_history.empty():
		return []
	else:
		return brush_buffer_history[history_index].duplicate()

func get_color_buffer() -> Array:
	if color_buffer_history.empty():
		return []
	else:
		return color_buffer_history[history_index].duplicate()
