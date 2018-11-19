#########################################
#  funky Shell Integration Script  #
#########################################

##### WHAT DOES THIS SCRIPT DO?
# - Source local and global funks on startup.
# - Source local funks everytime the directory changes.
# - Define two wrapper functions, `funky` and `gfunky`.

##### INSTALLATION
# In order to take advantage of the full benefits of funky, this script must
# be sourced directly into your .zshrc file. See the official docs for more
# information:
# 
# https://funky.readthedocs.io/en/latest/installation.html#additional-installation-steps

##### Create temporary funky directory
# ensure running as root
if [ "$EUID" -eq 0 ]; then
    _home_dir=/root
else
    _home_dir="$HOME"
fi

if [[ -n "$XDG_DATA_HOME" ]]; then
    _xdg_data_dir="$XDG_DATA_HOME"/funky
else
    _xdg_data_dir="$_home_dir"/.local/share/funky
fi

[[ -d "$_xdg_data_dir" ]] || mkdir -p "$_xdg_data_dir"

funky_exe="$(which funky)"

##### Function used for sourcing funks
_source_globals() { "${funky_exe}" --verbose --global | source /dev/stdin; }
_source_locals() { "${funky_exe}" --verbose | source /dev/stdin; }

_maybe_source_locals() {
    if [[ -f $PWD/.funky ]]; then
        _source_locals
    fi
}

_maybe_source_globals() {
    if [[ -f ~/.funky ]]; then
        _source_globals
    fi
}

##### Source funks on startup
_maybe_source_globals
_maybe_source_locals

##### Source appropriate funks everytime the directory is changed
#
# - Is run everytime the directory is changed.
# - Lazily loads global funks and local funks while attempting to maintain parent's local
#   funks.
chpwd() {
    if [[ -f $_xdg_data_dir/localpath ]] && [[ $PWD != "$(cat $_xdg_data_dir/localpath)/"* ]]; then
        _maybe_source_globals
        rm -f $_xdg_data_dir/localpath
    fi

    if [[ $PWD != "$_home_dir" ]] && [[ -f $PWD/.funky ]]; then
        _source_locals
        if [[ ! -f $_xdg_data_dir/localpath ]]; then
            echo $PWD > $_xdg_data_dir/localpath
        fi
    fi
}

##### Wrapper used to interact with local funks
unalias funky &> /dev/null
funky() {
    touch $_xdg_data_dir/timestamp

    "${funky_exe}" --color "$@"
    if [[ .funky -nt $_xdg_data_dir/timestamp ]]; then
        _source_locals
    fi
}

##### Wrapper used to interact with global funks
unalias gfunky &> /dev/null
gfunky() {
    touch $_xdg_data_dir/timestamp
    "${funky_exe}" --global --color "$@"
    if [[ ~/.funky -nt $_xdg_data_dir/timestamp ]]; then
        _source_globals
        _maybe_source_locals
    fi
}
