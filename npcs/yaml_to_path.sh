#!/bin/sh

if test $# -ne 1
then
    echo "Usage: $0 (yaml-filename)"
    echo ""
    echo "Converts the YAML file into root.trunk.leaf=value format."
    echo ""
    echo "For example, the following YAML:"
    echo ""
    echo "vehicle:"
    echo "  type: bicycle"
    echo "  colour: candy apple red"
    echo "  wheels:"
    echo "  - name: front wheel"
    echo "    size: huge"
    echo "  - name: back wheel"
    echo "    size: tiny"
    echo "  dot.for.fun:"
    echo "    colour: blue"
    echo ""
    echo "Will be turned into the following output:"
    echo ""
    echo "vehicle.type=bicycle"
    echo "vehicle.colour=candy apple red"
    echo "vehicle.wheels[0].name=front wheel"
    echo "vehicle.wheels[0].size=huge"
    echo "vehicle.wheels[1].name=back wheel"
    echo "vehicle.wheels[2].size=tiny"
    echo "vehicle.dot\.for\.fun.colour=blue"
    echo ""
    echo "From there, you get to decide whether to `read` the output"
    echo "or \ backslash the spaces in the values and so on."
    echo ""
    echo "To take input from stdin instead of a file, pass '-'."
    echo ""
    exit 1
fi

YAML_FILENAME=$1

if test "$YAML_FILENAME" = "-"
then
    CAT_FILENAME="--"
    YAML_FILENAME="(stdin)"
else
    if test ! -f "$YAML_FILENAME"
    then
        echo "ERROR $0: No such YAML file: $YAML_FILENAME"
        exit 2
    fi

    CAT_FILENAME="$YAML_FILENAME"
fi

cat "$CAT_FILENAME" \
    | grep -v '^[ ]*#' \
    | grep -v '^[ ]*$' \
    | awk -v "single_quote='" '
           BEGIN {
               two_single_quotes = single_quote single_quote;
               previous_spaces = "";
               previous_path = "";
           }

           {
               spaces = $0;
               gsub(/[^ ].*/, "", spaces);

               key_value = $0;
               gsub(/^[ ]*/, "", key_value);

               maybe_array = key_value;
               gsub(/[ ]*:.*$/, "", maybe_array);

               maybe_dots_key = maybe_array;
               gsub(/^-[ ]*/, "", maybe_dots_key);

               key = maybe_dots_key;
               gsub(/\./, "\\.", key);

               extra_spaces = "";
               if (maybe_dots_key == maybe_array) {
                   array_index = -1;
               } else {
                   array_indentation = spaces "- ";
                   if (! yaml_array[array_indentation][key]) {
                       yaml_array[array_indentation][key] = 0;
                   }
                   array_index = yaml_array[array_indentation][key];
                   yaml_array[array_indentation][key] ++;
                   for (extra_space = length(key) + 1; extra_space <= length(maybe_array); extra_space ++) {
                       extra_spaces = extra_spaces " ";
                   }
                   spaces = spaces extra_spaces;
               }

               value = key_value;
               gsub(/^[^:]*:[ ]*/, "", value);

               if (maybe_array == key_value) {
                   key = "~NO_KEY~";
                   value = key_value;
                   gsub(/^-[ ]*/, "", value);
               }

               actual_value = value;
               if (value == "[]" || value == "\"\"" || value == two_single_quotes) {
                   value = "";
               }

               if (array_index < 0) {
                   maybe_array_index = "";
               } else {
                   maybe_array_index = "[" array_index "]";
               }

               if (previous_path == "" || parents[spaces] == ".") {
                   parents[spaces] = ".";
                   parent = "";
                   parent_prefix = "";
                   if (key == "~NO_KEY~") {
                       key = "";
                   }
               } else if (length(spaces) < length(previous_spaces)) {
                   parent = parents[spaces];
                   if (maybe_array_index != "") {
                       gsub(/\[[0-9][0-9]*\]$/, "", parent);
                   }
                   parent = parent maybe_array_index;

                   if (key == "~NO_KEY~") {
                       parent_prefix = parent;
                       key = "";
                   } else {
                       parent_prefix = parent ".";
                   }

                   for (array_indentation in yaml_array) {
                       if (length(array_indentation) > length(spaces)) {
                           delete yaml_array[array_indentation];
                       }
                   }
               } else if ( length(spaces) > length(previous_spaces)) {
                   parent = previous_path;
                   if (maybe_array_index != "") {
                       gsub(/\[[0-9][0-9]*\]$/, "", parent);
                   }
                   parent = parent maybe_array_index;

                   parents[spaces] = parent;

                   if (key == "~NO_KEY~") {
                       parent_prefix = parent;
                       key = "";
                   } else {
                       parent_prefix = parent ".";
                   }
               } else {
                   parent = parents[spaces];
                   if (maybe_array_index != "") {
                       gsub(/\[[0-9][0-9]*\]$/, "", parent);
                   }
                   parent = parent maybe_array_index;
                   parents[spaces] = parent;

                   if (key == "~NO_KEY~") {
                       parent_prefix = parent;
                       key = "";
                   } else {
                       parent_prefix = parent ".";
                   }
               }

               path = parent_prefix key;

               if ( path != "" ) {
                   if (actual_value != "") {
                       print path "=" value;
                   }

                   previous_spaces = spaces;
                   previous_path = path;
               }
           }
          ' \
              || exit 3

echo "SUCCESS converting YAML file $YAML_FILENAME to paths." >&2

exit 0
