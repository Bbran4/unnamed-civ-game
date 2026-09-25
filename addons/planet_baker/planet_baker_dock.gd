@tool
extends VBoxContainer

## Planet Texture Baker dock behaviour.
##
## Lets the user pick a PlanetData resource, bake its surface and cloud
## textures with PlanetTextureBaker, and assign the results back onto that
## resource. All UI is defined in planet_baker_dock.tscn; this script only
## wires behaviour.

const OUTPUT_DIRECTORY: String = "res://assets/textures/planets/generated/"

@onready var planet_picker: EditorResourcePicker = $PlanetPicker
@onready var output_path_label: Label = $OutputPathLabel
@onready var bake_button: Button = $BakeButton
@onready var status_label: Label = $StatusLabel

var selected_planet_data: PlanetData


func _ready() -> void:
	planet_picker.resource_changed.connect(_on_planet_resource_changed)
	bake_button.pressed.connect(_on_bake_button_pressed)
	_on_planet_resource_changed(null)


func _on_planet_resource_changed(resource: Resource) -> void:
	selected_planet_data = resource as PlanetData
	bake_button.disabled = selected_planet_data == null
	status_label.text = ""

	if selected_planet_data == null:
		output_path_label.text = "Select a PlanetData resource to bake."
		return

	output_path_label.text = "Output: %s" % _get_output_path(selected_planet_data)


func _on_bake_button_pressed() -> void:
	if selected_planet_data == null:
		return

	status_label.text = "Baking surface and clouds..."

	var surface_output_path: String = _get_surface_output_path(selected_planet_data)
	var cloud_output_path: String = _get_cloud_output_path(selected_planet_data)

	var surface_texture: Texture2D = PlanetTextureBaker.bake_and_save(
		selected_planet_data,
		surface_output_path
	)

	if surface_texture == null:
		status_label.text = "Surface bake failed. Check the Output panel."
		return

	var cloud_texture: Texture2D = PlanetTextureBaker.bake_clouds_and_save(
		selected_planet_data,
		cloud_output_path
	)

	if cloud_texture == null:
		status_label.text = "Surface baked, but cloud bake failed. Check the Output panel."
		return

	selected_planet_data.surface_texture = surface_texture
	selected_planet_data.cloud_texture = cloud_texture

	var save_error: Error = ResourceSaver.save(selected_planet_data)

	if save_error != OK:
		status_label.text = "Baked the textures, but could not save the PlanetData resource."
		return

	status_label.text = (
		"Baked and assigned:\nSurface: %s\nClouds: %s"
		% [surface_output_path, cloud_output_path]
	)


func _get_surface_output_path(planet_data: PlanetData) -> String:
	return OUTPUT_DIRECTORY + String(planet_data.id) + "_surface.png"


func _get_cloud_output_path(planet_data: PlanetData) -> String:
	return OUTPUT_DIRECTORY + String(planet_data.id) + "_clouds.png"


func _get_output_path(planet_data: PlanetData) -> String:
	return _get_surface_output_path(planet_data)
