#!/bin/sh
# Runs the engine's unit tests headless with GUT.
#
#   GODOT=/path/to/godot sh tests/run_tests.sh
#
# GODOT defaults to `godot` on the PATH. GUT must be installed in addons/gut.
here=$(cd "$(dirname "$0")/.." && pwd)
godot=${GODOT:-godot}
"$godot" --headless --path "$here" --import >/dev/null 2>&1
exec "$godot" --headless --path "$here" -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit -glog=1
