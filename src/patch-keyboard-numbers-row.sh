#!/bin/sh
# shellcheck enable=all disable=SC2250

# Generate patches to add a number row to Sailfish OS keyboard layouts.

set -eu

LF='
'
IFS="$LF"
SED_LF="\\$LF"

LAYOUTS_DIR=usr/share/maliit/plugins/com/jolla/layouts

get_idx() {
    eval "printf '%s\n' \"\${$(($1 + 2))}\"";
}

# Workaround for broken wait in the rpm scriptlet environment.
wait2() {
    for _pid in "$@"; do
        while :; do
            if ! { read -r _stat < "/proc/$_pid/stat"; } 2> /dev/null; then
                # Process no longer exists.
                break
            fi
            if [ "$(printf '%s\n' "$_stat" | cut -d ' ' -f 4 || :)" != "$$" ]; then
                # PID reused by a process which is not our child.
                break
            fi
            if [ "$(printf '%s\n' "$_stat" | cut -d ' ' -f 3 || :)" = 'Z' ]; then
                # Zombie.
                break
            fi
            sleep 1
        done
    done
}

uniq_sort_by_freq() {
    sort | uniq -c | sort -n -r -s | sed 's/^[[:space:]]*//' | cut -d ' ' -f 2-
}

number_row="$({
    printf '    KeyboardRow {'
    printf '%s' "$SED_LF"
    for _i in $(seq 0 9); do
        _num="\"$(((_i + 1) % 10))\""
        printf '        CharacterKey { '
        printf 'caption: %s; ' "$_num"
        printf 'captionShifted: %s; ' "$_num"
        printf 'symView: %s; ' "$_num"
        printf 'symView2: %s }' "$_num"
        printf '%s' "$SED_LF"
    done
    printf '    }\n'
})"

row_pat='^[[:space:]]*\(KeyboardRow\|SpacebarRow\|SpacebarRowDeadKey\)[[:space:]]*{'

# Copy the line into hold space, do the first search and replace,
# restore the line from hold space, do the second search and replace.
# Prepend 1 to primary symbols and 2 to alternate symbols for later
# sorting.
str_pat='"\(\\"\|\\\\\|[^\\"]*\)"'
sym_search_cmd="
    h;
    s/^.* symView: ${str_pat}.*$/1 \1/gp;
    g;
    s/^.* symView2: ${str_pat}.*$/2 \1/gp
"

find_syms() {
    _n_rows="$(grep -c "${row_pat}" "$1")"

    # When $row_pat matches, a subcommand will get next line,
    # run $sym_search_cmd which prints matches, try to match $row_pat
    # and recurse the subcommand if it does, or loop back to the beginning
    # of the subcommand if it doesn't. At the bottom of the recursion,
    # a match for $row_pat quits sed; therefore the program will quit
    # after matching $_n_rows - 1 times.
    #
    # Recursion is implemented by wrapping the command in itself the
    # desired number of times.
    _cmd="/${row_pat}/q"
    for _label in $(seq "$((_n_rows - 1))"); do
        _cmd="/${row_pat}/ {
            :${_label}
            n;
            ${sym_search_cmd};
            ${_cmd};
            b ${_label}
        }"
    done

    sed -n "$_cmd" "$1" | sort -n -s | cut -d ' ' -f 2
}

# Get top symbols not already in layout.
generate_extra_syms() {
    _grepfile="$(mktemp -p "$workdir")"
    # Some layouts have period and comma as PeriodKey and CommaKey,
    # assume all layouts have those symbols.
    printf '.\n,\n' > "$_grepfile"
    sed -n "$sym_search_cmd" "$1" | cut -d ' ' -f 2- >> "$_grepfile"
    printf '%s' "$top_syms" | grep -f "$_grepfile" -F -v
}

update_layout() {
    _layout_syms="$(find_syms "$1")"
    _all_syms="${_layout_syms}${LF}$(generate_extra_syms "$1")"

    # Escape original layout symbols for pattern matching and all symbols for
    # substitution.
    _layout_syms="$(printf '%s\n' "$_layout_syms" | sed 's|[][/\\.*^$]|\\&|g')"
    _all_syms="$(printf '%s\n' "$_all_syms" | sed 's|[/&\\]|\\&|g')"

    _i=0
    # Disable pathname expansion in order to prevent loop arguments being
    # interpreted as globs.
    set -f
    _sed_cmd=''
    for _sym in $_layout_syms; do
        # Assuming the first 10 symbols are digits, shift out digits by
        # replacing each symbol (digits included) by the one 10 positions
        # ahead.
        # shellcheck disable=SC2086
        _upd_sym="$(get_idx "$((_i + 10))" $_all_syms)"

        _sed_cmd="
            s/ \\(symView2\\{0,1\\}\\): \"${_sym}\"/ \1: \"${_upd_sym}\"/g;
            ${_sed_cmd}
        "

        _i="$((_i + 1))"
    done
    set +f

    # Add the numbers row before the first row.
    _sed_cmd="
        ${_sed_cmd}
        1,/${row_pat}/ {
            s/${row_pat}/${number_row}${SED_LF}${SED_LF}&/
        }
    "

    sed "$_sed_cmd" "$1"
}

workdir="$(mktemp -d)"
mkdir -p "$workdir/a/$LAYOUTS_DIR"
mkdir -p "$workdir/b/$LAYOUTS_DIR"
NO_PM_PRELOAD=1 cp "/$LAYOUTS_DIR/"*.qml "$workdir/a/$LAYOUTS_DIR"

for type in emoji zh_cn_stroke_ zh_hwr_; do
    rm "$workdir/a/$LAYOUTS_DIR/$type"*.qml || :
done

# All symbols of all layouts, sorted by most frequent.
top_syms="$(
    sed -n "$sym_search_cmd" "$workdir/a/$LAYOUTS_DIR"/*.qml |
        cut -d ' ' -f 2 | uniq_sort_by_freq
)"

pids=''
for layout in "$workdir/a/$LAYOUTS_DIR"/*.qml; do
    update_layout "$layout" > "$workdir/b/$LAYOUTS_DIR/$(basename "$layout")" &
    pids="${pids}$!${LF}"
done

# shellcheck disable=SC2086
wait2 $pids

( cd "$workdir"; diff -ur a b || : )
rm -r "$workdir"
