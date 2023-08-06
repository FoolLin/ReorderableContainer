@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("ReorderableContainer", "Container", preload("reorderable_container.gd"), preload("Icon/reorderable_container_icon.svg"))
	add_custom_type("ReorderableVBox", "ReorderableContainer", preload("reorderable_vbox.gd"), preload("Icon/reorderable_vbox_icon.svg"))
	add_custom_type("ReorderableHBox", "ReorderableContainer", preload("reorderable_hbox.gd"), preload("Icon/reorderable_hbox_icon.svg"))
	

func _exit_tree():
	remove_custom_type("ReorderableContainer")
	remove_custom_type("ReorderableVBox")
	remove_custom_type("ReorderableHBox")
