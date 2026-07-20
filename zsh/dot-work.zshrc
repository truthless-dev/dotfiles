export RADAR_DIR="$HOME/Documents/radar"

RADAR_BUG_NAME_PATTERN='[0-9]+'


radar-current-dir() {
    printf "%s/current" "$RADAR_DIR"
}


radar-today-dir() {
    local today="$(LC_TIME=C date '+%a' | tr '[:upper:]' '[:lower:]')"
    printf "%s/%s" "$(radar-current-dir)" "$today"
}


bug-list() {
    local dir="$(radar-today-dir)"
    local bugs="$(find -E "$dir" -maxdepth 1 -type d -regex ".*/${RADAR_BUG_NAME_PATTERN}" 2>/dev/null | awk -F/ '{print $NF}' | sort -n)"
    printf '%s\n' "$bugs"
}


bug-latest() {
    bug-list | tail -1
}


cd-radar-today-dir() {
    local dir="$(radar-today-dir)"
    mkdir -p "$dir" && cd "$dir"
}


radar-archive-dir() {
    printf "%s/archive" "$RADAR_DIR"
}


sr-name() {
    local name="Screen Recording $(LC_TIME=C date "+%F at %-I.%M.%S %p")"
    echo -n "$name" | pbcopy
    echo "Copied to clipboard: $name"
}


sysd() {
    local output_dir=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output-dir)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! -d "$2" ]]; then
                    print -u2 "Error: output dir does not exist: $2"
                    return 1
                fi
                output_dir="$2"
                shift 2
                ;;
            -h|--help)
                cat <<"EOF"
Usage: sysd [options]

Capture a macOS sysdiagnose.

Options:
  -o, --output-dir <dir>   Use this directory instead of the latest bug directory
  -h, --help               Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    if [[ -z "$output_dir" ]]; then
        local latest="$(bug-latest)"
        if [[ -z "$latest" ]]; then
            print -u2 "Error: no bugs created yet today — run \`bug\` first, or pass -o/--output-dir"
            return 1
        fi
        output_dir="$(radar-today-dir)/$latest"
    fi

    local previous_diagnose="$(echo -n "$output_dir"/sysdiagnose_*_macOS*(N.om[1]))"
    sudo /usr/bin/sysdiagnose -b -f "$output_dir"
    local current_diagnose="$(echo -n "$output_dir"/sysdiagnose_*_macOS*(N.om[1]))"
    if [[ -z "$current_diagnose" || "$previous_diagnose" == "$current_diagnose" ]]; then
        return 1
    fi

    say -v 'Reed (English (US))' -r 600 'Sysdiagnose finished.'
}


bug-rec() {
    local valid_audio=(system default none)
    local audio=
    local count=0
    local output=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--audio)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                audio="${2:l}"
                if (( ! ${valid_audio[(Ie)$audio]} )); then
                    print -u2 "Error: invalid audio source: $audio"
                    return 1
                fi
                shift 2
                ;;
            -c|--count)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! "$2" =~ "^[0-9]+$" ]]; then
                    print -u2 "Error: \`$1\` requires a number"
                    return 1
                fi
                count=$2
                shift 2
                ;;
            -o|--output)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! -d "${2:A:h}" ]]; then
                    print -u2 "Error: output dir does not exist: ${2:A:h}"
                    return 1
                fi
                if [[ -f "${2:A}" ]]; then
                    print -u2 "Error: output file already exists: ${2:A}"
                    return 1
                fi
                output="${2:A}"
                shift 2
                ;;
            -h|--help)
                cat <<"EOF"
Usage: bug-rec [options]

Capture a screen recording.

Options:
  -a, --audio <source>    Set the audio source (system, default, or none)
  -c, --count <seconds>   Play a countdown before recording
  -o, --output <path>     Write to this file path instead of the default
  -h, --help              Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    if [[ -z "$audio" ]]; then
        audio="${valid_audio[1]}"
    fi
    if [[ -z "$output" ]]; then
        local latest="$(bug-latest)"
        if [[ -z "$latest" ]]; then
            print -u2 "Error: no bugs created yet today — run \`bug\` first, or pass -o/--output"
            return 1
        fi
        output="$(radar-today-dir)/$latest/Screen Recording $(LC_TIME=C date "+%F at %-I.%M.%S %p").mov"
        if [[ -f "${output:A}" ]]; then
            print -u2 "Error: output file already exists: ${output:A}"
            return 1
        fi
    fi

    local args=(-v)
    case "$audio" in
        system) args+=(-A) ;;
        default) args+=(-g) ;;
        none) ;;
    esac

    if (( $count )); then
        local i
        for i in {$count..1}; do
            (afplay "/System/Library/Sounds/Tink.aiff" &>/dev/null &)
            sleep 1
        done
        (afplay "/System/Library/Sounds/Purr.aiff" &>/dev/null &)
    fi
    screencapture $args "$output"
}


bug() {
    local title=""
    local copy_sysdiagnose=1
    local edit=1
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                title="$2"
                shift 2
                ;;
            --no-copy-sysdiagnose)
                copy_sysdiagnose=0
                shift
                ;;
            --no-edit)
                edit=0
                shift
                ;;
            -h|--help)
                cat <<"EOF"
Usage: bug [options]

Create the skeleton for a new bug report.

Options:
  -t, --title <title>     Set the issue's title
  --no-copy-sysdiagnose   Skip copying the previous issue's sysdiagnose archive
  --no-edit               Do not open the title and description in the editor
  -h, --help              Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    cd-radar-today-dir
    local latest="$(bug-latest)"
    if [[ -n "$latest" && ! "$latest" =~ ^${RADAR_BUG_NAME_PATTERN}$ ]]; then
        print -u2 "Error: unexpected bug name '$latest' (expected a number)"
        return 1
    fi
    local next=$(( latest + 1))
    if ! mkdir "$next"; then
        print -u2 "Failed to create directory: $next"
        return 1
    fi
    if [[ "$copy_sysdiagnose" -eq 1 ]]; then
        local copied=$(find "$latest" -type f -iname "sysdiagnose*.tar.gz" -exec cp {} "$next" \; -print 2>/dev/null)
        if [[ -n "$copied" ]]; then
            echo "Copied sysdiagnose from bug $latest"
        fi
    fi
    cd "$next"
    printf "%s" "$title" > title.txt
    printf "Summary:\n\n\n\nSteps to Reproduce:\n1. \n\n\nExpected Results:\n\n\n\nActual Results:\n\n\n\nRegression:\nUnknown." > desc.txt
    if [[ "$edit" -eq 0 ]]; then
        return 0
    fi
    if [[ -n "$RADAR_EDITOR" ]]; then
        "$RADAR_EDITOR" desc.txt title.txt
    else
        open -e desc.txt title.txt
    fi
}


app-vers() {
    local app_name="$1"
    local app_matches=$(find -L /Applications /System/Applications "$HOME/Applications" \
        -maxdepth 2 -iname "${app_name}*.app" -type d 2>/dev/null)
    local app_path=$(echo "$app_matches" | head -1)
    if [[ -z "$app_path" ]]; then
        print -u2 "App not found: $app_name"
        return 1
    fi
    if [[ "$(echo "$app_matches" | wc -l)" -gt 1 ]]; then
        print -u2 "Multiple matches found for $app_name, using: $app_path"
    fi

    local plist="$app_path/Contents/Info"
    local name=$(defaults read "$plist" CFBundleName 2>/dev/null)
    [[ -z "$name" ]] && name=$(defaults read "$plist" CFBundleDisplayName 2>/dev/null)
    [[ -z "$name" ]] && name="$app_name"
    local short_version=$(defaults read "$plist" CFBundleShortVersionString 2>/dev/null)
    local build_version=$(defaults read "$plist" CFBundleVersion 2>/dev/null)
    local macos_build=$(sw_vers -buildVersion)

    local result="$macos_build / $name $short_version ($build_version)"
    echo -n "$result" | pbcopy
    echo "Copied to clipboard: $result"
}


bug-mv() {
    typeset -a sources
    local destination=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--destination)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! -d "$2" ]]; then
                    print -u2 "Error: destination does not exist: $2"
                    return 1
                fi
                destination="$2"
                shift 2
                ;;
            -s|--source)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! -d "$2" ]]; then
                    print -u2 "Error: source does not exist: $2"
                    return 1
                fi
                sources+="$2"
                shift 2
                ;;
            -h|--help)
                cat <<"EOF"
Usage: bug-mv [options]

Collect attachments into a single place.

Options:
  -s, --source <dir>        Add a directory to search (repeatable; default: ~/Downloads)
  -d, --destination <dir>   Move collected files here instead of the latest bug directory
  -h, --help                Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    if [[ -z "$destination" ]]; then
        local latest="$(bug-latest)"
        if [[ -z "$latest" ]]; then
            print -u2 "Error: no bugs created yet today — run \`bug\` first, or pass -d/--destination"
            return 1
        fi
        destination="$(radar-today-dir)/$latest"
    fi
    if [[ "${#sources}" -eq 0 ]]; then
        sources+="$HOME/Downloads"
    fi

    find $sources -maxdepth 1 \
        \( \
            -iname 'sysdiagnose*.tar.gz' \
            -or -iname 'screen*.mov' \
            -or -iname 'screen*.mp4' \
            -or -iname 'screen*.png' \
        \) \
        -exec sh -c 'echo "Collecting $(basename "$1")"' _ {} \; \
        -exec mv {} "$destination" \;
}


bug-cp() {
    local bug_dir bug_num desc esc excluded f fname mode pattern source_dir target_label title
    typeset -a excludes files as_items
    excludes=("title.txt" "desc.txt")
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                if [[ -n "$mode" ]]; then
                    print -u2 "Error: only one of -t/--title, -d/--desc, -a/--attachments may be given"
                    return 1
                fi
                mode="title"
                shift
                ;;
            -d|--desc)
                if [[ -n "$mode" ]]; then
                    print -u2 "Error: only one of -t/--title, -d/--desc, -a/--attachments may be given"
                    return 1
                fi
                mode="desc"
                shift
                ;;
            -a|--attachments)
                if [[ -n "$mode" ]]; then
                    print -u2 "Error: only one of -t/--title, -d/--desc, -a/--attachments may be given"
                    return 1
                fi
                mode="attachments"
                shift
                ;;
            -x|--exclude)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                excludes+="$2"
                shift 2
                ;;
            -b|--bug)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ -n "$source_dir" ]]; then
                    print -u2 "Error: -s/--source cannot be combined with -b/--bug"
                    return 1
                fi
                if [[ ! "$2" =~ ^${RADAR_BUG_NAME_PATTERN}$ ]]; then
                    print -u2 "Error: \`$1\` value must be a bug number"
                    return 1
                fi
                bug_num="$2"
                shift 2
                ;;
            -s|--source)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ -n "$bug_num" ]]; then
                    print -u2 "Error: -s/--source cannot be combined with -b/--bug"
                    return 1
                fi
                if [[ ! -d "$2" ]]; then
                    print -u2 "Error: source directory does not exist: $2"
                    return 1
                fi
                source_dir="$2"
                shift 2
                ;;
            -h|--help)
                cat <<"EOF"
Usage: bug-cp [options]

Copy one part of a bug to the clipboard.

Options:
  -t, --title            Copy the bug's title
  -d, --desc             Copy the bug's description
  -a, --attachments      Copy the bug's attachments as file references
  -x, --exclude <glob>   Exclude matching files from attachments (repeatable; only valid with -a)
  -b, --bug <n>          Operate on this bug number instead of today's latest
  -s, --source <dir>     Operate on this directory instead (relative or absolute; conflicts with -b)
  -h, --help             Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    if [[ -z "$mode" ]]; then
        print -u2 "Error: exactly one of -t/--title, -d/--desc, -a/--attachments is required"
        return 1
    fi
    if [[ "$mode" != "attachments" && "${#excludes}" -gt 2 ]]; then
        print -u2 "Error: -x/--exclude is only valid with -a/--attachments"
        return 1
    fi

    if [[ -n "$source_dir" ]]; then
        bug_dir="${source_dir:A}"
    else
        if [[ -z "$bug_num" ]]; then
            bug_num="$(bug-latest)"
            if [[ -z "$bug_num" ]]; then
                print -u2 "Error: no bugs created yet today — run \`bug\` first, or pass -b/--bug or -s/--source"
                return 1
            fi
        fi
        bug_dir="$(radar-today-dir)/$bug_num"
        if [[ ! -d "$bug_dir" ]]; then
            print -u2 "Error: no such bug: $bug_num"
            return 1
        fi
    fi

    if [[ "$mode" == "title" && ! -f "$bug_dir/title.txt" ]]; then
        print -u2 "Error: title.txt not found in $bug_dir"
        return 1
    fi
    if [[ "$mode" == "desc" && ! -f "$bug_dir/desc.txt" ]]; then
        print -u2 "Error: desc.txt not found in $bug_dir"
        return 1
    fi
    if [[ -n "$source_dir" ]]; then
        target_label="$bug_dir"
    else
        target_label="bug $bug_num"
    fi

    case "$mode" in
        title)
            title="$(<"$bug_dir/title.txt")"
            echo -n "$title" | pbcopy
            echo "Copied to clipboard: $title"
            ;;
        desc)
            desc="$(<"$bug_dir/desc.txt")"
            echo -n "$desc" | pbcopy
            echo "Copied description for $target_label to clipboard"
            ;;
        attachments)
            for f in "$bug_dir"/*(N.); do
                fname="$(basename "$f")"
                excluded=0
                for pattern in "${excludes[@]}"; do
                    if [[ "$fname" == ${~pattern} ]]; then
                        excluded=1
                        break
                    fi
                done
                (( excluded )) && continue
                files+="$f"
            done
            if [[ "${#files}" -eq 0 ]]; then
                print -u2 "Error: no attachments found for $target_label"
                return 1
            fi
            for f in "${files[@]}"; do
                echo "Copying $(basename "$f")"
            done
            for f in "${files[@]}"; do
                esc="${f//\\/\\\\}"
                esc="${esc//\"/\\\"}"
                as_items+="POSIX file \"$esc\" as alias"
            done
            local osa_output osa_status
            osa_output=$(osascript 2>&1 <<APPLESCRIPT
tell application "System Events"
    set previousApp to name of first application process whose frontmost is true
end tell
tell application "Finder"
    activate
    select {${(j:, :)as_items}}
end tell
delay 0.3
try
    tell application "System Events"
        keystroke "c" using command down
    end tell
    delay 0.2
    tell application previousApp to activate
on error errMsg number errNum
    tell application previousApp to activate
    error errMsg number errNum
end try
APPLESCRIPT
)
            osa_status=$?
            if [[ $osa_status -ne 0 ]]; then
                if [[ "$osa_output" == *"not allowed to send keystrokes"* || "$osa_output" == *"not authorized"* ]]; then
                    print -u2 "Error: copying attachments needs Accessibility permission. Grant it to your terminal app in System Settings > Privacy & Security > Accessibility, then try again."
                else
                    print -u2 "Error: failed to copy attachments to clipboard ($osa_output)"
                fi
                return 1
            fi
            echo "Copied ${#files} attachment(s) to clipboard"
            ;;
    esac
}


bug-archive() {
    local force=0
    local name=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                if [[ -z "$2" ]]; then
                    print -u2 "Error: \`$1\` requires a value"
                    return 1
                fi
                if [[ "$2" == */* ]]; then
                    print -u2 "Error: \`$1\` value must not contain '/'"
                    return 1
                fi
                name="$2"
                shift 2
                ;;
            -f|--force)
                force=1
                shift
                ;;
            -h|--help)
                cat <<"EOF"
Usage: bug-archive [options]

Archive the current week's issues.

Options:
  -n, --name <name>   Set the archive directory's name (default: the previous Monday's date)
  -f, --force         Skip the confirmation prompt
  -h, --help          Show this help message and exit
EOF
                return 0
                ;;
            *)
                print -u2 "Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage."
                return 1
                ;;
        esac
    done

    local current_dir="$(radar-current-dir)"
    if [[ ! -d "$current_dir" ]]; then
        echo "Nothing to archive: $current_dir does not exist"
        return 0
    fi

    if [[ -z "$name" ]]; then
        name="$(date -v-$(( $(date '+%u') - 1 ))d '+%Y-%m-%d')"
    fi
    local archive_dir="$(radar-archive-dir)/$name"

    if [[ -e "$archive_dir" ]]; then
        print -u2 "Error: $archive_dir already exists, aborting"
        return 1
    fi

    if [[ "$force" -ne 1 ]]; then
        local reply
        printf "This will permanently delete every file except title.txt/desc.txt under %s,\nthen move it to %s. Proceed? [y/N] " "$current_dir" "$archive_dir"
        read -r reply
        if [[ "$reply" != [yY] ]]; then
            print -u2 "Aborted"
            return 1
        fi
    fi

    local day_dir bug_dir
    for day_dir in "$current_dir"/*(N/); do
        for bug_dir in "$day_dir"/*(N/); do
            [[ "$(basename "$bug_dir")" =~ ^${RADAR_BUG_NAME_PATTERN}$ ]] || continue
            find "$bug_dir" -type f ! -name "title.txt" ! -name "desc.txt" -delete
        done
    done

    if [[ "$PWD" == "$current_dir" || "$PWD" == "$current_dir"/* ]]; then
        cd "$RADAR_DIR" || return 1
        echo "Note: working directory was inside $current_dir, moved to $RADAR_DIR"
    fi

    mkdir -p "$(radar-archive-dir)"
    mv "$current_dir" "$archive_dir"
    echo "Archived bugs to $archive_dir"
}
