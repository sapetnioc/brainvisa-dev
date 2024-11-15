# bv_env.sh: set the necessary BrainVISA environment variables in a shell.
#
# Usage
# =====
#
# In an interactive shell, you should be able to simply use:
#
#   . /somewhere/bin/bv_env.sh
#
# Otherwise, use one of the following two forms. The former works under most
# shells but this is not guaranteed by the POSIX standard, while the latter
# should work everywhere.
#
#   . /somewhere/bin/bv_env.sh /somewhere
#   PATH=/somewhere/bin:$PATH . bv_env.sh

# Create a temporary file with mktemp if available
bv_env_tempfile=$(mktemp -t bv_env.XXXXXXXXXX 2>/dev/null)

# Fall back to making up a file name
if ! [ -w "$bv_env_tempfile" ]
then
    bv_env_i=0
    bv_env_tempfile=${TMPDIR:-/tmp}/bv_env-$$-$bv_env_i
    while [ -e "$bv_env_tempfile" ]; do
        bv_env_i=$(($bv_env_i+1))
        bv_env_tempfile=${TMPDIR:-/tmp}/bv_env-$$-$bv_env_i
    done
    unset bv_env_i
    # Create the temporary file, making sure not to overwrite an existing file
    (umask 077 && set -C && : > "$bv_env_tempfile") || {
        echo "bv_env.sh: error creating $bv_env_tempfile, aborting" >&2
        unset bv_env_tempfile
        return 1
    }
fi

bv_env_cleanup() {
    rm -f "$bv_env_tempfile"
    unset bv_env bv_env_tempfile
}


# The core of this script is to "guess" the location of the bv_env executable,
# which is then used to generate the necessary environment variables. Several
# methods are tried in turn, the first which finds a useable bv_env wins.
bv_env=

# Method 1: the directory of the pack is given as a parameter. Note that this
# may not work in all shells (POSIX does not require the shell to accept
# positional parameters when sourcing a script).
if [ ! -x "$bv_env" ] && [ $# -eq 1 ]
then
    bv_env=$1/bin/bv_env
fi

# Method 2: the path to this script is passed as $0 (zsh does that).
if [ ! -x "$bv_env" ] && [ "$(basename -- "$0" 2>/dev/null)" = "bv_env.sh" ]
then
    bv_env=$(dirname -- "$0")/bv_env
fi

# Method 3: check for Conda installation
if [ ! -x "$bv_env" -a -x "$CONDA_PREFIX/src/brainvisa-cmake/bin/bv_env" ] ;
then
    bv_env="$CONDA_PREFIX/src/brainvisa-cmake/bin/bv_env"
fi

# Method 4: look for the path to bv_env.sh in the shell history.
if [ ! -x "$bv_env" ] && type fc > /dev/null 2>&1
then
    # Read the currently executing command using fc. fc needs to be run in the
    # current shell, so the following two solutions cannot work because they
    # invoke a subshell:
    #
    # - bv_env_sh_command=$(fc -ln -1)
    # - fc -ln -1 | read -r bv_env_sh_command
    fc -ln -1 >| "$bv_env_tempfile" 2> /dev/null

    # Field splitting is performed on the result of the command substitution,
    # hence each field is passed as a separate argument. Note that using the
    # construct $(< "$bv_env_tempfile") to spare a call to cat, although it is
    # advised by the bash manual, has unspecified behaviour under POSIX.
    for bv_env_arg in $(cat "$bv_env_tempfile"); do
        if [ "$(basename -- "$bv_env_arg")" = bv_env.sh ]; then
            bv_env=$(dirname -- "$bv_env_arg")/bv_env
        fi
    done
    unset bv_env_arg
    : >| "$bv_env_tempfile"  # truncate tempfile after use

    # If needed (e.g. path begins with ~), submit the path read from the
    # history to shell expansions using eval. Doing so in a sub-shell should
    # provide some isolation from potential side-effects of eval.
    if [ ! -x "$bv_env" ]; then
        bv_env=$(eval printf '%s' "$bv_env")
    fi
fi

# Method 5: see if bv_env can be found in $PATH, which is the case if this
# script was found during a PATH lookup, i.e. called as ". bv_env.sh".
if [ ! -x "$bv_env" ] && type bv_env > /dev/null 2>&1
then
    bv_env=$(which bv_env)
elif [ ! -x "$bv_env" ]
then
    # No method could find bv_env, give up.
    echo 'bv_env.sh: Error: cannot find the bv_env executable.' >&2
    echo 'bv_env.sh: Please pass the path to the BrainVISA pack:' >&2
    echo 'bv_env.sh:     . /somewhere/bin/bv_env.sh /somewhere' >&2
    echo 'bv_env.sh: or set your PATH to find bv_env:' >&2
    echo 'bv_env.sh:     PATH=/somewhere/bin:$PATH . bv_env.sh' >&2
    bv_env_cleanup
    return 1
fi


# Finally call bv_env, and source the result.
"$bv_env" >| "$bv_env_tempfile" || {
    echo "bv_env.sh: error while using $bv_env, aborting" >&2
    bv_env_cleanup
    return 1
}

. "$bv_env_tempfile" || {
    echo "bv_env.sh: error while sourcing the output of $bv_env" >&2
    bv_env_cleanup
    hash -r
    return 1
}

# initialize the bash completion compatibility layer in zsh
if autoload -U bashcompinit >/dev/null 2>&1; then
    bashcompinit
fi
# test the presence of the bash completion functions (compgen and complete)
if type compgen complete >/dev/null 2>&1; then
    if type realpath >/dev/null 2>&1; then
        bv_env=$(realpath "$bv_env")
    fi
    base_dir=$(dirname -- "$(dirname -- "$bv_env")")
    for d in "$base_dir/etc/bash_completion.d/"*; do
        if [ -f "$d" ]; then # if the dir is empty, we get an entry with *
            . "$d" || :  # an error in the completion script is not fatal
        fi
    done
    unset base_dir
fi

bv_env_cleanup

# Empty the cache of known command locations, which is necessary to take
# changes of $PATH into account under some shells.
hash -r
