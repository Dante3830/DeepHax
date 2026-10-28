# LAS MEJORAS QUE SE PUEDEN COMPRAR EN EL SHOP
extends Node

const ITEMS = {
	"get_out": {
		"name": "¡FUERA DE MI VISTA!",
		"description": "25% de probabilidad de que una ventana se cierre sola al aparecer.",
		"price": 80
	},
	"extra_time": {
		"name": "TIEMPO EXTRA",
		"description": "+10 segundos al empezar la próxima fase. Se usa una sola vez.",
		"price": 60
	},
	"protect_combo": {
		"name": "PROTEGER COMBO",
		"description": "Anula la próxima vez que se rompa tu combo. Se usa una sola vez.",
		"price": 75
	},
	"long_cord": {
		"name": "ALARGUE",
		"description": "+15 segundos al empezar cada fase.",
		"price": 160
	},
	"auto_comp": {
		"name": "AUTOCOMPLETAR v1",
		"description": "25% de probabilidad de poder autocompletar líneas con una sola tecla.",
		"price": 100
	},
	"greedy": {
		"name": "CODICIOSO",
		"description": "Duplica las hackoins conseguidas. Pero si fallas, pierdes todo y no sumas más.",
		"price": 130
	}
}

var bought = []

func has(id: String) -> bool:
	return id in bought

func use(id: String) -> bool:
	if !has(id):
		return false
	bought.erase(id)
	return true

func take_time_bonus() -> float:
	var bonus = 0.0
	if has("long_cord"):
		bonus += 15.0
	if use("extra_time"):
		bonus += 10.0
	return bonus
