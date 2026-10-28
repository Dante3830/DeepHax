# LAS MEJORAS QUE SE PUEDEN COMPRAR EN EL SHOP
extends Node

const ITEMS = {
	"get_out": {
		"name": "¡Fuera de mi vista!",
		"description": "25% de probabilidad de que una ventana se cierre sola al aparecer.",
		"price": 80
	},
	"extra_time": {
		"name": "Tiempo extra",
		"description": "+10 segundos al empezar la próxima fase. Se usa una sola vez.",
		"price": 60
	},
	"protect_combo": {
		"name": "Proteger combo",
		"description": "Anula la próxima vez que se rompa tu combo. Se usa una sola vez.",
		"price": 75
	},
	"long_cord": {
		"name": "Alargue",
		"description": "+15 segundos al empezar cada fase.",
		"price": 145
	},
	"auto_comp": {
		"name": "Autocompletar v1",
		"description": "25% de probabilidad de poder autocompletar líneas con una sola tecla.",
		"price": 100
	},
	"greedy": {
		"name": "Codicioso",
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
