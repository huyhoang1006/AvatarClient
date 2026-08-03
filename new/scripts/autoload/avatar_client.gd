extends Node

@warning_ignore("unused_signal")
signal login_succeeded(user: Dictionary)
@warning_ignore("unused_signal")
signal login_failed(message: String)

var is_logged_in := false
var current_username := ""

func login(username: String, password: String) -> Dictionary:
	# TODO: thay đoạn giả lập này bằng HTTPRequest gọi API backend thật
	await get_tree().create_timer(0.6).timeout

	if username.is_empty() or password.is_empty():
		return {"ok": false, "message": "Thiếu tài khoản hoặc mật khẩu"}

	is_logged_in = true
	current_username = username
	return {"ok": true, "message": "Đăng nhập thành công"}

func login_with_oauth() -> Dictionary:
	# Chưa có backend hỗ trợ OAuth
	return {"ok": false, "message": "Tính năng đang phát triển"}

func await_ready(_timeout: float = 5.0) -> bool:
	# TODO: thay bằng việc chờ đồng bộ dữ liệu thật từ server
	return true

func logout() -> void:
	is_logged_in = false
	current_username = ""
