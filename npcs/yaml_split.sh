#!/bin/sh

if test $# -eq 0
then
    echo "Usage: $0 (yaml-input-file-path) ..."
    echo ""
    echo "Splits the specified YAML file into multiple files under the same"
    echo "parent path."
    echo ""
    echo "The monolith file is split by '---' dpcument dividers."
    echo ""
    echo "The split files are each named by the 'id' attribute in each"
    echo "document.  If there is none, then the process will fail wiuthout"
    echo "creating any new files at all."
    echo ""
    exit 1
fi

FILENAME_FIELD="id"
FILENAME_PRE=""
FILENAME_POST=".yaml"

INPUT_FILES=$*

#
# First check splittability of the monolithic YAML file:
#
echo "Pre-checks..."
for YAML_INPUT_FILE in $INPUT_FILES
do
    if test ! -f "$YAML_INPUT_FILE"
    then
        echo "ERROR No such input file: $YAML_INPUT_FILE"
        exit 2
    fi

    OUTPUT_DIR=`dirname "$YAML_INPUT_FILE"`
    if test -z "$OUTPUT_DIR"
    then
        echo "ERROR Failed to determine parent path for YAML input file $YAML_INPUT_FILE"
        exit 3
    elif test ! -d "$OUTPUT_DIR"
    then
        echo "ERROR Directory $OUTPUT_DIR does not exist for YAML input file $YAML_INPUT_FILE"
        exit 4
    fi

    cat "$YAML_INPUT_FILE" \
        | sed 's|[\r]||g' \
        | awk \
              -v "input_path=$YAML_INPUT_FILE" \
              -v "output_dir=$OUTPUT_DIR" \
              -v "filename_field=$FILENAME_FIELD" \
              -v "filename_pre=$FILENAME_PRE" \
              -v "filename_post=$FILENAME_POST" \
              '
               BEGIN {
                   line_num_divider = -1;
                   line_num_start = -1;
                   yaml_output_filename = "";
                   yaml_output_path = "";
                   is_error = "false";
                   line_num = 0;
               }

               {
                   line_num ++;
                   line_type = "none";
               }

               $0 == "---" {
                   if ( line_num_start > 0 && yaml_output_path == "" ) {
                       line_end = line_num - 1;
                       print "ERROR document lines " line_num_start " - " line_end " do not contain a(n) " filename_field " field: " input_path;
                       is_error = "true";

                   }

                   line_num_divider = line_num;
                   line_num_start = -1;
                   yaml_output_filename = "";
                   yaml_output_path = "";
                   line_type = "divider";
               }

               $0 ~ /^[ ]*#.*$/ {
                   line_type = "comment";
               }

               $0 ~ /^[ ]*$/ {
                   line_type = "blank";
               }

               line_type == "none" {
                   line_type = "yaml";
               }

               line_type == "yaml" && line_num_start <= 0 {
                   line_num_start = line_num_divider + 1;
               }

               line_type == "yaml" && $1 == filename_field ":" {
                   if ( NF < 2 ) {
                       print "ERROR document " filename_field " field at line " line_num " has no value: " input_path;
                       is_error = "true";
                   }
                   else if ( NF > 2 ) {
                       print "ERROR document " filename_field " field at line " line_num " contains spaces (" $0 "): " input_path;
                       is_error = "true";
                   }
                   else if ( yaml_output_path != "" ) {
                       print "ERROR document starting at line " line_num_start " (" yaml_output_filename ") has 2nd " filename_field " field at line " line_num " (" $0 "): " input_path;
                       is_error = "true";
                   }

                   yaml_output_filename = filename_pre $2 filename_post;
                   yaml_output_path = output_dir "/" yaml_output_filename;
                   if ( split_line_nums[yaml_output_path] > 0 ) {
                       print "ERROR duplicate " filename_field " values: lines " split_line_nums[yaml_output_path] " and " line_num " (" $0 "): " input_path;
                   } else {
                       split_line_nums[yaml_output_path] = line_num;
                   }
               }

               END {
                   if ( line_num_start > 0 && yaml_output_path == "" ) {
                       line_end = line_num;
                       print "ERROR document lines " line_num_start " - " line_end " do not contain a(n) " filename_field " field: " input_path;
                       is_error = "true";
                   }

                   if ( "is_error" == "true" ) {
                       exit 5;
                   }
               }
              ' \
                  || exit 5
done


#
# Now split the monolithic YAML file:
#
echo "Splitting files..."
for YAML_INPUT_FILE in $INPUT_FILES
do
    if test ! -f "$YAML_INPUT_FILE"
    then
        echo "ERROR No such input file: $YAML_INPUT_FILE"
        exit 7
    fi

    OUTPUT_DIR=`dirname "$YAML_INPUT_FILE"`
    if test -z "$OUTPUT_DIR"
    then
        echo "ERROR Failed to determine parent path for YAML input file $YAML_INPUT_FILE"
        exit 8
    elif test ! -d "$OUTPUT_DIR"
    then
        echo "ERROR Directory $OUTPUT_DIR does not exist for YAML input file $YAML_INPUT_FILE"
        exit 9
    fi

    cat "$YAML_INPUT_FILE" \
        | sed 's|[\r]||g' \
        | awk \
              -v "input_path=$YAML_INPUT_FILE" \
              -v "output_dir=$OUTPUT_DIR" \
              -v "filename_field=$FILENAME_FIELD" \
              -v "filename_pre=$FILENAME_PRE" \
              -v "filename_post=$FILENAME_POST" \
              '
               BEGIN {
                   yaml_output_filename = "";
                   yaml_output_path = "";
                   yaml_output_path = "";
                   yaml_content = "";
               }

               {
                   line_type = "none";
               }

               $0 == "---" {
                   if ( yaml_output_path != "" && yaml_content != "" ) {
                       print "  " yaml_output_path;
                       print yaml_content > yaml_output_path;
                   }
                   yaml_output_filename = "";
                   yaml_output_path = "";
                   yaml_content = "";
                   line_type = "divider";
               }

               line_type == "none" {
                   yaml_content = yaml_content "\n" $0;
                   line_type = "yaml";
               }

               line_type == "yaml" && $1 == filename_field ":" {
                   yaml_output_filename = filename_pre $2 filename_post;
                   yaml_output_path = output_dir "/" yaml_output_filename;
               }

               END {
                   if ( yaml_output_path != "" && yaml_content != "" ) {
                       print "  " yaml_output_path;
                       print yaml_content > yaml_output_path;
                   }
               }
              ' \
                  || exit 10
done

echo ""
echo "SUCCESS splitting YAML file(s): $INPUT_FILES"
echo ""

exit 0
