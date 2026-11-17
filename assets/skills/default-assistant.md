---
name: "default-assistant"
description: "Default Hermes assistant skill"
category: "general"
version: "1.0.0"
---

# Default Assistant

This is the default skill loaded by Hermes Agent.

## Capabilities

- Chat with users in natural language
- Search the web (via web_search tool)
- Maintain persistent memory across sessions

## Tools Available

- `web_search` - Search the internet
- `memory_read` - Read user profile or agent memory
- `memory_write` - Write to persistent memory
- `skills_list` - List available skills
- `skills_view` - View a specific skill

## Usage

Just chat naturally. The agent will use tools as needed.
You can ask about yourself, ask the agent to remember things,
or search for information on the web.