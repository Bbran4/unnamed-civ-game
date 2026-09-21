extends Node

## Centralized scene transition helper.
const WARP_TRANSITION_SCENE: PackedScene = preload("res://scenes/ui/warp_transition.tscn")

func change_scene(scene_path: String) -> void:
    if not ResourceLoader.exists(scene_path):
        push_error("Scene does not exist: %s" % scene_path)
        return

    var error: Error = get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_error("Failed to change scene to %s. Error: %s" % [scene_path, error])

func warp_to_scene(scene_path: String) -> void:
    if not ResourceLoader.exists(scene_path):
        push_error("Warp destination does not exist: %s" % scene_path)
        return

    var existing_transition: Node = get_node_or_null("WarpTransition")
    if existing_transition != null:
        return

    var transition_instance: Node = WARP_TRANSITION_SCENE.instantiate()
    add_child(transition_instance)

    var transition: WarpTransition = transition_instance as WarpTransition
    if transition == null:
        push_error("Warp transition scene root must use WarpTransition.")
        transition_instance.queue_free()
        return

    transition.begin_warp(scene_path)

func reload_current_scene() -> void:
    get_tree().reload_current_scene()
