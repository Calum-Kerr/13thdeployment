extends Control
class_name LoadingScreen

# Node references
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var loading_text: Label = $VBoxContainer/LoadingText
@onready var tip_text: Label = $VBoxContainer/TipText
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Loading tips
const LOADING_TIPS = [
	"Death is not the end, but a chance to learn.",
	"Observe enemy patterns before engaging.",
	"Stamina management is key to survival.",
	"Timing your dodges is more important than spamming them.",
	"Parrying can turn the tide of battle, but requires precise timing.",
	"Don't be greedy with your attacks.",
	"Explore thoroughly to find hidden items and shortcuts.",
	"Upgrading your weapon often yields better results than leveling up.",
	"Messages from other players can provide valuable hints.",
	"Some walls may be illusory. Strike them to reveal hidden paths.",
	"Bloodstains show how other players died. Learn from their mistakes.",
	"Phantoms can be summoned to help with difficult areas.",
	"Bosses often have weaknesses that can be exploited.",
	"Conserve healing items for when you truly need them.",
	"The environment can be as deadly as the enemies."
]

# Variables
var target_scene: String = ""
var progress: float = 0.0
var loading_thread: Thread
var is_loading: bool = false
var load_error: bool = false

func _ready():
	# Hide by default
	visible = false
	
	# Initialize progress bar
	progress_bar.value = 0

func start_loading(scene_path: String):
	# Store target scene
	target_scene = scene_path
	
	# Show loading screen
	visible = true
	
	# Reset progress
	progress = 0.0
	progress_bar.value = 0
	
	# Set loading text
	loading_text.text = "Loading..."
	
	# Set random tip
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var tip_index = rng.randi_range(0, LOADING_TIPS.size() - 1)
	tip_text.text = "TIP: " + LOADING_TIPS[tip_index]
	
	# Play appear animation if available
	if animation_player and animation_player.has_animation("appear"):
		animation_player.play("appear")
	
	# Start loading in a thread
	loading_thread = Thread.new()
	is_loading = true
	load_error = false
	loading_thread.start(_load_scene_thread)

func _load_scene_thread():
	# Create a ResourceLoader
	var loader = ResourceLoader.load_threaded_request(target_scene)
	
	# Wait until loading is complete
	while true:
		var status = ResourceLoader.load_threaded_get_status(target_scene)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Update progress
				progress = ResourceLoader.load_threaded_get_status(target_scene, [])
				# Continue loading
				OS.delay_msec(50)
			ResourceLoader.THREAD_LOAD_LOADED:
				# Loading complete
				var scene = ResourceLoader.load_threaded_get(target_scene)
				call_deferred("_loading_complete", scene)
				return
			ResourceLoader.THREAD_LOAD_FAILED:
				# Loading failed
				call_deferred("_loading_failed")
				return
			_:
				# Unknown status
				call_deferred("_loading_failed")
				return

func _process(delta):
	if is_loading:
		# Update progress bar
		progress_bar.value = progress * 100
		
		# Update loading text based on progress
		if progress < 0.3:
			loading_text.text = "Loading."
		elif progress < 0.6:
			loading_text.text = "Loading.."
		else:
			loading_text.text = "Loading..."

func _loading_complete(scene):
	# Update progress bar to 100%
	progress_bar.value = 100
	
	# Update loading text
	loading_text.text = "Loading Complete!"
	
	# Wait a moment for visual feedback
	await get_tree().create_timer(0.5).timeout
	
	# Play disappear animation if available
	if animation_player and animation_player.has_animation("disappear"):
		animation_player.play("disappear")
		await animation_player.animation_finished
	
	# Change scene
	get_tree().change_scene_to_packed(scene)
	
	# Hide loading screen
	visible = false
	
	# Clean up
	is_loading = false
	loading_thread.wait_to_finish()

func _loading_failed():
	# Update loading text
	loading_text.text = "Loading Failed!"
	
	# Set error flag
	load_error = true
	
	# Show error dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Loading Error"
	dialog.dialog_text = "Failed to load scene: " + target_scene
	dialog.get_ok_button().text = "OK"
	add_child(dialog)
	
	# Connect dialog signals
	dialog.confirmed.connect(func():
		# Hide loading screen
		visible = false
		
		# Clean up
		is_loading = false
		loading_thread.wait_to_finish()
		
		# Return to main menu
		if get_node_or_null("/root/UIManager"):
			get_node("/root/UIManager").show_main_menu()
	)
	
	# Show dialog
	dialog.popup_centered() 