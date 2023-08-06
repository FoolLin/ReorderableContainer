# <img src="./addons/ReorderableContainer/Icon/reorderable_container_icon.svg" alt="drawing" width="25" style="padding-top: 20px;"/> ReorderableContainer
 A container similar to BoxContainer but extended with drag-and-drop style reordering functionality, and auto-scroll functionality when placed under ScrollContainer.
 
 ## How to use
1. Click the "+" button to add a new node and select `ReorderableVBox` or `ReorderableHBox`.
2. Add it under `ScrollContainer` if you want to make "Reorderable list". The container will automatically scroll when the user drag item to a certain point. <br />
  **Note:** This addon also works with [SmoothScroll](https://github.com/SpyrexDE/SmoothScroll) by SpyrexDE.
3. Add child control node under `ReorderableContainer` as many as you like and set `custom_minimum_size` to appropriate value.
4. Further documentation is provided with the addon but can be troublesome to access due to [this issue](https://github.com/godotengine/godot/issues/67203) and [this](https://godotforums.org/d/33337-custom-class-documentation-not-showing-up)

 ## License
[MIT](https://choosealicense.com/licenses/mit/)
