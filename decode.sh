#!/bin/bash

set -e

output_fmt=""

while getopts "jd" opts; do
  case $opts in
    j) output_fmt="json";;
    d) output_fmt="der";;
    ?) echo "Usage: decode.sh [-j] [-d] ENCODED_STRING" && exit 1;;
  esac
done

shift $((OPTIND-1))
if [[ $# -ne 0 ]]; then
  encoded_str="$1"
else
  echo "Usage: decode.sh [-j] [-d] ENCODED_STRING"
  exit 1
fi

# Both base64 and base64url encoded string can be correctly
# processed.
decoded_str="$(echo -n "$encoded_str"==== | fold -w 4 | \
  sed '$ d' | tr -d '\n' | tr '_-' '/+')"

if [[ "$output_fmt" == "json" ]]; then
  echo -n "$decoded_str" | base64 -d | jq .
elif [[ "$output_fmt" == "der" ]]; then
  echo -n "$decoded_str" | base64 -d | openssl x509 -inform der -nocert -text 
else
  echo -n "$decoded_str" | base64 -d
fi
