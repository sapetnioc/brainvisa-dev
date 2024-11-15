# bv_unenv.sh: unset the environment which was set up by bv_env.sh in a shell.
#
# Usage:
#   . bv_unenv.sh

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
        echo "bv_unenv.sh: error creating $bv_env_tempfile, aborting" >&2
        unset bv_env_tempfile
        return 1
    }
fi

bv_env_cleanup() {
    rm -f "$bv_env_tempfile"
    unset bv_env_tempfile
}


# Contrary to bv_env.sh, we know that bv_unenv is in the PATH so we do not have
# to guess its location.
bv_unenv >| "$bv_env_tempfile" || {
    echo "bv_unenv.sh: error while using bv_unenv, aborting" >&2
    bv_env_cleanup
    return 1
}

. "$bv_env_tempfile" || {
    echo "bv_unenv.sh: error while sourcing the output of $bv_env" >&2
    bv_env_cleanup
    hash -r
    return 1
}

bv_env_cleanup

# Empty the cache of known command locations, which is necessary to take
# changes of $PATH into account under some shells.
hash -r