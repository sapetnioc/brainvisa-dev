# -*- coding: utf-8 -*-
"""Functions used by release-management scripts."""


import itertools
import logging
import os
import pathlib
import re
import shlex
import sys

from brainvisa_cmake.components_definition import components_definition


logger = logging.getLogger(__name__)


def user_confirms(message, *, dry_run, dry_run_reply):
    if dry_run:
        logger.info('Dry-run: would ask "%s", assuming user replies "%s"',
                    message.strip(), 'y' if dry_run_reply else 'n')
        return dry_run_reply
    while True:
        answer = input(message)
        if answer.lower() == 'y':
            return True
        elif answer.lower() == 'n':
            return False
        elif answer.lower() == 'q':
            sure = user_confirms('Are you sure you want to quit? [y/n] ')
            if sure:
                sys.exit(1)
        print('Answer not recognized. Please try again [y/n/q].')


class SourceVersionError(Exception):
    """Exception for source version parse failures."""
    pass


def find_source_version_file_and_syntax(source_path):
    source_path = pathlib.Path(source_path)
    if (source_path / 'project_info.cmake').exists():
        return ('project_info.cmake', 'project_info.cmake')
    info_py_candidates = list(source_path.glob('*/info.py'))
    if info_py_candidates:
        if len(info_py_candidates) == 1:
            return (str(info_py_candidates[0].relative_to(source_path)), 'py')
    info_py_candidates = list(source_path.glob('python/*/info.py'))
    if info_py_candidates:
        if len(info_py_candidates) == 1:
            return (str(info_py_candidates[0].relative_to(source_path)), 'py')
    info_py_candidates = list(source_path.glob('info.py'))
    if info_py_candidates:
        if len(info_py_candidates) == 1:
            return (str(info_py_candidates[0].relative_to(source_path)), 'py')
    raise SourceVersionError(f'cannot find a version file in {source_path}')


# Each regex must have 3 groups: before the version number, the version number
# itself, and after the version number.
CMAKE_VERSION_REGEXPS = (
    re.compile(r'(\bset\s*\(\s*BRAINVISA_PACKAGE_VERSION_MAJOR\s*)'
               r'([0-9]+)(\s*\))',
               re.IGNORECASE),
    re.compile(r'(\bset\s*\(\s*BRAINVISA_PACKAGE_VERSION_MINOR\s*)'
               r'([0-9]+)(\s*\))',
               re.IGNORECASE),
    re.compile(r'(\bset\s*\(\s*BRAINVISA_PACKAGE_VERSION_PATCH\s*)'
               r'([0-9]+)(\s*\))',
               re.IGNORECASE),
)


PY_VERSION_REGEXPS = (
    re.compile(r'(\bversion_major\s*=\s*)([0-9]+)(\b)'),
    re.compile(r'(\bversion_minor\s*=\s*)([0-9]+)(\b)'),
    re.compile(r'(\bversion_micro\s*=\s*)([0-9]+)(\b)'),
)


def iterate_source_version_regexes(syntax):
    if syntax == 'project_info.cmake':
        regexps = CMAKE_VERSION_REGEXPS
    elif syntax == 'py':
        regexps = PY_VERSION_REGEXPS
    else:
        raise RuntimeError(f'unknown syntax {syntax}')
    for regex in regexps:
        yield regex


def get_source_version_components(source_path):
    version_file, syntax = find_source_version_file_and_syntax(source_path)
    with open(os.path.join(source_path, version_file), 'rt') as f:
        file_contents = f.read()
    for regex in iterate_source_version_regexes(syntax):
        match = regex.search(file_contents)
        if match is None:
            raise SourceVersionError(
                f'cannot find a version number component in {source_path} '
                f'(regex pattern: {regex.pattern})'
            )
        yield int(match.group(2))


def get_source_version_tuple(source_path):
    try:
        return tuple(get_source_version_components(source_path))
    except SourceVersionError as exc:
        logger.error(str(exc))
        return None


def set_source_version_tuple(source_path, version_tuple, *, dry_run=False):
    version_file, syntax = find_source_version_file_and_syntax(source_path)
    version_file_fullpath = os.path.join(source_path, version_file)
    with open(version_file_fullpath, 'rt') as f:
        file_contents = f.read()
    for regex, version_component in itertools.zip_longest(
            iterate_source_version_regexes(syntax), version_tuple):
        assert regex is not None and version_component is not None, \
            f'version_tuple has an incorrect length {len(version_tuple)}'
        file_contents, nsubs = regex.subn(f'\\g<1>{version_component:d}\\g<3>',
                                          file_contents)
        if nsubs != 1:
            logger.error(
                f'cannot substitute a version number component in '
                f'{source_path} ({nsubs:d} substitutions done, regex pattern: '
                f'{regex.pattern})'
            )
            return None
    if not dry_run:
        with open(version_file_fullpath, 'wt') as f:
            f.write(file_contents)
    return version_file


def set_version_number_and_commit(source_root, local_path,
                                  version_tuple, branch,
                                  gr, *,
                                  dry_run=True):
    major, minor, micro = version_tuple
    version_file = set_source_version_tuple(
        os.path.join(source_root, local_path),
        (major, minor, micro),
        dry_run=dry_run,
    )
    if version_file is None:
        logger.error('Could not bump the source version number in %s',
                     local_path)
        return
    cmd = ['git', 'add', version_file]
    if dry_run:
        logger.info('Dry-run: would now call %s',
                    ' '.join(shlex.quote(arg) for arg in cmd))
    else:
        retcode = gr.call_command(cmd, echo=True)
        gr.invalidate_cache()
        if retcode != 0:
            logger.error('Cannot index the version number bump in %s. '
                         'Leaving the repository in its current state',
                         os.path.join(local_path, version_file))
            return

    cmd = ['git', '--no-pager', 'diff', '--cached']
    if dry_run:
        logger.info('Dry-run: would now call %s',
                    ' '.join(shlex.quote(arg) for arg in cmd))
    else:
        gr.call_command(cmd, echo=True)
        if not user_confirms('Commit and push? [y/n/q] ',
                             dry_run=dry_run, dry_run_reply=True):
            return

    cmd = ['git', 'commit', '--no-verify', '-m',
           f'Bump version to {major:d}.{minor:d}.{micro:d}']
    if dry_run:
        logger.info('Dry-run: would now call %s',
                    ' '.join(shlex.quote(arg) for arg in cmd))
    else:
        retcode = gr.call_command(cmd, echo=True)
        gr.invalidate_cache()
        if retcode != 0:
            logger.error('Cannot commit the version number bump in %s. '
                         'Leaving the repository in its current state',
                         local_path)
            return
    cmd = ['git', 'push', 'origin',
           f'refs/heads/{branch}:refs/heads/{branch}']
    if dry_run:
        logger.info('Dry-run: would now call %s',
                    ' '.join(shlex.quote(arg) for arg in cmd))
    else:
        retcode = gr.call_command(cmd, echo=True)
        if retcode != 0:
            logger.error('Could not push the version number bump in %s',
                         local_path)
            return
        logger.info('Successfully bumped the version number in %s',
                    local_path)

    # We should merge also the version number bump into master (fake-merge
    # to avoid people messing up the version number on master)?
    # ...
    # Let's do this in a separate script to avoid adding complexity here.
