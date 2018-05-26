#!/bin/bash
# latex-gnuplot - render gnuplots from LaTeX terminals to self-contained figures
# Copyright (C) 2018  Jonas Greitemann

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cd ${0%/*}

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
gen_man=1

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        --prefix)
            prefix="$2"
            shift 2
            ;;
        --skip-man)
            gen_man=0
            shift
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
    echo "$0: prefix directory '$prefix' does not exist." 2>&1
    exit 1
fi

if [ "$action" == "install" ]; then
    if [[ $gen_man -gt 0 ]]; then
        echo "Generating man page..."
        pandoc -s -t man doc/man-page.md -o latex-gnuplot.1
    fi
    echo "Installing..."
    sed -r "s/^PREFIX=.+$/PREFIX=$(echo $prefix | sed 's/\//\\\//g')/g" latex-gnuplot.sh > latex-gnuplot
    mkdir -vp ${prefix}/bin
    install -v --mode=755 latex-gnuplot ${prefix}/bin
    mkdir -vp ${prefix}/share/latex-gnuplot
    install -v templates/*.tex ${prefix}/share/latex-gnuplot
    if [ -f latex-gnuplot.1 ] && [ -d ${prefix}/share/man ]; then
        mkdir -vp ${prefix}/share/man/man1
        install -v latex-gnuplot.1 ${prefix}/share/man/man1
        mandb
    fi
fi

if [ "$action" == "uninstall" ]; then
    echo "Uninstalling..."
    rm -vf ${prefix}/bin/latex-gnuplot
    rm -vrf ${prefix}/share/latex-gnuplot
    rm -vf ${prefix}/share/man/man1/latex-gnuplot.1
    mandb
fi
