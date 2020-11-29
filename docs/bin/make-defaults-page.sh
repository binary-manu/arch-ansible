#!/bin/sh

# Find all defaults.yaml files, plus global group_vars, and
# create a Markdown file with their contents, plus an index
# for easy browsing.

_parent="$(realpath -e -s "$0")"
_parent="$(dirname "$_parent")"
cd "$_parent/../../ansible"

list_defaults_files() {
    echo group_vars/all/00-default.yaml
    find roles/ -path '*/defaults/main.yaml' | sort
}

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
} | head -n -1 | sed "s/{{/{{ '{{' }}/g" > "$_parent/../defaults.md"
