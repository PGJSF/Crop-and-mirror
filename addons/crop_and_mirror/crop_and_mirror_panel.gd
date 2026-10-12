@tool
extends HBoxContainer
## Bottom-panel tool: select a corner region of a source image, mirror it into
## a symmetrical dialog box texture with a live preview, and export it as PNG.

signal panel_title_changed(title: String)

enum Language { ENGLISH, KOREAN }

const LANGUAGE_METADATA_SECTION: String = "crop_and_mirror"
## Each entry contains English followed by Korean, matching the language item ids.
const TEXT: Dictionary[String, Array] = {
	"panel_title": ["Crop & Mirror", "크롭 & 미러"],
	"language": ["Language", "언어"],
	"load": ["Load Image", "이미지 불러오기"],
	"select_all": ["Select All", "전체 선택"],
	"reset_zoom": ["Reset Zoom", "줌 리셋"],
	"no_image": ["No Image", "이미지 없음"],
	"hint": ["Left-drag: select region · Red handles: resize edges · Right-drag: pan · Wheel: zoom", "좌클릭 드래그: 영역 선택 · 빨간 핸들: 변 조절 · 우클릭 드래그: 이동 · 휠: 확대/축소"],
	"region": ["Region", "영역"],
	"width": ["Width", "너비"],
	"height": ["Height", "높이"],
	"mirror_h": ["Mirror H", "수평 대칭"],
	"mirror_v": ["Mirror V", "수직 대칭"],
	"source_corner": ["Source Corner", "원본 모서리"],
	"top_left": ["Top-Left", "좌상단"],
	"top_right": ["Top-Right", "우상단"],
	"bottom_left": ["Bottom-Left", "좌하단"],
	"bottom_right": ["Bottom-Right", "우하단"],
	"overlap_h": ["Horizontal Overlap", "좌우 겹침"],
	"overlap_v": ["Vertical Overlap", "상하 겹침"],
	"output_size_empty": ["Output Size: -", "출력 크기: -"],
	"output_size": ["Output Size: %d x %d", "출력 크기: %d x %d"],
	"preview": ["Live Preview", "미리보기"],
	"output_path": ["Output Path", "출력 경로"],
	"export": ["Export Dialog Box Image", "대화창 이미지 생성"],
	"open_title": ["Open an Image", "이미지 열기"],
	"open": ["Open", "열기"],
	"cancel": ["Cancel", "취소"],
	"images": ["Images", "이미지"],
	"load_failed": ["Unable to load image: %s", "이미지를 불러올 수 없습니다: %s"],
	"source_loaded": ["Source loaded: %s", "소스 로드됨: %s"],
	"no_selection": ["No image selected", "선택된 이미지가 없습니다"],
	"empty_selection": ["Selection is empty", "선택 영역이 비어 있습니다"],
	"empty_path": ["Output path is empty", "출력 경로가 비어 있습니다"],
	"overwrite": ["Output path matches the source (overwrite prevented)", "출력 경로가 원본과 같습니다 (덮어쓰기 방지)"],
	"save_failed": ["Save failed (%s): %s", "저장 실패 (%s): %s"],
	"export_complete": ["Export complete: %s (%d x %d)", "생성 완료: %s (%d x %d)"],
}
const LABEL_TEXT_KEYS: Dictionary[NodePath, String] = {
	^"LeftColumn/HintLabel": "hint",
	^"MiddleColumn/RegionLabel": "region",
	^"MiddleColumn/RegionGrid/WLabel": "width",
	^"MiddleColumn/RegionGrid/HLabel": "height",
	^"MiddleColumn/CornerLabel": "source_corner",
	^"MiddleColumn/OverlapHRow/OverlapHLabel": "overlap_h",
	^"MiddleColumn/OverlapVRow/OverlapVLabel": "overlap_v",
	^"RightColumn/PreviewLabel": "preview",
	^"RightColumn/DestLabel": "output_path",
}
const CORNER_TEXT_KEYS: PackedStringArray = ["top_left", "top_right", "bottom_left", "bottom_right"]

## Source corner options. Values must match the OptionButton item ids in the scene.
enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }
## Left-button interaction state on the canvas.
enum DragMode { MODE_IDLE, MODE_SELECTING_NEW, MODE_DRAG_TOP, MODE_DRAG_BOTTOM, MODE_DRAG_LEFT, MODE_DRAG_RIGHT }

const ZOOM_STEP: float = 1.15
const ZOOM_MIN: float = 0.1
const ZOOM_MAX: float = 16.0
const CANVAS_BG_COLOR: Color = Color(0.12, 0.12, 0.12)
const CHECKER_CELL: int = 8
const CHECKER_COLOR_A: Color = Color(0.20, 0.20, 0.20)
const CHECKER_COLOR_B: Color = Color(0.28, 0.28, 0.28)
const SELECTION_COLOR: Color = Color.YELLOW
const SELECTION_WIDTH: float = 2.0
const HANDLE_RADIUS: float = 5.0
const HANDLE_HIT_DISTANCE: float = 8.0
const HANDLE_COLOR: Color = Color.RED
const HANDLE_OUTLINE_COLOR: Color = Color.WHITE
const HANDLE_OUTLINE_WIDTH: float = 1.0
const STATUS_OK_COLOR: Color = Color(0.55, 1.0, 0.55)
const STATUS_ERROR_COLOR: Color = Color(1.0, 0.45, 0.45)
## Image extensions accepted by both the file dialog and FileSystem dock drops.
const IMAGE_EXTENSIONS: PackedStringArray = ["png", "webp", "jpg", "jpeg", "bmp", "svg"]

# --- Left column: source & canvas ---
@onready var load_button: Button = %LoadButton
@onready var select_all_button: Button = %SelectAllButton
@onready var reset_zoom_button: Button = %ResetZoomButton
@onready var zoom_label: Label = %ZoomLabel
@onready var source_info_label: Label = %SourceInfoLabel
@onready var language_option: OptionButton = %LanguageOption
@onready var canvas: Control = %Canvas
# --- Middle column: region & settings ---
@onready var x_spin: SpinBox = %XSpin
@onready var y_spin: SpinBox = %YSpin
@onready var w_spin: SpinBox = %WSpin
@onready var h_spin: SpinBox = %HSpin
@onready var mirror_h_check: CheckBox = %MirrorHCheck
@onready var mirror_v_check: CheckBox = %MirrorVCheck
@onready var corner_option: OptionButton = %CornerOption
@onready var overlap_h_spin: SpinBox = %OverlapHSpin
@onready var overlap_v_spin: SpinBox = %OverlapVSpin
@onready var output_size_label: Label = %OutputSizeLabel
# --- Right column: preview & export ---
@onready var preview_bg: Control = %PreviewBg
@onready var preview_rect: TextureRect = %PreviewRect
@onready var dest_path_edit: LineEdit = %DestPathEdit
@onready var export_button: Button = %ExportButton
@onready var status_label: Label = %StatusLabel
@onready var file_dialog: FileDialog = %FileDialog

var source_path: String = ""
var source_image: Image = null
var source_texture: ImageTexture = null
## Current selection in source-image pixel coordinates.
var region: Rect2i = Rect2i()
var output_image: Image = null
## Canvas view transform: screen = pan_offset + texture_pos * zoom.
var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO

var _preview_texture: ImageTexture = null
var _checker_texture: ImageTexture = null
var _drag_mode: DragMode = DragMode.MODE_IDLE
var _panning: bool = false
var _drag_origin: Vector2i = Vector2i.ZERO
## Coalesces preview rebuilds to at most one per frame during fast drags.
var _preview_pending: bool = false
## Guards against feedback loops while spinboxes are written programmatically.
var _syncing_spins: bool = false
var _language: int = Language.ENGLISH
var _status_key: String = ""
var _status_args: Array = []


func _ready() -> void:
	_checker_texture = _make_checker_texture()

	load_button.pressed.connect(_on_load_pressed)
	select_all_button.pressed.connect(_select_all)
	reset_zoom_button.pressed.connect(_reset_view)
	file_dialog.file_selected.connect(_load_source)

	canvas.draw.connect(_on_canvas_draw)
	canvas.gui_input.connect(_on_canvas_gui_input)
	preview_bg.draw.connect(_on_preview_bg_draw)

	# Canvas and preview stop mouse events, so forward drops from them to the panel handlers.
	canvas.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)
	preview_bg.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)

	for spin: SpinBox in [x_spin, y_spin, w_spin, h_spin]:
		spin.value_changed.connect(_on_region_spin_changed)
	mirror_h_check.toggled.connect(_on_setting_changed.unbind(1))
	mirror_v_check.toggled.connect(_on_setting_changed.unbind(1))
	corner_option.item_selected.connect(_on_setting_changed.unbind(1))
	overlap_h_spin.value_changed.connect(_on_setting_changed.unbind(1))
	overlap_v_spin.value_changed.connect(_on_setting_changed.unbind(1))
	_update_overlap_controls()

	export_button.pressed.connect(_on_export_pressed)
	language_option.item_selected.connect(_on_language_selected)
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if Engine.is_editor_hint():
		var settings: EditorSettings = EditorInterface.get_editor_settings()
		_language = clampi(int(settings.get_project_metadata(LANGUAGE_METADATA_SECTION, "language", Language.ENGLISH)), Language.ENGLISH, Language.KOREAN)
	_apply_language()


func _text(key: String) -> String:
	return TEXT[key][_language]


func get_panel_title() -> String:
	return _text("panel_title")


func _on_language_selected(index: int) -> void:
	_language = language_option.get_item_id(index)
	_apply_language()
	if Engine.is_editor_hint():
		var settings: EditorSettings = EditorInterface.get_editor_settings()
		settings.set_project_metadata(LANGUAGE_METADATA_SECTION, "language", _language)


## Refreshes text without changing the source, selection, zoom, or generated image.
func _apply_language() -> void:
	language_option.select(_language)
	language_option.tooltip_text = _text("language")
	load_button.text = _text("load")
	select_all_button.text = _text("select_all")
	reset_zoom_button.text = _text("reset_zoom")
	mirror_h_check.text = _text("mirror_h")
	mirror_v_check.text = _text("mirror_v")
	export_button.text = _text("export")
	for path: NodePath in LABEL_TEXT_KEYS:
		var label: Label = get_node(path) as Label
		label.text = _text(LABEL_TEXT_KEYS[path])
	for index: int in range(CORNER_TEXT_KEYS.size()):
		corner_option.set_item_text(index, _text(CORNER_TEXT_KEYS[index]))
	if source_image == null:
		source_info_label.text = _text("no_image")
	file_dialog.title = _text("open_title")
	file_dialog.ok_button_text = _text("open")
	file_dialog.get_cancel_button().text = _text("cancel")
	var image_patterns: PackedStringArray = []
	for extension: String in IMAGE_EXTENSIONS:
		image_patterns.append("*." + extension)
	file_dialog.filters = PackedStringArray([", ".join(image_patterns) + " ; " + _text("images")])
	_update_output_size_label()
	_refresh_status_text()
	panel_title_changed.emit(get_panel_title())


func _update_output_size_label() -> void:
	if output_image == null:
		output_size_label.text = _text("output_size_empty")
	else:
		output_size_label.text = _text("output_size") % [output_image.get_width(), output_image.get_height()]


#region Drag & drop (FileSystem dock)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var path: String = _get_first_dropped_file(data)
	return not path.is_empty() and IMAGE_EXTENSIONS.has(path.get_extension().to_lower())


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	_load_source(_get_first_dropped_file(data))


## Returns the first path of an editor "files" drag payload, or "" if the payload is not one.
static func _get_first_dropped_file(data: Variant) -> String:
	if not data is Dictionary:
		return ""
	var dict: Dictionary = data
	if dict.get("type", "") != "files":
		return ""
	var files: Variant = dict.get("files", [])
	# The FileSystem dock sends a PackedStringArray; accept a plain Array too.
	if (files is PackedStringArray or files is Array) and not files.is_empty():
		return String(files[0])
	return ""

#endregion


#region Source loading

func _on_load_pressed() -> void:
	file_dialog.popup_centered_ratio(0.6)


func _load_source(path: String) -> void:
	var img: Image = _load_image(path)
	if img == null:
		_set_status("load_failed", true, [path])
		return

	source_path = path
	source_image = img
	source_texture = ImageTexture.create_from_image(img)
	source_info_label.text = "%s  (%d x %d)" % [path.get_file(), img.get_width(), img.get_height()]
	dest_path_edit.text = "%s/%s_full.png" % [path.get_base_dir(), path.get_file().get_basename()]

	# Spinbox ranges follow the image bounds.
	x_spin.max_value = img.get_width() - 1
	y_spin.max_value = img.get_height() - 1
	w_spin.max_value = img.get_width()
	h_spin.max_value = img.get_height()

	_reset_view()
	# Default selection: top-left quarter of the image.
	_set_region(Rect2i(0, 0, maxi(1, floori(img.get_width() / 2.0)), maxi(1, floori(img.get_height() / 2.0))))
	_set_status("source_loaded", false, [path])


## Loads raw image data. Prefers the source file on disk; falls back to the imported texture.
static func _load_image(path: String) -> Image:
	var img: Image = null
	if FileAccess.file_exists(path):
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null and ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			img = tex.get_image()
	if img == null or img.is_empty():
		return null
	# Imported textures may be VRAM-compressed or mipmapped; get_region/blit_rect need raw single-level data.
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	return img

#endregion


#region Selection (canvas <-> spinboxes)

func _select_all() -> void:
	if source_image == null:
		_set_status("no_selection", true)
		return
	_set_region(Rect2i(Vector2i.ZERO, source_image.get_size()))


## Single entry point for selection changes: clamps, syncs spinboxes, redraws, and schedules a preview rebuild.
func _set_region(rect: Rect2i) -> void:
	if source_image == null:
		return
	var img_size: Vector2i = source_image.get_size()
	var pos: Vector2i = rect.position.clamp(Vector2i.ZERO, img_size - Vector2i.ONE)
	var size: Vector2i = rect.size.clamp(Vector2i.ONE, img_size - pos)
	region = Rect2i(pos, size)

	_syncing_spins = true
	x_spin.value = region.position.x
	y_spin.value = region.position.y
	w_spin.value = region.size.x
	h_spin.value = region.size.y
	_syncing_spins = false

	canvas.queue_redraw()
	_request_preview()


func _on_region_spin_changed(_value: float) -> void:
	if _syncing_spins:
		return
	_set_region(Rect2i(int(x_spin.value), int(y_spin.value), int(w_spin.value), int(h_spin.value)))

#endregion


#region Canvas (zoom / pan / select)

func _on_canvas_gui_input(event: InputEvent) -> void:
	# No image: swallow nothing, do nothing.
	if source_image == null:
		return

	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null:
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_zoom_at(mb.position, zoom * ZOOM_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_zoom_at(mb.position, zoom / ZOOM_STEP)
			MOUSE_BUTTON_RIGHT:
				_panning = mb.pressed
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_begin_left_drag(mb.position)
				else:
					_drag_mode = DragMode.MODE_IDLE
					_update_hover_cursor(mb.position)
			_:
				return
		canvas.accept_event()
		return

	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm == null:
		return
	if _panning:
		pan_offset += mm.relative
		canvas.queue_redraw()
		canvas.accept_event()
		return
	match _drag_mode:
		DragMode.MODE_IDLE:
			_update_hover_cursor(mm.position)
		DragMode.MODE_SELECTING_NEW:
			var current: Vector2i = _screen_to_pixel(mm.position)
			var top_left: Vector2i = _drag_origin.min(current)
			var bottom_right: Vector2i = _drag_origin.max(current)
			# Inclusive of both corner pixels.
			_set_region(Rect2i(top_left, bottom_right - top_left + Vector2i.ONE))
			canvas.accept_event()
		_:
			_drag_edge(mm.position)
			canvas.accept_event()


## Left press: grab an edge handle if one is under the cursor, otherwise start a new selection.
func _begin_left_drag(screen_pos: Vector2) -> void:
	var handle_mode: DragMode = _hit_test_handle(screen_pos)
	if handle_mode != DragMode.MODE_IDLE:
		_drag_mode = handle_mode
		return
	_drag_mode = DragMode.MODE_SELECTING_NEW
	_drag_origin = _screen_to_pixel(screen_pos)
	_set_region(Rect2i(_drag_origin, Vector2i.ONE))


## Moves only the edge targeted by the current drag mode; the opposite edge stays fixed.
func _drag_edge(screen_pos: Vector2) -> void:
	if source_image == null or not region.has_area():
		return
	# Edges lie on pixel boundaries, so round to the nearest boundary.
	var tex_pos: Vector2 = (screen_pos - pan_offset) / zoom
	var edge_x: int = roundi(tex_pos.x)
	var edge_y: int = roundi(tex_pos.y)
	var img_size: Vector2i = source_image.get_size()
	var left: int = region.position.x
	var top: int = region.position.y
	var right: int = region.end.x
	var bottom: int = region.end.y
	match _drag_mode:
		DragMode.MODE_DRAG_TOP:
			top = clampi(edge_y, 0, bottom - 1)
		DragMode.MODE_DRAG_BOTTOM:
			bottom = clampi(edge_y, top + 1, img_size.y)
		DragMode.MODE_DRAG_LEFT:
			left = clampi(edge_x, 0, right - 1)
		DragMode.MODE_DRAG_RIGHT:
			right = clampi(edge_x, left + 1, img_size.x)
		_:
			return
	_set_region(Rect2i(left, top, right - left, bottom - top))


## Screen-space handle centers at the midpoint of each selection edge, keyed by drag mode.
func _get_handle_positions() -> Dictionary[DragMode, Vector2]:
	var handles: Dictionary[DragMode, Vector2] = {}
	if source_image == null or not region.has_area():
		return handles
	var r: Rect2 = _region_to_screen()
	handles[DragMode.MODE_DRAG_TOP] = Vector2(r.position.x + r.size.x * 0.5, r.position.y)
	handles[DragMode.MODE_DRAG_BOTTOM] = Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y)
	handles[DragMode.MODE_DRAG_LEFT] = Vector2(r.position.x, r.position.y + r.size.y * 0.5)
	handles[DragMode.MODE_DRAG_RIGHT] = Vector2(r.position.x + r.size.x, r.position.y + r.size.y * 0.5)
	return handles


## Returns the drag mode of the nearest handle within HANDLE_HIT_DISTANCE, or MODE_IDLE.
func _hit_test_handle(screen_pos: Vector2) -> DragMode:
	var best_mode: DragMode = DragMode.MODE_IDLE
	var best_dist: float = HANDLE_HIT_DISTANCE
	var handles: Dictionary[DragMode, Vector2] = _get_handle_positions()
	for mode: DragMode in handles:
		var dist: float = screen_pos.distance_to(handles[mode])
		if dist <= best_dist:
			best_dist = dist
			best_mode = mode
	return best_mode


func _update_hover_cursor(screen_pos: Vector2) -> void:
	var shape: Control.CursorShape = Control.CURSOR_ARROW
	match _hit_test_handle(screen_pos):
		DragMode.MODE_DRAG_TOP, DragMode.MODE_DRAG_BOTTOM:
			shape = Control.CURSOR_VSIZE
		DragMode.MODE_DRAG_LEFT, DragMode.MODE_DRAG_RIGHT:
			shape = Control.CURSOR_HSIZE
	canvas.mouse_default_cursor_shape = shape


func _region_to_screen() -> Rect2:
	return Rect2(pan_offset + Vector2(region.position) * zoom, Vector2(region.size) * zoom)


## Zooms to [param new_zoom] keeping the texture point under [param anchor] fixed on screen.
func _zoom_at(anchor: Vector2, new_zoom: float) -> void:
	var old_zoom: float = zoom
	zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(zoom, old_zoom):
		return
	pan_offset = anchor - ((anchor - pan_offset) / old_zoom) * zoom
	_update_zoom_label()
	canvas.queue_redraw()


func _reset_view() -> void:
	zoom = 1.0
	pan_offset = Vector2.ZERO
	_update_zoom_label()
	canvas.queue_redraw()


func _update_zoom_label() -> void:
	zoom_label.text = "%d%%" % roundi(zoom * 100.0)


## Converts a canvas-local screen position to a clamped source pixel coordinate.
func _screen_to_pixel(screen_pos: Vector2) -> Vector2i:
	var tex_pos: Vector2 = (screen_pos - pan_offset) / zoom
	var pixel: Vector2i = Vector2i(floori(tex_pos.x), floori(tex_pos.y))
	return pixel.clamp(Vector2i.ZERO, source_image.get_size() - Vector2i.ONE)


func _on_canvas_draw() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), CANVAS_BG_COLOR)
	if source_texture == null:
		return
	var tex_rect: Rect2 = Rect2(pan_offset, Vector2(source_texture.get_size()) * zoom)
	canvas.draw_texture_rect(_checker_texture, tex_rect, true)
	canvas.draw_texture_rect(source_texture, tex_rect, false)
	if not region.has_area():
		return
	canvas.draw_rect(_region_to_screen(), SELECTION_COLOR, false, SELECTION_WIDTH)
	var handles: Dictionary[DragMode, Vector2] = _get_handle_positions()
	for mode: DragMode in handles:
		canvas.draw_circle(handles[mode], HANDLE_RADIUS, HANDLE_COLOR)
		canvas.draw_circle(handles[mode], HANDLE_RADIUS, HANDLE_OUTLINE_COLOR, false, HANDLE_OUTLINE_WIDTH, true)

#endregion


#region Preview & composition

func _on_setting_changed() -> void:
	_update_overlap_controls()
	_request_preview()


func _update_overlap_controls() -> void:
	overlap_h_spin.editable = mirror_h_check.button_pressed
	overlap_v_spin.editable = mirror_v_check.button_pressed


## Schedules one preview rebuild at the end of the frame, coalescing bursts of drag/spin events.
func _request_preview() -> void:
	if _preview_pending:
		return
	_preview_pending = true
	_update_preview.call_deferred()


## Rebuilds the composite image from the current region and settings, then refreshes the preview.
func _update_preview() -> void:
	_preview_pending = false
	if source_image == null or not region.has_area():
		output_image = null
		_preview_texture = null
		preview_rect.texture = null
		_update_output_size_label()
		return

	var sub_img: Image = source_image.get_region(region)
	output_image = compose_symmetrical(
		sub_img,
		corner_option.get_selected_id(),
		mirror_h_check.button_pressed,
		mirror_v_check.button_pressed,
		int(overlap_h_spin.value),
		int(overlap_v_spin.value)
	)

	# Reuse the GPU texture while the size is unchanged (cheap updates during drag).
	if _preview_texture != null and _preview_texture.get_size() == Vector2(output_image.get_size()) \
			and _preview_texture.get_format() == output_image.get_format():
		_preview_texture.update(output_image)
	else:
		_preview_texture = ImageTexture.create_from_image(output_image)
		preview_rect.texture = _preview_texture
	_update_output_size_label()


## Normalizes [param sub_img] so it represents the top-left corner, then mirrors it
## horizontally and/or vertically. [param overlap_h] and [param overlap_v] independently
## control the pixels shared at the horizontal and vertical mirror seams.
static func compose_symmetrical(sub_img: Image, corner: int, mirror_h: bool, mirror_v: bool, overlap_h: int, overlap_v: int) -> Image:
	# 1) Corner normalization: canonicalize to Top-Left.
	var top_left: Image = sub_img.duplicate() as Image
	if corner == Corner.TOP_RIGHT or corner == Corner.BOTTOM_RIGHT:
		top_left.flip_x()
	if corner == Corner.BOTTOM_LEFT or corner == Corner.BOTTOM_RIGHT:
		top_left.flip_y()

	# 2) Output dimensions. Overlap is clamped so each mirror still adds at least 1px.
	var w: int = top_left.get_width()
	var h: int = top_left.get_height()
	var overlap_x: int = clampi(overlap_h, 0, w - 1) if mirror_h else 0
	var overlap_y: int = clampi(overlap_v, 0, h - 1) if mirror_v else 0
	var out_w: int = (w * 2 - overlap_x) if mirror_h else w
	var out_h: int = (h * 2 - overlap_y) if mirror_v else h
	var out_img: Image = Image.create_empty(out_w, out_h, false, top_left.get_format())
	var src_rect: Rect2i = Rect2i(0, 0, w, h)

	# 3) Quadrant blits. Later blits overwrite the shared seam pixels.
	out_img.blit_rect(top_left, src_rect, Vector2i.ZERO)
	if mirror_h:
		var top_right: Image = top_left.duplicate() as Image
		top_right.flip_x()
		out_img.blit_rect(top_right, src_rect, Vector2i(w - overlap_x, 0))
	if mirror_v:
		var bottom_left: Image = top_left.duplicate() as Image
		bottom_left.flip_y()
		out_img.blit_rect(bottom_left, src_rect, Vector2i(0, h - overlap_y))
	if mirror_h and mirror_v:
		var bottom_right: Image = top_left.duplicate() as Image
		bottom_right.flip_x()
		bottom_right.flip_y()
		out_img.blit_rect(bottom_right, src_rect, Vector2i(w - overlap_x, h - overlap_y))
	return out_img


func _on_preview_bg_draw() -> void:
	preview_bg.draw_texture_rect(_checker_texture, Rect2(Vector2.ZERO, preview_bg.size), true)


static func _make_checker_texture() -> ImageTexture:
	var size: int = CHECKER_CELL * 2
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	img.fill(CHECKER_COLOR_A)
	img.fill_rect(Rect2i(CHECKER_CELL, 0, CHECKER_CELL, CHECKER_CELL), CHECKER_COLOR_B)
	img.fill_rect(Rect2i(0, CHECKER_CELL, CHECKER_CELL, CHECKER_CELL), CHECKER_COLOR_B)
	return ImageTexture.create_from_image(img)

#endregion


#region Export

func _on_export_pressed() -> void:
	if source_image == null:
		_set_status("no_selection", true)
		return
	_update_preview()
	if output_image == null:
		_set_status("empty_selection", true)
		return

	var dest_path: String = dest_path_edit.text.strip_edges()
	if dest_path.is_empty():
		_set_status("empty_path", true)
		return
	if dest_path.get_extension().to_lower() != "png":
		dest_path += ".png"
		dest_path_edit.text = dest_path
	if dest_path == source_path:
		_set_status("overwrite", true)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest_path.get_base_dir()))
	var err: Error = output_image.save_png(dest_path)
	if err != OK:
		_set_status("save_failed", true, [error_string(err), dest_path])
		return

	_refresh_filesystem(dest_path)
	_set_status("export_complete", false, [dest_path, output_image.get_width(), output_image.get_height()])


static func _refresh_filesystem(dest_path: String) -> void:
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if FileAccess.file_exists(dest_path + ".import"):
		fs.reimport_files(PackedStringArray([dest_path]))
	else:
		# New file: not tracked by the editor yet, so a scan is required to import it.
		fs.scan()

#endregion


func _set_status(key: String, is_error: bool, args: Array = []) -> void:
	_status_key = key
	_status_args = args.duplicate()
	_refresh_status_text()
	status_label.add_theme_color_override("font_color", STATUS_ERROR_COLOR if is_error else STATUS_OK_COLOR)


func _refresh_status_text() -> void:
	if _status_key.is_empty():
		status_label.text = ""
	else:
		var format_text: String = _text(_status_key)
		status_label.text = format_text if _status_args.is_empty() else format_text % _status_args
