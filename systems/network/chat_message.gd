extends RefCounted
class_name ChatMessage

## Chat message sanitation shared by client and server. PROTOTYPE chat: no
## moderation, no filtering, no admin commands, no history persistence — the
## server only enforces shape (trimmed, single-line, length-capped) and always
## uses ITS identity state for the sender name, never a client-sent name.

const MAX_LENGTH := 200

static func sanitize(text: String) -> String:
	var clean: String = text.strip_edges()
	# Single line only: collapse any newlines/tabs a creative client sends.
	clean = clean.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while clean.contains("  "):
		clean = clean.replace("  ", " ")
	return clean.substr(0, MAX_LENGTH)

static func is_sendable(text: String) -> bool:
	return not sanitize(text).is_empty()
