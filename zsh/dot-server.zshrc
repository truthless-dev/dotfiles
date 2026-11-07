export PATH="$PATH:$HOME/.docker/bin"

export TTS_VOICE=Daniel
export TTS_RATE=350


speak() {
    if [[ ! $# -eq 1 ]]; then
        print -u2 "Usage: $0 <text>"
        return 1
    fi
    (say --voice "${TTS_VOICE:-Daniel}" --rate "${TTS_RATE:-350}" "$1" &)
}


cpu() {
    local usage
    usage=$(top -l 1 | grep "CPU usage" | awk '{print $3 + $5 "%"}')
    printf "%s\n" "$usage"
}


vol() {
    local silent value message
        silent=0
        value=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -s|--silent)
                silent=1
                shift
                ;;
            -v|--value)
                if [[ -z "$2" ]]; then
                    print -u2 "ERROR: \`$1\` requires a value"
                    return 1
                fi
                if [[ ! "$2" =~ "^[0-9]+$" ]]; then
                    print -u2 "ERROR: \`$1\` requires a numeric value"
                    return 1
                fi
                if [[ "$2" -lt 0 || "$2" -gt 100 ]]; then
                    print -u2 "ERROR: \`$1\` must be between 0 and 100"
                    return 1
                fi
                value="$2"
                shift 2
                ;;
            -h|--help)
                cat <<EOF
Usage: vol [options]

Set or display the system's current output volume.

Options:
  -s, --silent   Do not speak the result out loud
  -v, --value    Set the volume to this percentage
  -h, --help     Show this help and exit
EOF
                return 0
                ;;
            *)
                print -u2 "ERROR: Unknown option: \`$1\`"
                print -u2 "Try \`$0 --help\` for usage"
                return 1
                ;;
            esac
            done

    if [[ -z "$value" ]]; then
        message=$(osascript -e "output volume of (get volume settings)")
    else
        message=$(osascript -e "set volume output volume $value" -e "output volume of (get volume settings)")
    fi

    message="Volume: ${message}%"
    if [[ "$silent" -eq 1 ]]; then
        printf "%s\n" "$message"
    else
        speak "$message"
    fi
}
