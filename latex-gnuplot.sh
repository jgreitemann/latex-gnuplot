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

PREFIX=/usr/local/

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

OPTIONS=epszE:t:P:i:h
LONGOPTIONS=eps,pdf,svg,svgz,engine:,template:,preamble:,inject:,no-cleanup,help

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
formats=""
engine="default"
template=article
nc=0

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -e|--eps)
            formats+=" eps"
            shift
            ;;
        -p|--pdf)
            formats+=" pdf"
            shift
            ;;
        -s|--svg)
            formats+=" svg"
            shift
            ;;
        -z|--svgz)
            formats+=" svgz"
            shift
            ;;
        -E|--engine)
            engine="$2"
            shift 2
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

# Load the template

template="${template%.*}.tex"
TEMPLATE_HOME="${HOME}/.latex-gnuplot/${template}"
TEMPLATE_PREFIX="${PREFIX}/share/latex-gnuplot/${template}"
TEMPLATE_LOCAL="/usr/local/share/latex-gnuplot/${template}"
TEMPLATE_USR="/usr/share/latex-gnuplot/${template}"

if [ ! -f $template ]; then
    if [ ! -f $TEMPLATE_HOME ]; then
        if [ ! -f $TEMPLATE_PREFIX ]; then
            if [ ! -f $TEMPLATE_LOCAL ]; then
                if [ ! -f $TEMPLATE_USR ]; then
                    echo "$0: Template file '$template' not found." >&2
                    exit 5
                else
                    template=$TEMPLATE_USR
                fi
            else
                template=$TEMPLATE_LOCAL
            fi
        else
            template=$TEMPLATE_PREFIX
        fi
    else
        template=$TEMPLATE_HOME
    fi
fi

# Set up temporary working directory

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

# Copy data files to temp dir

while [[ $# -gt 0 ]]; do
    if [[ ! -e $1 ]]; then
        echo "$0: data file '$1' not found, skipping..."
    else
        cp -r $1 $TMPDIR
    fi
    shift
done

# Prepare tex file

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

# Identify engine

enginecmd=$({
    if [ -z "$engine" ]; then
        sed -nr 's/%\s*TeX-engine:\s*([^\w]+)/\1/p' $TEX
    else
        echo $engine
    fi
} | sed -r 's/^default$/pdftex/g' | sed -r 's/(la)?tex$/latex/g')

command -v $enginecmd > /dev/null 2>&1 || {
    echo "$0: Engine command '$enginecmd' not available" >&2
    exit 7
}

# Run gnuplot

GP=$(basename $GP)

pushd $TMPDIR

echo -e "\nshow output" \
    | cat $GP - \
    | gnuplot 2> output.log
cat output.log
OUTPUT=`grep "output is sent to" output.log | sed -r "s/output is sent to '(.+)'/\\1/g" | xargs`

# Run TeX

sed -i "s/THEFILENAME/${OUTPUT}/g" $TEX
command $enginecmd $TEX

# Convert and copy
TEX=$(basename $TEX)
DVI=${TEX%.*}.dvi
EPS=${TEX%.*}.eps
PDF=${TEX%.*}.pdf
SVG=${TEX%.*}.svg
SVGZ=${TEX%.*}.svgz

function get_eps {
    if [ ! -e "$EPS" ]; then
        if [ -e "$DVI" ]; then
            dvips -E -o $EPS $DVI
        elif [ -e "$PDF" ]; then
            pdftops -eps $PDF
        else
            echo "$0: EPS output: no input format to convert from" >&2
            exit 8
        fi
    fi
}

function get_pdf {
    if [ ! -e "$PDF" ]; then
        get_eps
        if [ -e "$EPS" ]; then
            epstopdf $EPS
        else
            echo "$0: PDF output: no input format to convert from" >&2
            exit 8
        fi
    fi
}

function get_svg {
    if [ ! -e "$SVG" ]; then
        if [ ! -e "$PDF" ]; then
            get_pdf
        fi
        if [ -e "$PDF" ]; then
            command -v pdftocairo > /dev/null 2>&1 || {
                echo "$0: 'pdftocairo' needs to be installed for SVG output" >&2
                exit 9
            }
            pdftocairo -svg $PDF $SVG
        fi
    fi
}

for format in $formats; do
    case "$format" in
        "eps")
            get_eps
            cp $EPS $OLDPWD/${GP%.*}.eps
            ;;
        "pdf")
            get_pdf
            cp $PDF $OLDPWD/${GP%.*}.pdf
            ;;
        "svg")
            get_svg
            cp $SVG $OLDPWD/${GP%.*}.svg
            ;;
        "svgz")
            get_svg
            gzip -c $SVG > $SVGZ
            cp $SVGZ $OLDPWD/${GP%.*}.svgz
            ;;
        *)
            echo "$0: unrecognized format: '$format'." >&2
            exit 6
            ;;
    esac
done

popd

if [[ $nc -eq 1 ]]; then
    echo "$0: skipped cleanup: $TMPDIR"
else
    rm -r $TMPDIR
fi
