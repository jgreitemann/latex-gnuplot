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

usage () {
    echo "$0 [*options*] *input-gnuplot-file* [*data-file*]..."
}

show_usage () {
    echo "Usage: $(usage)"
    echo "Try '$0 --help' for more information."
}

show_help () {
    echo "
latex-gnuplot -- render gnuplots from LaTeX terminals to self-contained figures

Copyright (C) 2018  Jonas Greitemann
This program comes with ABSOLUTELY NO WARRANTY.
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version, see <http://www.gnu.org/licenses/>.

USAGE:
    $(usage)

OPTIONS:
    -e, --eps                     Specify \`latex\` + \`dvips\` as typeset commands
    -p, --pdf                     Specify \`pdflatex\` as typeset command
        --eps-from-pdf            Specify \`pdflatex\` as typeset command, but
                                  convert subsequently with \`pdftops\` to EPS
    -t, --template TEMPLATE       Specify the name of an installed template file
    -P, --preamble PREAMBLE-FILE  Specify path to an optional preamble file
    -i, --inject INJECTION        Specify LaTeX commands to put immediately
                                  before the gnuplot figure is included
        --no-cleanup              Do not delete temporary working directory
    -h, --help                    Display this help message
"
}

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment." >&2
    exit 1
fi

OPTIONS=ept:P:i:h
LONGOPTIONS=eps,pdf,eps-from-pdf,template:,preamble:,inject:,no-cleanup,help

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
format=eps
template=article
nc=0

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -e|--eps)
            format=eps
            shift
            ;;
        -p|--pdf)
            format=pdf
            shift
            ;;
        --eps-from-pdf)
            format=eps-from-pdf
            shift
            ;;
        -t|--template)
            template="$2"
            shift 2
            ;;
        -P|--preamble)
            preamble="$2"
            shift 2
            ;;
        -i|--inject)
            injection="$2"
            shift 2
            ;;
        --no-cleanup)
            nc=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
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

template="${template%.*}.tex"
TEMPLATE_HOME="${HOME}/.latex-gnuplot/${template}"
TEMPLATE_SHARE="/usr/local/share/latex-gnuplot/${template}"

if [ ! -f $template ]; then
    if [ ! -f $TEMPLATE_HOME ]; then
        if [ ! -f $TEMPLATE_SHARE ]; then
            echo "$0: Template file '$template' not found." >&2
            exit 5
        else
            template=$TEMPLATE_SHARE
        fi
    else
        template=$TEMPLATE_HOME
    fi
fi

OLDPWD=$PWD
TMPDIR=`mktemp -d --tmpdir latex-gnuplot_XXXXXXXX`
TEX=`mktemp --tmpdir=$TMPDIR XXXXXX_$(basename $template)`

# handle non-option arguments
if [[ $# -lt 1 ]]; then
    echo "$0: At least a single gnuplot input file is required." >&2
    exit 4
fi
GP=$1
cp $GP $TMPDIR
shift

while [[ $# -gt 0 ]]; do
    if [[ ! -e $1 ]]; then
        echo "$0: data file '$1' not found, skipping..."
    else
        cp -r $1 $TMPDIR
    fi
    shift
done

{
    sed '/THEPREAMBLE/,$d' $template
    if [[ ! -z $preamble ]]; then
        if [ ! -f $preamble ]; then
            echo "$0: Preamble file '$preamble' not found, skipping..." >&2
        else
            cat $preamble
        fi
    fi
    sed '1,/THEPREAMBLE/d' $template \
        | sed "s/THEINJECTION/${injection}/g"
} > $TEX

GP=$(basename $GP)
RES=${GP%.*}.eps

pushd $TMPDIR

echo -e "\nshow output" \
    | cat $GP - \
    | gnuplot 2> output.log
cat output.log
OUTPUT=`grep "output is sent to" output.log | sed -r "s/output is sent to '(.+)'/\\1/g" | xargs`

sed -i "s/THEFILENAME/${OUTPUT}/g" $TEX

case "$format" in
    "eps")
        latex $TEX
        dvips -E -o res.eps ${TEX%.*}.dvi
        mv res.eps $OLDPWD/${GP%.*}.eps
        ;;
    "pdf")
        pdflatex $TEX
        mv ${TEX%.*}.pdf $OLDPWD/${GP%.*}.pdf
        ;;
    "eps-from-pdf")
        pdflatex $TEX
        pdftops -eps ${TEX%.*}.pdf
        mv ${TEX%.*}.eps $OLDPWD/${GP%.*}.eps
        ;;
    *)
        echo "$0: unrecognized format: '$format'." >&2
        exit 6
        ;;
esac

popd

if [[ $nc -eq 1 ]]; then
    echo "$0: skipped cleanup: $TMPDIR"
else
    rm -r $TMPDIR
fi
