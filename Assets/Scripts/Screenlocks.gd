extends Node

# Tracks which instance currently holds the lock
var current_lock_holder: Node = null

# Called by an instance to try and acquire the lock
func request_lock(requestor: Node) -> bool:
	if current_lock_holder == null:
		current_lock_holder = requestor
		return true # Lock granted
	return false # Already locked by someone else

# Called by the instance when it finishes the action
func release_lock(requestor: Node):
	if current_lock_holder == requestor:
		current_lock_holder = null
