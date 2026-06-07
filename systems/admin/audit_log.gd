extends RefCounted
class_name AuditLog

## Local, in-memory, append-only audit trail placeholder for future moderation and
## admin tooling. There is no database and no network — entries live only for the
## current session. A real implementation would forward these to an authoritative
## server and durable store. Nothing in gameplay writes to this yet.

var _entries: Array[Dictionary] = []

## Append an audit entry. `kind` is a short category (e.g. "report",
## "admin_action", "build_change"); `payload` is the associated data Dictionary.
func append(kind: String, payload: Dictionary) -> Dictionary:
	var entry: Dictionary = {
		"id": _entries.size() + 1,
		"kind": kind,
		"payload": payload,
		"logged_at": Time.get_unix_time_from_system(),
	}
	_entries.append(entry)
	return entry

func record_report(report: Dictionary) -> Dictionary:
	return append("report", report)

func record_admin_action(action: Dictionary) -> Dictionary:
	return append("admin_action", action)

func get_entries() -> Array[Dictionary]:
	return _entries.duplicate(true)

func get_entries_of_kind(kind: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for entry in _entries:
		if String(entry.get("kind", "")) == kind:
			results.append(entry.duplicate(true))
	return results

func size() -> int:
	return _entries.size()

func clear() -> void:
	_entries.clear()
