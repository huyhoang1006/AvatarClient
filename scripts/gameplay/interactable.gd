extends Area2D
class_name Interactable
## Điểm tương tác: đứng gần sẽ hiện vòng auto-lock + đổi icon nút trung tâm.
## Scene connect signal `activated` để xử lý.

signal activated

var icon_index := 1        # frame icon trên nút trung tâm
var radius := 46.0
var enabled := true


static func make(pos: Vector2, r: float, icon: int, parent: Node) -> Interactable:
	var it := Interactable.new()
	it.position = pos
	it.radius = r
	it.icon_index = icon
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = r
	cs.shape = sh
	it.add_child(cs)
	it.monitoring = false
	it.monitorable = false
	parent.add_child(it)
	# QUAN TRỌNG: đăng ký vào danh sách dò mục tiêu của scene
	if parent is SceneBase:
		(parent as SceneBase).interactables.append(it)
	return it


func activate() -> void:
	if enabled:
		activated.emit()
