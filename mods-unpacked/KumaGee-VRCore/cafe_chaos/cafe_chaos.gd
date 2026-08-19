class_name CafeChaos
extends BaseGame

## Café Chaos — cooperative coffee-shop management game.

signal shift_timer_updated(time_remaining: float)
signal drink_served(order: Order)
signal drink_failed(order: Order)

const SHIFT_DURATION := 180.0

var order_manager: OrderManager
var current_cup: Cup
var shift_time_remaining: float = SHIFT_DURATION
var _shift_running: bool = false

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	order_manager = OrderManager.new()
	add_child(order_manager)
	order_manager.order_served.connect(_on_order_served)
	order_manager.order_failed.connect(_on_order_failed)

func _on_prepare_phase() -> void:
	current_cup = Cup.new()
	shift_time_remaining = SHIFT_DURATION

func _on_game_phase() -> void:
	_shift_running = true
	order_manager.start()

func _process(delta: float) -> void:
	if not _shift_running:
		return
	shift_time_remaining -= delta
	shift_timer_updated.emit(shift_time_remaining)
	if shift_time_remaining <= 0.0:
		shift_time_remaining = 0.0
		_end_shift()

func _end_shift() -> void:
	_shift_running = false
	order_manager.stop()
	var title := "Shift Over!"
	finish_game(title, func(lb): lb.set_entries([
		{"name": "Served", "score": order_manager.orders_served},
		{"name": "Failed", "score": order_manager.orders_failed},
	]))

func add_component_to_cup(component: RecipeData.Component) -> void:
	if current_cup == null or current_cup.is_ruined:
		return
	current_cup.add_component(component)

func serve_cup() -> bool:
	if current_cup == null or current_cup.is_ruined or current_cup.is_empty():
		return false
	var served_order := order_manager.try_serve(current_cup.get_components())
	if served_order != null:
		drink_served.emit(served_order)
		_reset_cup()
		return true
	_reset_cup()
	return false

func trash_cup() -> void:
	_reset_cup()

func _reset_cup() -> void:
	current_cup = Cup.new()

func _on_order_served(order: Order) -> void:
	drink_served.emit(order)

func _on_order_failed(order: Order) -> void:
	drink_failed.emit(order)

func _debug_advance() -> void:
	if is_game_phase:
		_end_shift()
	else:
		super._debug_advance()
