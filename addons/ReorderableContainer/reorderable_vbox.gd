@tool
@icon("Icon/reorderable_vbox_icon.svg")
class_name ReorderableVBox
extends ReorderableContainer
## A container that allows its child to be reorder and arranges vertically.


func set_vertical(value):
	value = true
	super.set_vertical(value)
	

func _ready():
	is_vertical = true
	super._ready()
