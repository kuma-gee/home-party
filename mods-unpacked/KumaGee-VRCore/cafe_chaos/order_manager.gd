class_name OrderManager
extends Node

## Manages the order queue: spawning, ticking patience, tracking results.

signal order_added(order: Order)
signal order_served(order: Order)
signal order_failed(order: Order)

const SPAWN_INTERVAL := 8.0
const MAX_QUEUE_SIZE := 3

var active_orders: Array[Order] = []
var orders_served: int = 0
var orders_failed: int = 0
var _spawn_timer: float = 0.0
var _running: bool = false

func start() -> void:
	_running = true
	_spawn_timer = 0.0
	_spawn_order()

func stop() -> void:
	_running = false

func _process(delta: float) -> void:
	if not _running:
		return
	_tick_orders(delta)
	_tick_spawner(delta)

func _tick_orders(delta: float) -> void:
	for order in active_orders:
		if order.state == Order.State.WAITING:
			order.tick(delta)
			if order.state == Order.State.FAILED:
				orders_failed += 1
				order_failed.emit(order)
	_cleanup_completed()

func _tick_spawner(delta: float) -> void:
	if active_orders.size() >= MAX_QUEUE_SIZE:
		return
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_order()

func _spawn_order() -> void:
	var recipe_id := "espresso"
	var order := Order.new(recipe_id)
	active_orders.append(order)
	order_added.emit(order)

func _cleanup_completed() -> void:
	active_orders = active_orders.filter(func(o: Order) -> bool:
		return o.state == Order.State.WAITING
	)

func try_serve(cup_components: Array[RecipeData.Component]) -> Order:
	for order in active_orders:
		if order.state != Order.State.WAITING:
			continue
		if _cup_matches_order(cup_components, order):
			order.serve()
			orders_served += 1
			order_served.emit(order)
			return order
	return null

func _cup_matches_order(components: Array[RecipeData.Component], order: Order) -> bool:
	var required: Array = order.recipe.get("components", [])
	if components.size() != required.size():
		return false
	var comp_copy := components.duplicate()
	for req in required:
		var idx := comp_copy.find(req)
		if idx == -1:
			return false
		comp_copy.remove_at(idx)
	return true

func get_active_count() -> int:
	return active_orders.size()
