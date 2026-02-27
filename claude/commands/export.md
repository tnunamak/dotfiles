Export the current conversation to a text file.

Usage:
/export           - Export with interactive selection
/export --simple  - Export current conversation (simple mode)

---

#!/bin/bash
python3 ~/.local/bin/claude_conversation_export.py "$@"
