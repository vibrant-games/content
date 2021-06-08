#!/bin/sh

cat -- \
    | sed 's|%0D%0A|\\n|g' \
    | sed 's|%0A|\\n|g' \
    | sed 's|%0D|\\n|g' \
    | sed 's|%20| |g' \
    | sed 's|%21|!|g' \
    | sed 's|%22|"|g' \
    | sed 's|%23|#|g' \
    | sed 's|%24|$|g' \
    | sed 's|%25|%%|g' \
    | sed 's|%26|\&|g' \
    | sed "s|%27|'|g" \
    | sed 's|%28|(|g' \
    | sed 's|%29|)|g' \
    | sed 's|%2A|*|g' \
    | sed 's|%2B|+|g' \
    | sed 's|%2C|,|g' \
    | sed 's|%2D|-|g' \
    | sed 's|%2E|.|g' \
    | sed 's|%2F|/|g' \
    | sed 's|%3A|:|g' \
    | sed 's|%3B|;|g' \
    | sed 's|%3C|<|g' \
    | sed 's|%3D|=|g' \
    | sed 's|%3E|>|g' \
    | sed 's|%3F|?|g' \
    | sed 's|%40|@|g' \
    | sed 's|%5B|[|g' \
    | sed 's|%5C|\\\\|g' \
    | sed 's|%5D|]|g' \
    | sed 's|%5E|^|g' \
    | sed 's|%5F|_|g' \
    | sed 's|%60|`|g' \
    | sed 's|%7B|{|g' \
    | sed 's/%7C/|/g' \
    | sed 's|%7D|}|g' \
    | sed 's|%7E|~|g' \
    | awk '
           BEGIN {
               num_indents = 0;
               state[num_indents] = "none";
               is_quoted = "false";
               is_started = "false";
               is_newline = "true";
               is_first[num_indents] = "false";
           }

           {
               is_backslash = "false";
               for ( c = 1; c <= length($0); c ++ ) {
                   ch = substr($0, c, 1);
                   if ( is_backslash == "true" ) {
                       printf "%s", ch;
                       is_backslash = "false";
                       is_started = "true";
                       is_newline = "false";
                       is_first[num_indents] = "false";
                       continue;
                   } else if ( ch == "\\" ) {
                       is_backslash = "true";
                       is_started = "true";
                       is_first[num_indents] = "false";
                       continue;
                   }

                   if ( state[num_indents] == "none" ) {
                       if ( ch == "{" ) {
                           num_indents ++;
                           state[num_indents] = "none";
                           is_array[num_indents] = "false";
                           is_first[num_indents] = "true";
                           is_quoted = "unknown";
                           is_started = "false";
                       } else if ( ch == "}" ) {
                           num_indents --;
                           is_first[num_indents] = "true";
                           is_quoted = "unknown";
                           is_started = "false";
                       } else if ( ch == "[" ) {
                           num_indents ++;
                           state[num_indents] = "none";
                           is_array[num_indents] = "true";
                           state[num_indents] = "none";
                           is_quoted = "unknown";
                           is_started = "false";
                       } else if ( ch == "]" ) {
                           num_indents --;
                           is_quoted = "unknown";
                           is_started = "false";
                       } else if ( ch == " " ) {
                           state[num_indents] = "none";
                       } else if ( ch == "," ) {
                           if (is_quoted == "false") {
                               print "";
                               is_newline = "true";
                           }
                           state[num_indents] = "none";
                           is_first[num_indents] = "false";
                       } else {
                           for ( indent = 1; indent < num_indents; indent ++ ) {
                               printf "%s", "  ";
                           }
                           if ( is_array[num_indents] == "true" ) {
                               printf "%s", "- ";
                               is_quoted = "unknown";
                               state[num_indents] = "value";
                           } else {
                               if ( num_indents == 1 && is_first[num_indents] == "true" ) {
                                   printf "%s", "- ";
                               } else {
                                   printf "%s", "  ";
                               }
                               state[num_indents] = "key";
                           }

                           if ( ch == "\"" ) {
                               is_quoted = "true";
                               is_started = "false";
                           } else {
                               printf "%s", ch;
                               is_quoted = "false";
                               is_started = "true";
                           }

                           is_first[num_indents] = "false";
                           is_newline = "false";
                       }

                       continue;
                   }

                   if ( is_quoted == "unknown" && ch == "\"" ) {
                       is_quoted = "true";
                       is_started = "false";
                       continue;
                   } else if ( is_quoted == "true" ) {
                       if ( ch == "\"" ) {
                           if ( state[num_indents] == "key" ) {
                               printf "%s", ": ";
                               state[num_indents] = "value";
                               is_started = "false";
                               is_quoted = "unknown";
                               is_newline = "false";
                           } else {
                               if ( is_started == "false" ) {
                                   printf "%s", "\"\"";
                               }
                               print "";
                               is_newline = "true";
                               state[num_indents] = "none";
                               is_started = "false";
                           }

                           is_first[num_indents] = "false";

                           continue;
                       }

                       printf "%s", ch;
                       is_started = "true";
                       is_first[num_indents] = "false";
                       is_newline = "false";

                       continue;
                   } else if ( ch == "{" ) {
                       if ( is_newline == "false" ) {
                           print "";
                           is_newline = "true";
                       }
                       num_indents ++;
                       state[num_indents] = "none";
                       is_array[num_indents] = "false";
                       is_first[num_indents] = "true";
                       is_quoted = "unknown";
                       is_started = "false";

                       continue;
                   } else if ( ch == "}" ) {
                       if ( is_newline == "false" ) {
                           print "";
                           is_newline = "true";
                       }
                       num_indents --;
                       is_first[num_indents] = "true";
                       is_quoted = "unknown";
                       is_started = "false";

                       continue;
                   } else if ( ch == "[" ) {
                       if ( is_newline == "false" ) {
                           print "";
                           is_newline = "true";
                       }
                       num_indents ++;
                       state[num_indents] = "none";
                       is_array[num_indents] = "true";
                       is_quoted = "unknown";
                       is_started = "false";

                       continue;
                   } else if ( ch == "]" ) {
                       if ( is_newline == "false" ) {
                           print "";
                           is_newline = "true";
                       }
                       num_indents --;
                       is_quoted = "unknown";
                       is_started = "false";

                       continue;
                   } else if ( ch == " " ) {
                       continue;
                   } else if ( ch == "," ) {
                       if (is_quoted == "false") {
                           print "";
                           is_newline = "true";
                       }
                       state[num_indents] = "none";
                       is_quoted = "unknown";
                       is_first[num_indents] = "false";
                       continue;
                   } else if ( ch == ":" ) {
                       state[num_indents] = "value";
                       is_quoted = "unknown";
                       continue;
                   } else if ( is_quoted == "unknown" ) {
                       is_quoted = "false";
                       printf "%s", ch;
                       is_started = "true";
                       is_first[num_indents] = "false";
                       is_newline = "false";
                       continue;
                   }

                   printf "%s", ch;
                   is_started = "true";
                   is_first[num_indents] = "false";
                   is_newline = "false";
               }
           }

           END {
               if ( is_newline == "false" ) {
                   print "";
                   is_newline = "true";
               }
           }
          ' \
    || exit 1

exit 0
