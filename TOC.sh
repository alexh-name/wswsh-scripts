#!/bin/sh

file="$1"

printf '%s\n' "<ul>"
grep '<h2\ id=".*">.*</h2>' ${file} | sed -e 's/<h2\ id=\"/<li><a\ href=\"#/g' -e 's/<\/h2>/<\/a><\/li>/g'
printf '%s\n' "</ul>"
