extends Area2D

@export var coins_required: int = 25
@export_file("*.tscn") var next_level: String = "res://scenes/game_level_2.tscn"


# only react to the player
func _on_body_entered(body: Node2D) -> void:
	if not "coins" in body:
		return

	if body.coins >= coins_required:
		get_tree().change_scene_to_file.call_deferred(next_level)
	else:
		var missing = coins_required - body.coins
		print("portal locked! Need", missing, "more coins")
