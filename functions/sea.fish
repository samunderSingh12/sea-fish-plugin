function sea
    # --- Version ---
    set -l _SEA_VERSION "1.0.0" # Incremented for this change

    # --- Configuration ---
    set -l history_file ~/.config/fish/sea_history.txt
    # Create directory and history file if they don't exist
    mkdir -p (dirname "$history_file")
    touch "$history_file"

    # Bang command definitions: "bang_prefix" "URL_template (use %s for query)" "Description for fzf"
    set -l bangs \
        "g"   "https://www.google.com/search?q=%s" "Google" \
        "w"   "https://en.wikipedia.org/w/index.php?search=%s" "Wikipedia" \
        "yt"  "https://www.youtube.com/results?search_query=%s" "YouTube" \
        "gh"  "https://github.com/search?q=%s" "GitHub" \
        "ddg" "https://duckduckgo.com/?q=%s" "DuckDuckGo" \
        "def" "https://duckduckgo.com/?q=!def+%s" "Define (DDG)" \
        "map" "https://www.google.com/maps/search/%s" "Google Maps" \
        "lucky" "https://search.brave.com/search?q=%s&I=1" "Brave (I'm Feeling Lucky)" \
        "ch"  "https://chat.openai.com/?q=%s" "ChatGPT" # <-- ADDED CHATGPT BANG
        # Brave's &I=1 seems to be their "I'm Feeling Lucky" equivalent

    # Default search engine if no bang is used
    set -l default_search_url_template "https://search.brave.com/search?q=%s"
    # --- End Configuration ---

    # --- Version Check ---
    if contains -- "-v" $argv; or contains -- "--version" $argv
        echo "sea version $_SEA_VERSION"
        return 0
    end

    # --- Help Section ---
    if contains -- "-h" $argv; or contains -- "--help" $argv
        echo "Sea - Search the web from your terminal (primarily with Brave)"
        echo "Version: $_SEA_VERSION"
        echo ""
        echo "Usage:"
        echo "  sea [!bang] <search query>"
        echo "  sea <url>"
        echo "  sea                         (Opens fzf to browse history and bangs)"
        echo "  sea -h | --help             (Show this help message)"
        echo "  sea -v | --version          (Show version information)"
        echo ""
        echo "Description:"
        echo "  Performs a web search. Defaults to Brave Search unless a !bang or direct URL is specified."
        echo "  If no arguments are provided, an interactive fzf menu allows you to:"
        echo "    - Search through your previous queries."
        echo "    - Select a !bang prefix and then enter a query."
        echo "    - Delete history entries using Ctrl-D."
        echo ""
        echo "Bangs:"
        echo "  Use a '!' followed by a short prefix to target a specific site."
        echo "  Example: sea !yt funny cat videos"
        echo ""
        echo "  Available Bangs:"
        for i in (seq 1 3 (count $bangs))
            set -l bang_prefix $bangs[$i]
            set -l bang_desc $bangs[(math $i + 2)]
            printf "    !%-5s - %s\n" "$bang_prefix" "$bang_desc"
        end
        echo ""
        echo "Direct URL Opening:"
        echo "  If the first argument looks like a URL (e.g., example.com, http://...), it will be opened directly."
        echo "  Example: sea fishshell.com"
        echo ""
        echo "Configuration:"
        echo "  History file: $history_file"
        echo "Note: For !ch (ChatGPT), you need to be logged into chat.openai.com in your browser." # <-- Added note
        return 0
    end

    set -l query_string ""
    set -l full_args (string join " " $argv)

    if test -z "$argv"
        set -l fzf_options_list
        for i in (seq 1 3 (count $bangs))
            set -l bang_prefix $bangs[$i]
            set -l bang_desc $bangs[(math $i + 2)]
            set -a fzf_options_list "!$bang_prefix - $bang_desc"
        end

        set -l fzf_selection_and_key (
            begin
                for item in $fzf_options_list
                    echo "$item"
                end
                echo "--- HISTORY ---"
                if test -s "$history_file"
                    tac "$history_file"
                end
            end | fzf \
                --height 50% \
                --layout=reverse \
                --border \
                --info=inline \
                --prompt="Search History / Bangs > " \
                --header="Ctrl-D to delete history entry" \
                --expect=ctrl-d
        )

        if test -z "$fzf_selection_and_key"
            echo "No query selected."
            return 1
        end

        set -l key_pressed (echo "$fzf_selection_and_key" | head -n 1)
        set -l selected_item (echo "$fzf_selection_and_key" | tail -n +2)

        if test -z "$selected_item"
            echo "No query selected."
            return 1
        end

        if string match -q "ctrl-d" -- "$key_pressed"
            if string match -q -- "--- HISTORY ---" "$selected_item"
                echo "Cannot delete separator."
                return 1
            end
            if string match -q -- "!*" "$selected_item"
                echo "Cannot delete bang command template."
                return 1
            end

            set -l temp_history_file (mktemp)
            set -l escaped_selected_item (string escape -- "$selected_item")
            grep -Fxv -- "$escaped_selected_item" "$history_file" > "$temp_history_file"
            command mv "$temp_history_file" "$history_file"
            echo "Deleted '$selected_item' from history."
            return 0
        end

        if string match -q -- "!* - *" "$selected_item"
            set -l bang_prefix_from_fzf (string split " " -- "$selected_item")[1]
            set bang_prefix_from_fzf (string sub -s 2 -- "$bang_prefix_from_fzf")
            read -P "Search with !$bang_prefix_from_fzf: " query_string
            if test -z "$query_string"; return 1; end
            set full_args "!$bang_prefix_from_fzf $query_string"
        else
            set query_string "$selected_item"
            set full_args "$query_string"
        end
    else
        set query_string (string join " " $argv)
        set full_args "$query_string"
    end

    if test -z "$query_string"
        echo "Usage: sea [!bang] <query>"
        echo "   or: sea (with no arguments to browse history/bangs)"
        echo "   For help, use: sea -h"
        echo "   For version, use: sea -v"
        return 1
    end

    set -l search_url ""
    set -l actual_query "$query_string"

    set -l first_arg (string split " " -- "$query_string")[1]

    if string match -r '^https?://|^[a-zA-Z0-9.-]+\.(com|org|net|io|dev|app|co|me|sh|xyz|tech|ai)(/.*)?$' -- "$first_arg"
        if test (count (string split " " -- "$query_string")) -eq 1 -o (string match -q "$first_arg" "$query_string")
            if not string match -qr '^https?://' -- "$first_arg"
                set first_arg "http://$first_arg"
            end
            set search_url "$first_arg"
            echo "Opening URL: $search_url"
        end
    end

    if test -z "$search_url"
        if string match -qr '^![a-zA-Z0-9]+' -- "$first_arg"
            set -l bang_cmd (string sub -s 2 -- "$first_arg")
            set -l found_bang false
            for i in (seq 1 3 (count $bangs))
                if test "$bangs[$i]" = "$bang_cmd"
                    set -l url_template $bangs[(math $i + 1)]
                    set actual_query (string join " " -- (string split " " -- "$query_string")[2..-1])
                    if test -z "$actual_query" -a "$bang_cmd" != "lucky" # lucky and ch can be without query (ch just opens the page)
                        if test "$bang_cmd" = "ch" # For ChatGPT, opening without query is fine
                            set actual_query "" # No query, just open ChatGPT
                        else
                            read -P "Query for !$bang_cmd: " actual_query
                            if test -z "$actual_query"; return 1; end
                        end
                        set full_args "!$bang_cmd $actual_query"
                    end
                    # Ensure actual_query is not empty for replacement, unless it's specifically allowed to be
                    if test -z "$actual_query" -a "$bang_cmd" != "ch" -a "$bang_cmd" != "lucky"
                        echo "Query cannot be empty for !$bang_cmd"
                        return 1
                    end
                    set -l encoded_actual_query (string replace -a ' ' '+' -- "$actual_query")
                    set search_url (string replace '%s' "$encoded_actual_query" -- "$url_template")
                    set found_bang true
                    break
                end
            end
            if not $found_bang
                echo "Unknown bang: $first_arg. Using default search."
                set actual_query "$query_string"
            end
        end
    end

    if test -z "$search_url"
        set actual_query "$query_string"
        set -l encoded_actual_query (string replace -a ' ' '+' -- "$actual_query")
        set search_url (string replace '%s' "$encoded_actual_query" -- "$default_search_url_template")
    end

    # --- Save to History ---
    if string match -q -- "*search?q=*" "$search_url" \
        or string match -q -- "*wikipedia.org*" "$search_url" \
        or string match -q -- "*youtube.com*" "$search_url" \
        or string match -q -- "*github.com*" "$search_url" \
        or string match -q -- "*duckduckgo.com*" "$search_url" \
        or string match -q -- "*chat.openai.com*" "$search_url" # <-- ADDED condition for ChatGPT history

        if not test -z "$full_args" # Ensure we have something to save
            set -l temp_history_file (mktemp)
            echo "$full_args" > "$temp_history_file"
            set -l escaped_full_args (string escape -- "$full_args")
            grep -Fxv -- "$escaped_full_args" "$history_file" >> "$temp_history_file" 2>/dev/null
            command mv "$temp_history_file" "$history_file"
        end
    end

    # --- Launch Browser ---
    echo "Opening: $search_url"
    brave-browser "$search_url" >/dev/null 2>&1 & disown
end
