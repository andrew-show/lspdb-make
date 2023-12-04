#!/bin/bash

# $1: path
# $2: working directory
function abs_path()
{
    local path

    if [[ "$1" =~ / ]]; then
        path=$1
    else
        path=$2/$1
    fi

    echo $(cd $(dirname $path) && pwd)/$(basename $path)
}

function lsp_make_database()
{
    while read line; do
        set -- $line

        pwd=$1
        shift

        if [[ "$1" =~ (^|/)(gcc|g\+\+|clang|clang\+\+)$ ]]; then
            args=$1
            shift

            output=
            while [ $# -gt 1 ]; do
                if [[ "$1" =~ ^-I ]]; then
                    if [[ "$1" == "-I" ]]; then
                        shift
                        path="$1"
                    else
                        path=${1#-I}
                    fi

                    args="$args -I $(abs_path $path $pwd)"
		elif [[ "$1" == "-include" ]]; then
		    shift
		    args="$args -include $(abs_path $1 $pwd)"
                else
                    if [[ "$1" == "-o" ]]; then
                        output=yes
                    fi

                    args="$args $1"
                fi

                shift
            done

            if [ "X$1" != "X" -a "X$output" == "Xyes" ]; then
                if [[ $1 =~ \.(c|cc|cxx|cpp)$ ]]; then
                    path=$(abs_path $1 $pwd)
                    args=$(echo $args $path | sed 's/\"/\\"/g')
                    cat >> $PWD/compile_commands.json <<EOF
{
    "directory": "$PWD",
    "file": "$path",
    "command": "$args"
},
EOF
                fi
            fi
        fi
    done
}

echo '[' > $PWD/compile_commands.json

export ARGS_PROBE=/tmp/lsp-make-$$

args-probe $ARGS_PROBE | lsp_make_database &

ARGS_PROBE_PID=$!

export LD_PRELOAD=args-advise.so

$@

sleep 1
kill -2 $ARGS_PROBE_PID

sed -i '$ s/,$//' $PWD/compile_commands.json
echo ']' >> $PWD/compile_commands.json
