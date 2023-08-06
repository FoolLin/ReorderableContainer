@tool
@icon("Icon/reorderable_hbox_icon.svg")
class_name ReorderableHBox
extends ReorderableContainer

func set_vertical(value):
	value = false
	super.set_vertical(value)


func _ready():
	is_vertical = false
	super._ready()
