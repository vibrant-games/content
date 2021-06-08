#!/bin/sh

if test $# -lt 1
then
    echo "Usage: $0 (yaml-file) ..."
    echo ""
    echo "Uses dasel to verify that the specified YAML file(s) are"
    echo "formatted correctly; or outputs an error and a line number"
    echo "for the first YAML file that has syntax errors."
    echo ""
    exit 1
fi

YAML_FILES=$*

DASEL=`which dasel`
if test $? -ne 0 \
	-o "$DASEL" = ""
then
    echo "ERROR dasel must be installed to use $0: brew install dasel (https://daseldocs.tomwright.me/installation)"
    exit 1
fi

for YAML_FILE in $YAML_FILES
do
    DASEL_ERROR=`dasel select --file "$YAML_FILE" --read yaml --plain --selector metadata.date \
                     2> /dev/null`
    DASEL_EXIT_CODE=$?
    if test $DASEL_EXIT_CODE -ne 0
    then
        echo "ERROR validating $YAML_FILE:"
        echo "$DASEL_ERROR"
        exit 1
    fi
done

echo ""
echo "SUCCESS validating YAML files"
echo ""

exit 0
