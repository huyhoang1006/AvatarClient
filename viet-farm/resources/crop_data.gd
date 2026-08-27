class_name CropData
extends Resource

## Dữ liệu cho 1 loại cây trồng (ngô, cà chua, ...).
## Thêm giống mới = tạo 1 file .tres, KHÔNG cần viết script.

@export var display_name: String = ""

@export_group("Sprite")
## Frame bắt đầu trong sprite sheet. Ngô = 0, cà chua = 6.
## Sprite dùng frame = frame_offset + trạng thái sinh trưởng (0..5).
@export_range(0, 64) var frame_offset: int = 0

@export_group("Sinh trưởng")
## Số ngày ĐƯỢC TƯỚI cần để chín. Ngày không tưới không được tính.
@export_range(1, 365) var days_until_harvest: int = 7
## Scene sinh ra khi cây chín (corn_harvest.tscn, tomato_harvest.tscn)
@export var harvest_scene: PackedScene

@export_group("Tưới nước")
## 0 = tưới 1 lần mỗi ngày (nước cạn khi sang ngày mới) — mặc định, giống Stardew.
## > 0 = nước bay hơi sau ngần này GIỜ TRONG GAME.
## Ở nhịp chuẩn (1 ngày = 16,8 phút thật):
##   8 giờ  ≈ tưới lại mỗi 5,6 phút thật
##   12 giờ ≈ tưới lại mỗi 8,4 phút thật
@export_range(0, 48) var watering_interval_hours: int = 0
## Hiệu ứng nước bắn ra kéo dài bao lâu (giây thật)
@export_range(0.5, 10.0, 0.5) var watering_effect_duration: float = 5.0
