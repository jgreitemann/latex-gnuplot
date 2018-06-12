---
title: 'LATEX-GNUPLOT'
section: 1
header: 'LaTeX-gnuplot User Manual'
---

# NAME

latex-gnuplot - render gnuplots from LaTeX terminals to self-contained figures

# SYNOPSIS

latex-gnuplot [*options*] *input-gnuplot-file* [*data-file*]...

# DESCRIPTION

`latex-gnuplot` takes a gnuplot script which outputs to a LaTeX terminal
(`epslatex`, `pdflatex`, `cairolatex`, ...), runs *gnuplot*, embeds the
resulting `.tex` file containing the title, axis labels, etc., into a predefined
LaTeX template, and finally runs a LaTeX engine and subsequent conversions to
the desired output format.

Typical usage scenarios include submissions to journals (e.g. APS journals)
which require figures to be submitted in a self-contained format, i.e. as a
standalone file (e.g. *eps*) including all axis labels, keys, and titles.
`latex-gnuplot` allows you to comply with this constraint whilst still
benefitting from LaTeX typesetting for mathematical formulae. Using an
appropriate preamble file (see below), the type in the figure can be made to
look exactly as in the main LaTeX document, as though it was `\input` directly.
Another possible use case lies in the generation of SVG figures for seamless
embedding on the web while preserving vector graphics.

Before either *gnuplot* or LaTeX are invoked, the *input-gnuplot-file* and any
optional *data-file*s are copied in a temporary directory to not pollute the
working dir with auxiliary files. The final *eps* or *pdf* is copied back to the
working directory. The temporary directory is subsequently deleted; specifying
the option `--no-cleanup` will forego this, allowing to inspect any intermediate
products.

# OPTIONS

-h, \--help
:   Display a help message.

-E *ENGINE*, \--engine *ENGINE*
:   Select the LaTeX engine that is used behind the scenes to typeset. *ENGINE*
    may be *latex*, *pdflatex*, *pdftex*, *xetex*, ... . The *-latex* version will
    be invoked regardless of whether *-la-* is omitted. Overrides template default
    engine (see below).

-e, \--eps
:   An output file in EPS format will be generated. Uses `dvips` if engine's native
    output is DVI or converts back from PDF using Ghostscript if that's the native
    output format.

-p, \--pdf
:   An output file in PDF format will be generated. If PDF is not the engine's
    native output, it will be converted from EPS using Ghostscript.

-s, \--svg
:   An output file in SVG format will be generated. Uses `pdftocairo` to render
    SVG from previously generated PDF.

-z, \--svgz
:   An output file in gzipped SVG format will be generated. Uses `gzip` on
    previously created SVG output.

-t *TEMPLATE*, \--template *TEMPLATE*
:   Specify the name of an installed template file, excluding file extension
    *.tex*. Template files are looked for in several standard locations; confer
    *TEMPLATES*. The default template is *article*.

-P *PREAMBLE-FILE*, \--preamble *PREAMBLE-FILE*
:   Specify relative or absolute path to an optional file containing custom
    preamble commands. Its contents replace the string *`THEPREAMBLE`* in the
    template file. This may be used to include additional LaTeX packages for use
    in axis / key labels, etc.

-i *INJECTION*, \--inject *INJECTION*
:   Specify (few) LaTeX commands to put immediately before `\input{...}` is
    invoked. More precisely, the string *`THEINJECTION`* in the template file will
    be replaced. Useful for changing font size, color, etc.

\--no-cleanup
:   Do not delete temporary working directory and print its path instead to
    allow for inspection of intermediate products.

Note that multiple output flags can be specified simulataneously. Short flags
may be combined into one token. E.g. `-ez` will result in EPS and SVGZ output.

# LaTeX ENGINE

The `--engine` flag can be used to specify the LaTeX engine used to typeset the
figure. The possible engines are not contraint by this script. Any command like
`latex`, `pdflatex`, `xelatex`, ... is a valid choice as long as it produces
native DVI or PDF output.

Since some templates require certain engines to be typeset properly, templates
(see below) may include a comment of the form:

    % TeX-engine: xelatex

This follows the conventions of the Emacs AUCTeX mode. If the `-la-` token is
omitted (e.g. `xetex`) it will be inserted automatically. Explicit specification
of the `--engine` flag will override this preset.

If neither `--engine` is specified, nor a template preset is defined, (or the
engine token was set to *default*), *`pdflatex`* will be used as the engine.

# TEMPLATES

The template files are looked up from a hierarchy of directories in the
following order:

* `$HOME/.latex-gnuplot/`
* `$PREFIX/share/latex-gnuplot/`
* `/usr/local/share/latex-gnuplot/`
* `/usr/share/latex-gnuplot/`

where `$PREFIX` is the install prefix that was set by passing the `--prefix`
option to the `install.sh` script.

For example, the default template is named `article`; specifying this
(`--template article`) will invoke the file `article.tex` which is installed to
the install prefix path. Template are supposed to use LaTeX packages or other
facilities to the effect of the *preview* package which allows to extract the
figure cropped to its dimensions.

A number of substitutions are performed on the template. At the very least,
templates should include a line

    \input{THEFILENAME}

where *`THEFILENAME`* is a token that is replaced by the name of the LaTeX
terminal's output file.

Templates can be further customized by replacing the token *`THEPREAMBLE`* with
the contents of a separate `.tex` file via the `--preamble` flag. Lastly, LaTeX
commands can be injected directly into the LaTeX source using the `--inject`
flag and will replace the token *`THEINJECTION`*.

# AUTHORS

Copyright (C) 2018  Jonas Greitemann

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

# SEE ALSO

The source code and *README* can be found on GitHub:

<https://github.com/jgreitemann/latex-gnuplot>

The documentation of the *preview* package is available on CTAN:

<https://www.ctan.org/tex-archive/macros/latex/contrib/preview/>
