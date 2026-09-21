class_name WarpTransition
extends CanvasLayer

@export var warp_duration: float = 1.6

var destination_scene: String = ""
var transition_running: bool = false

@onready var overlay: ColorRect = $Overlay
@onready var streaks: Control = $Overlay/Streaks

func _ready() -> void:
    layer = 100
    overlay.modulate.a = 0.0
    for child: Node in streaks.get_children():
        var streak: ColorRect = child as ColorRect
        if streak != null:
            streak.modulate.a = 0.0

func begin_warp(scene_path: String) -> void:
    if transition_running:
        return

    destination_scene = scene_path
    transition_running = true
    await play_warp()

func play_warp() -> void:
    var fade_in_tween: Tween = create_tween()
    fade_in_tween.set_parallel(true)
    fade_in_tween.tween_property(overlay, "modulate:a", 1.0, 0.25)

    for child: Node in streaks.get_children():
        var streak: ColorRect = child as ColorRect
        if streak == null:
            continue

        var target_alpha: float = 0.35
        var target_width: float = 900.0
        streak.modulate.a = 0.0
        streak.size.x = 120.0
        streak.position.x = 640.0 - (streak.size.x * 0.5)

        var streak_tween: Tween = create_tween()
        streak_tween.set_parallel(true)
        streak_tween.tween_property(streak, "modulate:a", target_alpha, 0.25)
        streak_tween.tween_property(streak, "size:x", target_width, warp_duration * 0.55)
        streak_tween.tween_property(
            streak,
            "position:x",
            640.0 - (target_width * 0.5),
            warp_duration * 0.55
        )

    await get_tree().create_timer(warp_duration * 0.55).timeout
    SceneManager.change_scene(destination_scene)

    await get_tree().create_timer(0.25).timeout

    var fade_out_tween: Tween = create_tween()
    fade_out_tween.set_parallel(true)
    fade_out_tween.tween_property(overlay, "modulate:a", 0.0, 0.45)

    for child: Node in streaks.get_children():
        var streak: ColorRect = child as ColorRect
        if streak == null:
            continue
        fade_out_tween.tween_property(streak, "modulate:a", 0.0, 0.45)

    await fade_out_tween.finished
    queue_free()
