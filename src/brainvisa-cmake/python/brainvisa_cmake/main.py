# -*- coding: utf-8 -*-

"""Main procedure of the bv_maker command-line tool."""

import multiprocessing
import os
import sys
import traceback

from brainvisa_cmake.build import check_ld_library_path_error
import brainvisa_cmake.commands
import brainvisa_cmake.configuration
import brainvisa_cmake.output


def main():
    """Main procedure of the bv_maker command-line tool."""

    brainvisa_cmake.output.reconfigure_stdout()

    # export cpu_count() as NCPU env variable so that it can be used in conf file
    # for env replacements
    try:
        os.environ['NCPU'] = str(multiprocessing.cpu_count())
    except NotImplementedError:
        # multiprocessing.cpu_count can raise NotImplementedError
        os.environ['NCPU'] = '1'

    check_ld_library_path_error(fatal=False)


    default_commands = ['info', 'sources', 'configure', 'build', 'doc', 'test',
                        'pack', 'install_pack', 'test_pack']
    options_by_command = {None: []}
    command = None
    for i in sys.argv[1:]:
        if i in brainvisa_cmake.commands.COMMANDS:
            command = i
            if command in options_by_command:
                raise ValueError('Command %s used twice' % command)
            options_by_command[command] = []
        else:
            options_by_command[command].append(i)

    # Initialize global configuration
    configuration = brainvisa_cmake.configuration.GlobalConfiguration(options_by_command[None])

    # Parse commands options and prepare them for processing in the correct order
    todo = []
    if len(options_by_command) == 1:
        # No command selected => do all default commands
        for i in default_commands:
            options_by_command[i] = ['--only-if-default']

    log_something = False
    # Ordered command list
    for command in ['info', 'status', 'sources', 'configure', 'build',
                    'doc', 'test', 'testref', 'pack', 'install_pack', 'test_pack',
                    'testref_pack', 'publish_pack']:
        if command in options_by_command:
            command_class = brainvisa_cmake.commands.COMMANDS[command]
            todo.append(
                command_class(options_by_command[command], configuration))
            if command not in ('info', 'status') \
                    and '-h' not in options_by_command[command] \
                    and '--help' not in options_by_command[command]:
                log_something = True

    failed = False
    # Execute selected commands
    try:
        for f in todo:
            f()
    except KeyboardInterrupt:
        traceback.print_exc()
        failed = True

    failed = display_failure_summary(configuration) or failed

    return 1 if failed else 0


def display_failure_summary(configuration):
    sections = [('sourcesDirectories', ['sources']),
                ('buildDirectories', ['configure', 'build', 'doc', 'testref',
                                      'test']),
                ('packageDirectories', ['pack', 'install_pack', 'testref_pack',
                                        'test_pack']),
                ('publicationDirectories', ['publish_pack']),
                ]
    global_failed = False
    status_map = {'not run': '',
                  'succeeded': 'OK         ',
                  'failed': 'FAILED     ',
                  'unmet dependency': 'UNMET DEP  ',
                  'interrupted': 'INTERRUPTED'}
    sys.stdout.flush()
    sys.stderr.flush()
    messages = ['\nbv_maker summary:']
    print(messages[0])
    first_start = None
    for section_name, steps in sections:
        for section in getattr(configuration, section_name).values():
            for step in steps:
                status = status_map[section.get_status(step)]
                if status != '':
                    message = '%s step %s: %s' % (status, step,
                                                  section.directory)
                    start = section.start_time.get(step)
                    if start:
                        if first_start is None:
                            first_start = start
                        message += ', started: %04d/%02d/%02d %02d:%02d' \
                            % start[:5]
                    stop = section.stop_time.get(step)
                    if stop:
                        last_stop = stop
                        message += ', stopped: %04d/%02d/%02d %02d:%02d' \
                            % stop[:5]
                    messages.append(message)
                    print(message)
                    if section.has_failed(step):
                        global_failed = True
    if global_failed:
        status = 'There were errors.'
        print(status)
    else:
        status = 'All went good.'
        print(status)
    return global_failed
