# -*- coding: utf-8 -*-
"""Tools for launching subprocesses from bv_maker."""

import locale
import os
import subprocess
import sys
import signal
import shlex


try:
    from subprocess import DEVNULL
except ImportError:
    DEVNULL = open(os.devnull, 'wb')


def decode_output(output_bytes):
    """Decode the output of subprocess.check_output to Unicode."""
    return output_bytes.decode(locale.getpreferredencoding())


def system(*args, **kwargs):
    print('$ ' + ' '.join(shlex.quote(arg) for arg in args))
    error = None
    try:
        try:
            kwargs = dict(kwargs)
            timeout = kwargs.pop('timeout', None)
            popen = subprocess.Popen(args, start_new_session=True, **kwargs)
            popen.communicate(timeout=timeout)
            if popen.returncode != 0:
                raise OSError()
        except subprocess.TimeoutExpired as e:
            print(f'Timeout for {args[0]} ({timeout}s) expired',
                  file=sys.stderr)
            print('Terminating the whole process group...', file=sys.stderr)
            #os.killpg(os.getpgid(popen.pid), signal.SIGTERM)
            error = (type(e), e, sys.exc_info()[2])
        except Exception as e:
            print('Command failed. Terminating the whole process group...',
                  file=sys.stderr)
            #os.killpg(os.getpgid(popen.pid), signal.SIGTERM)
            error = (type(e), e, sys.exc_info()[2])
    finally:
        try:
            os.killpg(os.getpgid(popen.pid), signal.SIGTERM)
        except ProcessLookupError:
            pass  # no children, it's OK
        if error:
            txt = 'Command failed: %s' % ' '.join((repr(i) for i in args))
            if 'cwd' in kwargs:
                txt = '%s\nFrom directory: %s' % (txt, kwargs['cwd'])
            if error[1].args:
                txt += f'\n{error[1].args[0]}'
            error = (error[0], error[0](txt, *error[1].args[1:]), error[2])
            raise error[0](txt, *error[1].args[1:]) from error[1]


def system_output_on_error(*args, **kwargs):
    # system_output_on_error is a bit strange currently:
    # on error an exception is raised and the output value is not passed
    # to the caller. Only stdout is used in this case, when the output
    # strings is actally useful in this situation.
    # However it should be in the exception e.output
    echo = kwargs.pop('echo', True)
    if echo:
        print(' '.join([str(x) for x in args]))
    try:
        # !!! Redirecting STDERR to STDOUT is a burden on Windows OS and
        # lead to enormous processing times using "wine" (x80) ... I do not
        # know why.
        # The issue can be reproduced using commands:
        # time python -c 'import subprocess;print subprocess.check_output(["winepath", "-u", "c:\\"]).strip()'
        # time python -c 'import subprocess;print subprocess.check_output(["winepath", "-u", "c:\\"], stderr=subprocess.STDOUT).strip()'
        output = subprocess.check_output(*args, stderr=subprocess.STDOUT,
                                         **kwargs)
    except subprocess.CalledProcessError as e:
        print('-- failed command: --')
        print('-- command:', args)
        print('-- popen kwargs:', kwargs)
        print('-- return code: %d, output: --' % e.returncode)
        print(e.output)
        print('-- end of command outpput --')
        raise

    if sys.version_info[0] >= 3:
        output = output.decode()

    return output
