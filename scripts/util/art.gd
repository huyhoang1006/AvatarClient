class_name Art
## Helper load sheet PNG (strip ngang, frame vuông) export từ Aseprite.


static func tex(path: String) -> Texture2D:
	return load(path) as Texture2D


## Lấy 1 frame trong strip ngang; fw = bề rộng frame (mặc định = chiều cao sheet)
static func frame(path: String, idx: int, fw: int = 0) -> Texture2D:
	var t := tex(path)
	if t == null:
		push_error("Art.frame: khong load duoc " + path)
		return null
	var w := fw if fw > 0 else int(t.get_height())
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2(idx * w, 0, w, t.get_height())
	return at


## Tạo SpriteFrames từ strip ngang. anims = {"ten_anim": [from, to, fps, loop]}
static func frames(path: String, anims: Dictionary, fw: int = 0) -> SpriteFrames:
	var t := tex(path)
	var sf := SpriteFrames.new()
	if t == null:
		push_error("Art.frames: khong load duoc " + path)
		return sf
	var w := fw if fw > 0 else int(t.get_height())
	for anim_name in anims:
		var a: Array = anims[anim_name]
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, a[2])
		sf.set_animation_loop(anim_name, a[3])
		for i in range(a[0], a[1] + 1):
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(i * w, 0, w, t.get_height())
			sf.add_frame(anim_name, at)
	return sf


## Sprite2D tiện dụng, gốc đặt ở chân (bottom-center) để y-sort đẹp
static func sprite(texture: Texture2D, pos: Vector2, parent: Node, feet_origin := true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.position = pos
	if feet_origin and texture:
		s.offset = Vector2(0, -texture.get_height() / 2.0)
	parent.add_child(s)
	return s
