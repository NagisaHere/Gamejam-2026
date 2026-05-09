extends Node2D

@export var left_hand_states: Array[Texture2D]
@export var right_hand_states: Array[Texture2D]

@onready var left_hand := $LeftHand
@onready var right_hand := $RightHand
@onready var animation_player := $AnimationPlayer
@onready var typing_game = $"../typing"


var typing_states := [
	[0, 0],
	[1, 0],
	[2, 0],
	[3, 0],
	[4, 0],
	[5, 0],
	[5, 1],
	[5, 2],
	[5, 3],
	[5, 4],
	[5, 5],
]


func _ready():
	typing_game.fingers_changed.connect(_on_fingers_changed)
	animation_player.play("typing_loop")

func _on_fingers_changed(value):
	print("remaining fingers:", value)
	show_typing_state(10 - value)


func show_state(left_index: int, right_index: int):

	if left_index >= 0 and left_index < left_hand_states.size():
		left_hand.texture = left_hand_states[left_index]

	if right_index >= 0 and right_index < right_hand_states.size():
		right_hand.texture = right_hand_states[right_index]


func show_typing_state(state_index: int):

	if state_index < 0 or state_index >= typing_states.size():
		return

	var state = typing_states[state_index]

	show_state(state[0], state[1])
