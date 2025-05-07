# Sea 🌊

**Search the web from your terminal**  
[![Fish Shell Version](https://img.shields.io/badge/fish-v3.3.1+-blue.svg)](https://fishshell.com)
![Version](https://img.shields.io/badge/version-1.0.0-green)

A Fish shell function that lets you search the web using multiple search engines, ChatGPT, and direct URLs with browser integration. Features intelligent history and interactive fuzzy finding with fzf.

## Features

- 🔍 Multiple search engines via "!bangs" (Google, Wikipedia, YouTube, GitHub, etc.)
- 🤖 ChatGPT integration (!ch bang)
- 📜 Search history persistence
- 🔎 Interactive fuzzy search with fzf
- 🗺️ Direct URL opening
- 🚀 Brave browser integration (default)
- 🗑️ History management (Ctrl-D to delete entries)

USAGE

Use `sea !ch docker` to search ChatGPT
# Default search (Brave)
sea my awesome query

# Search with a bang
sea !g fish shell scripting
sea !yt epic cat videos
sea !gh fisher

# Open a URL directly
sea example.com
sea https://fishshell.com

# Interactive menu (no arguments)
sea

Press Ctrl-D on a history item in the fzf menu to delete it.
Available Bangs:

`!g - Google`
`!w - Wikipedia`
`!yt - YouTube`
`!gh - GitHub`
`!ddg - DuckDuckGo`
`!def - Define (DDG)`
`!map - Google Maps`
`!lucky - Brave (I'm Feeling Lucky)`

Configuration
The search history is stored in ~/.config/fish/sea_history.txt.
Bangs and the default search engine are configured within the sea.fish function itself.



## Installation

1. Ensure you have:
   - [Fish Shell](https://fishshell.com) v3.3.1+
   - [fzf](https://github.com/junegunn/fzf)
   - Brave browser (or modify code for your preferred browser)

2. Save the function to your Fish config:
   ```bash
   curl -Lo ~/.config/fish/functions/sea.fish https://raw.githubusercontent.com/samunderSingh12/sea/main/sea.fish
