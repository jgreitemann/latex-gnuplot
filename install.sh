#!/bin/bash

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment." >&2
    exit 1
fi

OPTIONS=u
LONGOPTIONS=uninstall,prefix:

# -temporarily store output to be able to check for errors
# -e.g. use “--options” parameter by name to activate quoting/enhanced mode
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# default values
prefix=/usr/local
action=install

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        --prefix)
            prefix="$2"
            shift 2
            ;;
        -u|--uninstall)
            action=uninstall
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error" >&2
            exit 3
            ;;
    esac
done

if [ ! -d $prefix ]; then
    echo "$0: prefix directory '$prefix' do not exist." 2>&1
    exit 1
fi

if [ "$action" == "install" ]; then
    echo Installing...
    mkdir -vp ${prefix}/bin
    install -v --mode=755 latex-gnuplot.sh ${prefix}/bin/latex-gnuplot
fi

if [ "$action" == "uninstall" ]; then
    echo Uninstalling...
    rm -vf ${prefix}/bin/latex-gnuplot
fi
