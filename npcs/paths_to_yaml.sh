#!/bin/sh

if test $# -ne 1
then
    echo "Usage: $0 (paths-filename)"
    echo ""
    echo "Reverses the process of yaml_to_path.sh."
    echo ""
    echo "To take input from stdin instead of a file, pass '-'."
    echo ""
    exit 1
fi

PATHS_FILENAME=$1

if test "$PATHS_FILENAME" = "-"
then
    CAT_FILENAME="--"
    PATHS_FILENAME="(stdin)"
else
    if test ! -f "$PATHS_FILENAME"
    then
        echo "ERROR $0: No such paths file: $PATHS_FILENAME"
        exit 2
    fi

    CAT_FILENAME="$PATHS_FILENAME"
fi

cat "$CAT_FILENAME" \
    | grep -v '^[ ]*#' \
    | grep -v '^[ ]*$' \
    | sed 's|^[ ]*||' \
    | sed 's|[ ]*$||' \
    | awk -v "single_quote='" '
           BEGIN {
               two_single_quotes = single_quote single_quote;
               previous_level = 0;
           }

           {
               path = $0;
               gsub(/=.*$/, "", path);

               value = $0;
               gsub(/^[^=]*=/, "", value);

               build_key = "";
               level = 0;
               spaces[0] = "";
               prefix[0] = "";
               indexed_parents[0] = "";
               num_backslashes = 0;
               for (c = 1; c <= length(path); c ++) {
                   ch = substr(path, c, 1);
                   if (ch == "\\") {
                       num_backslashes ++;
                       if (num_backslahes > 1) {
                           num_backslashes = 0;
                           build_key = build_key "\\\\";
                       }
                   } else if (ch == "." && num_backslashes == 0) {
                       maybe_array = build_key;
                       gsub(/\[[0-9][0-9]*\]$/, "", build_key);

                       keys[level] = build_key;

                       level ++;

                       spaces[level] = spaces[level - 1] "  ";
                       if (build_key != maybe_array) {
                           if (maybe_array != indexed_parents[level]) {
                               indexed_parents[level] = maybe_array;
                               prefix[level] = spaces[level - 1 ] "- ";
                           } else {
                               prefix[level] = spaces[level - 1] "  ";
                           }
                       } else {
                           prefix[level] = spaces[level - 1] "  ";
                       }

                       build_key = "";
                   } else if (ch == ".") {
                       num_backslashes = 0;
                       build_key = build_key ".";
                   } else if (num_backslashes > 0) {
                       num_backslashes = 0;
                       build_key = build_key "\\" ch;
                   } else {
                       build_key = build_key ch;
                   }
               }

               if (build_key == "") {
                   level --;
               } else {
                   if (build_key == "~NO_KEY~") {
                       build_key = "";
                   }

                   keys[level] = build_key;
               }

               for (l = 0; l < level; l ++) {
                   if (l <= previous_level && keys[l] == previous_keys[l]) {
                       continue;
                   }

                   print prefix[l] keys[l] ":";
               }

               if (keys[level] == "") {
                   print prefix[level] value;
               } else {
                   print prefix[level] keys[level] ": " value;
               }

               previous_level = level;
               for (l = 0; l <= level; l ++) {
                   previous_keys[l] = keys[l];
               }
           }
          ' \
              || exit 3

echo "SUCCESS converting paths file $PATHS_FILENAME to YAML." >&2

exit 0
