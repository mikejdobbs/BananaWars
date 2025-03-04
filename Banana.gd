extends Area2D
@export var speed = 3000
@export var damage = 1

#var target = null
#var velocity = null
var player = 0 #the player who threw me


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	if (transform != null ):
		position += transform.x * speed * delta
		
	#if (target != null and velocity != null): 
		#position += velocity * delta	


func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()

#func fire(m_target):
	#target = m_target
	#look_at(target)
	#velocity = position.direction_to(target) * speed

func _on_area_entered(area): #responds to area2d
	queue_free()


func _on_body_entered(body): #walls
	
	#if body.is_in_group("players"):
	#	body.hit()

	queue_free()

#func acquire_target(m_target):
	#target = m_target
	#look_at(target)
	#return false
