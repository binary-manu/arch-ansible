#!/bin/sh

# Find all defaults.yaml files, plus global group_vars, and
# create a Markdown file with their contents, plus an index
# for easy browsing.

_parent="$(realpath -e -s "$0")"
_parent="$(dirname "$_parent")"
_defaults="$_parent/../defaults.md"
cd "$_parent/../../ansible"

list_defaults_files() {
    echo group_vars/all/00-default.yaml
    find roles/ -path '*/defaults/main.yaml' | sort
}

check_defaults_file_is_up_to_date() {
    test "group_vars/all/00-default.yaml" -ot "$_defaults" &&
      test -z "$(find roles/ -path '*/defaults/main.yaml' -newer "$_defaults" \( -print -quit \))"
}

case "$1" in
check)
    check_defaults_file_is_up_to_date
    exit
    ;;
"")
    ;;
*)
    echo "Unrecognized command '$1'" >&2
    exit 1
    ;;
esac

{
    echo "---"
    echo "layout: default"
    echo "---"
    echo "# Defaults files index"
    echo

    list_defaults_files | while read _deffile; do
        echo "* [$_deffile](#$(echo "$_deffile" | tr -d ./))"
    done

    echo

    list_defaults_files | while read _deffile; do
        echo "## $_deffile"
        echo
        echo '```yaml'
        cat "$_deffile"
        echo '```'
        echo
    done
} | head -n -1 | sed "s/{{/{{ '{{' }}/g" > "$_defaults"
