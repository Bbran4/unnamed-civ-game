extends Node2D

var collected_evidence: Array[String] = []
var spoken_to_witness: bool = false
var questioned_suspect: bool = false
var case_resolved: bool = false

@onready var case_status: Label = $CaseStatus

func _ready() -> void:
	_update_case_status()

func register_evidence(evidence_id: String, evidence_description: String) -> void:
	if collected_evidence.has(evidence_id):
		return

	collected_evidence.append(evidence_id)
	_show_message("Evidence collected: %s" % evidence_description)
	_check_case_progress()

func register_witness() -> void:
	if spoken_to_witness:
		return

	spoken_to_witness = true
	_show_message("Witness: I heard an argument near the docking bay before the lights went out.")
	_check_case_progress()

func register_suspect() -> void:
	if questioned_suspect:
		return

	questioned_suspect = true
	_show_message("Suspect: I never entered the docking bay. You cannot prove otherwise.")
	_check_case_progress()

func _check_case_progress() -> void:
	if collected_evidence.size() >= 3 and spoken_to_witness and questioned_suspect:
		case_resolved = true
		_show_message("CASE COMPLETE: The evidence places the suspect at the docking bay.")
	_update_case_status()

func _show_message(message: String) -> void:
	case_status.text = message

func _update_case_status() -> void:
	case_status.text = "Evidence: %d/3 | Witness: %s | Suspect: %s" % [
		collected_evidence.size(),
		"Spoken to" if spoken_to_witness else "Unknown",
		"Questioned" if questioned_suspect else "Unknown"
	]
