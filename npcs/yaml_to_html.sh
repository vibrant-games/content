#!/bin/sh

if test $# -lt 2
then
    echo "Usage: $0 (html-template-filename) (yaml-filename)..."
    echo ""
    echo "Converts 1 or more YAML NPC files to HTML."
    exit 1
fi

HTML_TEMPLATE_FILE=$1
shift
YAML_FILES=$*

RUN_DIR=`dirname $0`

if test ! -f "$HTML_TEMPLATE_FILE"
then
    echo "ERROR No such HTML template file: $HTML_TEMPLATE_FILE"
    exit 2
fi

MUSTACHE=`which mustache`
if test $? -ne 0 \
        -o "$MUSTACHE" = ""
then
    echo "ERROR you need to install mustache to run $0: sudo apt-get install ruby && sudo gem install mustache"
    exit 3
fi

for YAML_FILE in $YAML_FILES
do
    if test ! -f "$YAML_FILE"
    then
        echo "ERROR No such YAML file: $YAML_FILE"
        exit 3
    fi

    HTML_OUTPUT_DIR=`echo "$YAML_FILE" \
                         | sed 's|/\([^/]*\)$|/html|'`
    HTML_OUTPUT_FILE_BASE=`echo "$YAML_FILE" \
                               | sed 's|^.*/\([^/]*\)\.yaml$|\1|'`
    HTML_TEMP_FILE="$HTML_OUTPUT_DIR/$HTML_OUTPUT_FILE_BASE.temp"
    HTML_OUTPUT_FILE="$HTML_OUTPUT_DIR/$HTML_OUTPUT_FILE_BASE.html"

    echo "$YAML_FILE -> $HTML_OUTPUT_FILE"
    "$MUSTACHE" "$YAML_FILE" "$HTML_TEMPLATE_FILE" \
                > "$HTML_TEMP_FILE" \
        || exit 4
    cat "$HTML_TEMP_FILE" \
        | sed 's|\$characters\$||g' \
              > "$HTML_OUTPUT_FILE" \
        || exit 5
    rm "$HTML_TEMP_FILE" \
        || exit 6
    if test ! -f "$HTML_OUTPUT_FILE"
    then
        echo "ERROR $0 did not create $HTML_OUTPUT_FILE for some reason"
        exit 7
    fi
done

echo "SUCCESS Converting YAML files to HTML."
exit 0
