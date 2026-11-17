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
- Execute shell commands (with approval)
- Read and write files (with approval)
- Search the web
- Maintain persistent memory across sessions

## Tools Available

- `file_read` - Read text files
- `file_write` - Write files
- `file_list` - List directory contents
- `terminal` - Execute shell commands
- `web_search` - Search the internet
- `web_extract` - Extract content from URLs
- `memory` - Persistent user/agent memory

## Usage

Just chat naturally. The agent will use tools as needed.
