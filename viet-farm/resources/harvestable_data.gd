class_name HarvestableData
extends Resource

## Dữ liệu cho 1 loại vật thể chặt/đập được (cây to, cây nhỏ, đá...).
## Tạo file .tres mới cho mỗi loại — KHÔNG cần viết thêm script.

@export var display_name: String = ""

@export_group("Rơi ra")
## Scene sinh ra khi bị phá huỷ (log.tscn, stone.tscn...)
@export var drop_scene: PackedScene
## Số lượng rơi ra
@export_range(1, 10) var drop_count: int = 1
## Bán kính rải ngẫu nhiên quanh vị trí gốc (0 = rơi đúng 1 chỗ)
@export_range(0.0, 32.0) var drop_spread: float = 0.0

@export_group("Rung khi bị đánh")
@export_range(0.0, 2.0, 0.05) var shake_intensity: float = 0.5
@export_range(0.1, 3.0, 0.1) var shake_duration: float = 1.0
