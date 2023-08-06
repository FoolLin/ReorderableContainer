@tool
@icon("Icon/reorderable_vbox_icon.svg")
class_name ReorderableVBox
extends ReorderableContainer

func set_vertical(value):
	value = true
	super.set_vertical(value)
	

func _ready():
	is_vertical = true
	super._ready()
