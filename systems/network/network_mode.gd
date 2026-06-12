extends RefCounted
class_name NetworkMode

## Session mode ids for the NetworkSession autoload. OFFLINE is and remains the
## default — the game boots fully offline and only leaves OFFLINE when the
## player explicitly connects (F8 panel) or the dedicated server scene starts.

const OFFLINE := "offline"
const CLIENT := "client"
const SERVER := "server"
