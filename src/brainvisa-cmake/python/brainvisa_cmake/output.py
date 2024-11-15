# -*- coding: utf-8 -*-

"""Output-related functions (encoding, redirection)."""

from __future__ import absolute_import, division
from __future__ import print_function, unicode_literals

import codecs
import io
import locale
import os
import sys

import six


ASCII_SUBSTITUTIONS = {
    ord('┌'): '/',
    ord('─'): '-',
    ord('│'): '|',
    ord('✓'): 'v',
    ord('✗'): 'X',
}


def _substitute_ascii_error_handler(error):
    """Unicode error handler that replaces a few characters with ASCII.

    Characters not in ASCII_SUBSTITUTIONS are handled by the 'replace' error
    handler (i.e. replaced by '?').
    """
    if isinstance(error, UnicodeEncodeError):
        unencodable = error.object[error.start:error.end]
        substitute = unencodable.translate(ASCII_SUBSTITUTIONS)
        replaced_substitute = substitute.encode(error.encoding, 'replace')
        if six.PY2:
            return (replaced_substitute.decode(error.encoding), error.end)
        return (replaced_substitute, error.end)
    else:
        raise error


codecs.register_error('substitute_ascii', _substitute_ascii_error_handler)


def reconfigure_stdout():
    """Reconfigure stdout so it does not crash on foreign Unicode characters.

    Also enable line-buffering, so that the output from print() and
    subprocesses will be interspersed correctly.
    """
    # Python 3.7 and later
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(errors='substitute_ascii', line_buffering=True)
        return

    try:
        fileno = sys.stdout.fileno()
    except (AttributeError, IOError):
        fileno = None

    # Under Python 2 many libraries (e.g. optparse) will try to write
    # strings of type 'str' to stdout, so we need to replace it with an
    # object that handles both unicode and str.
    if six.PY2:
        linebuf_stdout = sys.stdout
        if fileno is not None:
            linebuf_stdout = os.fdopen(fileno, 'w', 1)
        encoding = getattr(sys.stdout, 'encoding', None)
        if encoding is None:
            encoding = locale.getpreferredencoding()
        new_stdout = codecs.getwriter(encoding)(
            linebuf_stdout, errors='substitute_ascii')
    else:
        # Python 3.0 to 3.6
        new_stdout = io.open(fileno, mode='wt', buffering=1,
                             encoding=sys.stdout.encoding,
                             errors='substitute_ascii',
                             closefd=False)
    sys.stdout.flush()
    sys.stdout = new_stdout
