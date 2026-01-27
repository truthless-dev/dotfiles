# Unset or set to 0 to opt out of auto-venv.
export PYTHON_AUTO_VENV=1


# Determine whether we're currently standing in the root, or a child
# of the root, of a Python project (defined as a directory containing
# a `.venv` directory. The env var `PYTHON_PROJECT_ROOT_DIRECTORY`
# is set to the project's root if one exists, or to an empty string
# if not.
python-get-project-root-directory() {
    local root="$PWD"
    while [[ "$root" != "/" ]]; do
        if [[ -d "$root/.venv" ]]; then
            export PYTHON_PROJECT_ROOT_DIRECTORY="$root"
            return 0
        fi
        root=$(dirname "$root")
    done
    export PYTHON_PROJECT_ROOT_DIRECTORY=""
    return 1
}


# (De)activate Python environments depending on the current working
# directory and venv state.
python-auto-venv() {
    if [[ -z "$PYTHON_AUTO_VENV" || "$PYTHON_AUTO_VENV" = "0" ]]; then
        return 1
    fi
    if ! python-get-project-root-directory; then
        if [[ -n "$VIRTUAL_ENV" ]]; then
            # Not in a Py project but a venv is active.
            deactivate
        fi
    else
        if [[ -z "$VIRTUAL_ENV" ]]; then
            # In a Py project but no venv is active.
            source "$PYTHON_PROJECT_ROOT_DIRECTORY/.venv/bin/activate"
        else
            if [[ "$VIRTUAL_ENV" != "$PYTHON_PROJECT_ROOT_DIRECTORY/.venv" ]]; then
                # In a different Py project than the one whose venv is active.
                deactivate
                source "$PYTHON_PROJECT_ROOT_DIRECTORY/.venv/bin/activate"
            fi
        fi
    fi
}


autoload -Uz add-zsh-hook
add-zsh-hook chpwd python-auto-venv
