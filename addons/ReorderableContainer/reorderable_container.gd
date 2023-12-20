@tool
@icon("Icon/reorderable_container_icon.svg")
class_name ReorderableContainer
extends Container
## A container that allows its child to be reorder and arranges horizontally or vertically.
##
## A container similar to [BoxContainer] but extended with drag-and-drop style reordering functionality, 
## and auto-scroll functionality when placed under [ScrollContainer].[br][br]
## [b]Note:[/b] This addon also works with SmoothScroll by SpyrexDE.
##
## @tutorial(SmoothScroll): https://github.com/SpyrexDE/SmoothScroll
## @tutorial(Using Containers): https://docs.godotengine.org/en/4.1/tutorials/ui/gui_containers.html

## Emitted when children have been reordered.
signal reordered(from: int, to: int)

## Extend the drop zone length at the start and end of the container. 
## This will ensure that drop input is recognized even outside the container itself.
const DROP_ZONE_EXTEND = 2000

## The hold duration time in seconds before the holded child will start being drag.
@export 
var hold_duration := 0.5

## The overall speed of how fast children will move and arrange.
@export_range(3, 30, 0.01, "or_greater", "or_less")
var speed := 10.0

## The space between the container's elements, in pixels.
@export 
var separation := 10: set = set_separation
func set_separation(value):
	if value == separation or value < 0:
		return
	separation = value
	_on_sort_children()


## if [code]true[/code] the container will arrange its children vertically, rather than horizontally.
@export var is_vertical := false: set = set_vertical
func set_vertical(value):
	if value == is_vertical:
		return
	is_vertical = value
	if is_vertical:
		custom_minimum_size.x = 0
	else:
		custom_minimum_size.y = 0
	_on_sort_children()

## (Optional) [ScrollContainer] refference. Normally, the addon will automatically check 
## its parent node for [ScrollContainer]. If this is not the case, you can manually specify it here.
@export
var scroll_container: ScrollContainer

## The maximum speed of auto scroll.
@export 
var auto_scroll_speed := 10.0

## The pacentage of how much space auto scroll will take in [ScrollContainer][br][br]
## [b]Example:[/b] If [code]auto_scroll_range[/code] is 30% (0.3) and [ScrollContainer] height is 100 px, 
## upper part will be 0 to 30 px and lower part will be 70 to 100 px.
@export_range(0, 0.5) 
var auto_scroll_range := 0.3

## The scrolling threshold in pixel. In a nutshell, user will have hard time trying to drag a child if it too low
## and user will accidentally drag a child when scrolling if it too high.
@export 
var scroll_threshold := 30

## Uses when debugging
@export
var is_debugging := false

var _scroll_starting_point := 0
var _is_smooth_scroll := false

var _drop_zones: Array[Rect2] = []
var _drop_zone_index := -1
var _expect_child_rect: Array[Rect2] = []

var _focus_child: Control
var _is_press := false
var _is_hold := false
var _current_duration := 0.0
var _is_using_process := false


func _ready():
	if scroll_container == null and get_parent() is ScrollContainer:
		scroll_container = get_parent()
		
	if scroll_container != null and scroll_container.has_method("handle_overdrag"):
		_is_smooth_scroll = true
	
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_adjust_expected_child_rect()
	if not sort_children.is_connected(_on_sort_children):
		sort_children.connect(_on_sort_children, CONNECT_PERSIST)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added, CONNECT_PERSIST)


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		for _child in get_children():
			var child := _child as Control
			if child.get_rect().has_point(get_local_mouse_position()) and event.is_pressed():
				_focus_child = child
				_is_press = true
			elif not event.is_pressed():
				_is_press = false
				_is_hold = false


func _process(delta):
	if Engine.is_editor_hint(): return	
	
	_handle_input(delta)
	if _current_duration >= hold_duration != _is_hold:
		_is_hold = _current_duration >= hold_duration
		if _is_hold:
			_on_start_dragging()
	
	if _is_hold:
		_handle_dragging_child_pos(delta)
		if scroll_container != null:
			_handle_auto_scroll(delta)
	elif not _is_hold and _drop_zone_index != -1:
		_on_stop_dragging()
			
	if _is_using_process :
		_on_sort_children(delta)


func _handle_input(delta): 
	if scroll_container != null and _is_press and not _is_hold:
		var scroll_point = scroll_container.scroll_vertical if is_vertical else scroll_container.scroll_horizontal
		if _current_duration == 0:
			_scroll_starting_point = scroll_point
		else:
			# If user scroll more than scroll_threshold, press is abort.
			_is_press = true if abs(scroll_point - _scroll_starting_point) <= scroll_threshold else false
	_current_duration = _current_duration + delta if _is_press else 0.0


func _on_start_dragging():
	# Force _on_sort_children to use process update for linear interpolation
	_is_using_process = true 
	_focus_child.z_index = 1
	# Workaround for SmoothScroll addon
	if _is_smooth_scroll:
		scroll_container.process_mode = Node.PROCESS_MODE_DISABLED
	for child in _get_visible_children():
		child.propagate_call("set_mouse_filter", [MOUSE_FILTER_IGNORE])


func _on_stop_dragging():
	_focus_child.z_index = 0
	var focus_child_index := _focus_child.get_index()
	move_child(_focus_child, _drop_zone_index)
	reordered.emit(focus_child_index, _drop_zone_index)
	_focus_child = null
	_drop_zone_index = -1
	if _is_smooth_scroll:
		scroll_container.pos = -Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical)
		scroll_container.process_mode = Node.PROCESS_MODE_INHERIT
	for child in _get_visible_children():
		child.propagate_call("set_mouse_filter", [MOUSE_FILTER_PASS])	


func _on_node_added(node):
	if node is Control and not Engine.is_editor_hint():
		node.mouse_filter = Control.MOUSE_FILTER_PASS


func _handle_dragging_child_pos(delta):
	if is_vertical:
		var target_pos = get_local_mouse_position().y - (_focus_child.size.y / 2.0)
		_focus_child.position.y = lerp(_focus_child.position.y, target_pos, delta * speed)
	else:
		var target_pos = get_local_mouse_position().x - (_focus_child.size.x / 2.0)
		_focus_child.position.x = lerp(_focus_child.position.x, target_pos, delta * speed)	
		
	# Update drop zone index
	var child_center_pos: Vector2 = _focus_child.get_rect().get_center()
	for i in range(_drop_zones.size()):
		var drop_zone = _drop_zones[i]
		if drop_zone.has_point(child_center_pos):
			_drop_zone_index = i
			break
		elif i == _drop_zones.size() - 1:
			_drop_zone_index = -1	


func _handle_auto_scroll(delta):
	var mouse_g_pos = get_global_mouse_position()
	var scroll_g_rect = scroll_container.get_global_rect()
	if is_vertical:
		var upper = scroll_g_rect.position.y + (scroll_g_rect.size.y * auto_scroll_range)
		var lower = scroll_g_rect.position.y + (scroll_g_rect.size.y * (1.0 - auto_scroll_range))
		
		if upper > mouse_g_pos.y:
			var factor = (upper - mouse_g_pos.y) / (upper - scroll_g_rect.position.y)
			scroll_container.scroll_vertical -= delta * float(auto_scroll_speed) * 150.0 * factor
		elif lower < mouse_g_pos.y:
			var factor = (mouse_g_pos.y - lower) / (scroll_g_rect.end.y - lower)
			scroll_container.scroll_vertical += delta * float(auto_scroll_speed) * 150.0 * factor
		else:
			scroll_container.scroll_vertical = scroll_container.scroll_vertical
	else:
		var left = scroll_g_rect.position.x + (scroll_g_rect.size.x * auto_scroll_range)
		var right = scroll_g_rect.position.x + (scroll_g_rect.size.x * (1.0 - auto_scroll_range))
		
		if left > mouse_g_pos.x:
			var factor = (left - mouse_g_pos.x) / (left - scroll_g_rect.position.x)
			scroll_container.scroll_horizontal -= delta * float(auto_scroll_speed) * 150.0 * factor
		elif right < mouse_g_pos.x:
			var factor = (mouse_g_pos.x - right) / (scroll_g_rect.end.x - right)
			scroll_container.scroll_horizontal += delta * float(auto_scroll_speed) * 150.0 * factor
		else:
			scroll_container.scroll_horizontal = scroll_container.scroll_horizontal		


func _on_sort_children(delta := -1.0):
	if _is_using_process and delta == -1.0:
		return
	
	_adjust_expected_child_rect()
	_adjust_child_rect(delta)
	_adjust_drop_zone_rect()


func _adjust_expected_child_rect():
	_expect_child_rect.clear()
	var children := _get_visible_children()
	var end_point = 0.0
	for i in range(children.size()):
		var child := children[i]
		if is_vertical:
			if i == _drop_zone_index:
				end_point += _focus_child.size.y + separation
			
			_expect_child_rect.append(Rect2(Vector2(0, end_point), Vector2(size.x, child.custom_minimum_size.y)))
			end_point += child.custom_minimum_size.y + separation
		else:
			if i == _drop_zone_index:
				end_point += _focus_child.size.x + separation
			
			_expect_child_rect.append(Rect2(Vector2(end_point, 0), Vector2(child.custom_minimum_size.x, size.y)))
			end_point += child.custom_minimum_size.x + separation			
			

func _adjust_child_rect(delta: float = -1.0):
	var children := _get_visible_children()
	if children.is_empty():
		return
	
	var is_animating := false
	var end_point := 0.0
	for i in range(children.size()):
		var child := children[i]
		if child.position == _expect_child_rect[i].position and child.size == _expect_child_rect[i].size:
			continue
		
		if _is_using_process:
			is_animating = true
			child.position = lerp(child.position, _expect_child_rect[i].position, delta * speed)
			child.size = _expect_child_rect[i].size
			if (child.position - _expect_child_rect[i].position).length() <= 1.0:
				child.position = _expect_child_rect[i].position
		else:
			child.position = _expect_child_rect[i].position
			child.size = _expect_child_rect[i].size
	
	var last_child := children[-1]
	if is_vertical:
		if _is_using_process and _drop_zone_index == children.size():
			custom_minimum_size.y = _expect_child_rect[-1].end.y + _focus_child.size.y + separation
		elif not _is_using_process:
			custom_minimum_size.y = last_child.get_rect().end.y
	else:
		if _is_using_process and _drop_zone_index == children.size():
			custom_minimum_size.x = _expect_child_rect[-1].end.x + _focus_child.size.x + separation
		elif not _is_using_process:
			custom_minimum_size.x = last_child.get_rect().end.x

	# Adjust rect every process frame until child is dropped and finished lerping 
	# ( return to adjust when sort_children signal is emitted)
	if not is_animating and _focus_child == null:
		_is_using_process = false


func _adjust_drop_zone_rect():
	_drop_zones.clear()
	var children = _get_visible_children()
	for i in range(children.size()):
		var drop_zone_rect: Rect2
		var child := children[i] as Control
		if is_vertical:
			if i == 0:
				# First child
				drop_zone_rect.position = Vector2(child.position.x, child.position.y - DROP_ZONE_EXTEND)
				drop_zone_rect.end = Vector2(child.size.x, child.get_rect().get_center().y)
				_drop_zones.append(drop_zone_rect)
			else:
				# In between
				var prev_child := children[i - 1] as Control
				drop_zone_rect.position = Vector2(prev_child.position.x, prev_child.get_rect().get_center().y)
				drop_zone_rect.end = Vector2(child.size.x, child.get_rect().get_center().y)
				_drop_zones.append(drop_zone_rect)
			if i == children.size() - 1:
				# Is also last child
				drop_zone_rect.position = Vector2(child.position.x, child.get_rect().get_center().y)
				drop_zone_rect.end = Vector2(child.size.x, child.get_rect().end.y + DROP_ZONE_EXTEND)
				_drop_zones.append(drop_zone_rect)
		else:
			if i == 0:
				# First child
				drop_zone_rect.position = Vector2(child.position.x - DROP_ZONE_EXTEND, child.position.y)
				drop_zone_rect.end = Vector2(child.get_rect().get_center().x, child.size.y)
				_drop_zones.append(drop_zone_rect)
			else:
				# In between
				var prev_child := children[i - 1] as Control
				drop_zone_rect.position = Vector2(prev_child.get_rect().get_center().x, prev_child.position.y)
				drop_zone_rect.end = Vector2(child.get_rect().get_center().x, child.size.y)
				_drop_zones.append(drop_zone_rect)
			if i == children.size() - 1:
				# Is also last child
				drop_zone_rect.position = Vector2(child.get_rect().get_center().x, child.position.y)
				drop_zone_rect.end = Vector2(child.get_rect().end.x + DROP_ZONE_EXTEND, child.size.y)
				_drop_zones.append(drop_zone_rect)


func _get_visible_children() -> Array[Control]:
	var visible_control: Array[Control]
	for _child in get_children():
		var child := _child as Control
		if not child.visible:
			continue
		if child == _focus_child and _is_hold:
			continue
		
		visible_control.append(child)
	return visible_control


func _print_debug(val):
	if is_debugging:
		print(val)
