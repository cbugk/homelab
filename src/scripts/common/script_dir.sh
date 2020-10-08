# Source: https://stackoverflow.com/questions/630372/determine-the-path-of-the-executing-bash-script

SCRIPT_PATH=$0
if [ ! -e "$SCRIPT_PATH" ]; then
  case $SCRIPT_PATH in
    (*/*) exit 1;;
    (*) SCRIPT_PATH=$(command -v -- "$SCRIPT_PATH") || exit;;
  esac
fi
SCRIPT_DIR=$(
  cd -P -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P
) || exit
SCRIPT_PATH=$dir/$(basename -- "$SCRIPT_PATH") || exit 

#printf '%s\n' "$SCRIPT_PATH"


# Previous method

# # cd into preoject directory
# SCRIPT_DIR="`dirname \"$0\"`"              # relative
# SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized
#  if [ -z "$SCRIPT_DIR" ] ; then
#   # error; for some reason, the path is not accessible
#   # to the script (e.g. permissions re-evaled after suid)
#   exit 1  # fail
# fi

