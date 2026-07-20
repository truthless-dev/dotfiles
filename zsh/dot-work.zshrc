export RADAR_DIR="$HOME/Documents/radar"


todays_radar_dir() {
    today="$(date '+%a' | tr '[:upper:]' '[:lower:]')"
        printf "%s/current/%s" "$RADAR_DIR" "$today"
}


todays_radar_list() {
    dir="$(todays_radar_dir)"
    issues="$(find -E "$dir" -maxdepth 1 -type d -regex '.*/[0-9]+' | awk -F/ '{print $NF}' | sort -n)"
    echo "$issues"
}


cd_todays_radar_dir() {
    dir="$(todays_radar_dir)"
    mkdir -p "$dir" && cd "$dir"
}


bug() {
    cd_todays_radar_dir
    latest="$(todays_radar_list | tail -1)"
    echo "Latest: $latest"
    next=$(( latest + 1))
    echo "Next: $next"
    mkdir "$next"
    if [[ ! -d "$next" ]]; then
        echo "Failed to create directory $next"
        exit 1
    fi
    find "$latest" -type f -iname 'sysdiagnose*.tar.gz' -exec cp {} "$next" \;
    cd "$next"
    touch desc.txt title.txt && open -e desc.txt title.txt
}
