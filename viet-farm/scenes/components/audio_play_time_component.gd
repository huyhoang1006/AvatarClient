extends Timer

@export var audio_stream_player_2D: AudioStreamPlayer2D
@export var min_wait_time: int = 1
@export var max_wait_time: int = 10


func _ready() -> void:
	randomize_wait_time()


func _on_timeout() -> void:
	audio_stream_player_2D.play()
	randomize_wait_time()


func randomize_wait_time() -> void:
	wait_time = randi_range(min_wait_time, max_wait_time)
