#!/bin/sh

if test $# -ne 1
then
    echo "Usage: $0 (content-repository)"
    echo ""
    echo "Converts the NPC YAML files into HTML."
    echo ""
    echo "(content-repository): The root of the Vibrant Games content repo."
    echo "    If (content-repository) is /foo/bar, then the NPC YAML files"
    echo "    are found in /foo/bar/npcs, and the HTML output files will"
    echo "    be written to /foo/bar/npcs/html."
    echo ""
    exit 1
fi

CONTENT_DIR=$1

RUN_DIR=`dirname $0`

NPCS_DIR="$CONTENT_DIR/npcs"
HTML_OUTPUT_DIR="$NPCS_DIR/html"
HTML_NPC_TEMPLATE="$HTML_OUTPUT_DIR/npc_template.html"

#
# First validate all the YAML files.
#
"$RUN_DIR/validate_yaml.sh" $NPCS_DIR/*.yaml \
    || exit 1

#
# OK, now we can convert them all into HTML.
#
"$RUN_DIR/yaml_to_html.sh" "$HTML_NPC_TEMPLATE" $NPCS_DIR/*.yaml \
    || exit 2

echo ""
echo "SUCCESS converting NPCs from YAML to HTML: $HTML_OUTPUT_DIR"
echo ""

exit 0
