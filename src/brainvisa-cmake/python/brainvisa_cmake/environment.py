# -*- coding: utf-8 -*-

"""Utilities related to environment variables."""

from __future__ import absolute_import, division
from __future__ import print_function, unicode_literals

import re
import os

env_vars_regex = re.compile(r'\$([A-Za-z0-9_]*)')
python_vars_regex = re.compile(r'\%\(([A-Za-z0-9_]*)\)s')


def variablesSubstitution(parser, value, vars={}):
    result = value
    offset = 0
    for m in parser.finditer(value):
        content = vars.get(m.group(1))
        if content is not None:
            start, end = m.span()
            start += offset
            end += offset
            offset += len(content) - end + start
            result = result[:start] + content + result[end:]
    return result


def pythonVariablesSubstitution(value, python_vars={}):
    return variablesSubstitution(python_vars_regex, value, vars=python_vars)


def environmentVariablesSubstitution(value, env=None):
    if env is None:
        env = os.environ

    return variablesSubstitution(env_vars_regex, value, vars=env)


def environmentPathVariablesSubstitution(path, env=None):
    return normalize_path(environmentVariablesSubstitution(path, env))


class VarReplacementType:
    NO = 0
    PYTHON = 1
    ENV = 2
    ALL = PYTHON | ENV


def replace_vars(value,
                 replacement_type=VarReplacementType.ALL,
                 python_vars=None,
                 env_vars=None):
    result = value

    if python_vars and (replacement_type & VarReplacementType.PYTHON):
        # Uses python variable substitutions to allow partial replacements
        #print('replace_vars, replace_python_vars call', value, replacement_type)
        #result = result % python_vars
        result = pythonVariablesSubstitution(result, python_vars=python_vars)

    if env_vars and (replacement_type & VarReplacementType.ENV):
        #print('replace_vars, replace_env_vars call', value, replacement_type)
        # Replaces only environment variables
        result = environmentVariablesSubstitution(result, env = env_vars)

    return result


def normalize_path(path):
    file_scheme = 'file://'
    has_file_scheme = path.startswith(file_scheme)
    if has_file_scheme:
        # Remove file scheme
        path = path[len(file_scheme):]

    # Try to detect windows pathes starting with drive letters
    # for cross compilation.
    # TODO: check only for cross compiling mode
    if not (len(path) > 1 and path[1] == ':'):
        path = os.path.normpath(os.path.realpath(os.path.abspath(path)))

    if has_file_scheme:
        # Add file scheme
        path = file_scheme + path

    return path
