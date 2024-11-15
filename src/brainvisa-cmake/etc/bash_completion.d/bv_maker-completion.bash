#/usr/bin/env bash

function _complete_bv_maker_()
{
    local word=${COMP_WORDS[COMP_CWORD]}
    local line=${COMP_LINE}
    local cmd_list="info sources configure build doc testref test pack install_pack testref_pack test_pack publish_pack status"
    local opt_list="-c -h -d -s -b --username -e --email --disable-jenkins --def --only-if-default -v --verbose --version"

    # get last subcommand
    local i=0
    local last_cmd=
    while [ $i -ne $COMP_CWORD ]; do
        local _cw=${COMP_WORDS[$i]}
        i=$(( i + 1 ))
        local j=0
        for j in $cmd_list; do
            if [ "$_cw" = "$j" ]; then
                last_cmd="$j"
                break
            fi
        done
    done

#     if [ -n "$last_cmd" ]; then
#         echo "last cmd: $last_cmd"
#     fi

    # options are specific to each subcommand
    case "$last_cmd" in
    info)
        opt_list="-h --help --only-if-default"
        ;;
    sources)
        opt_list="-h --help --only-if-default --no-cleanup --no-svn --no-git --ignore-git-failure"
        ;;
    configure)
        opt_list="-h --help -c --clean --only-if-default"
        ;;
    build)
        opt_list="-h --help -c --clean --only-if-default"
        ;;
    doc)
        opt_list="-h --help --only-if-default"
        ;;
    testref)
        opt_list="-h --help --only-if-default -m --make_options"
        ;;
    test)
        opt_list="-h --help --only-if-default -t --ctest_options"
        ;;
    pack)
        opt_list="-h --help --only-if-default"
        ;;
    install_pack)
        opt_list="-h --help --only-if-default --package-date --package-time --package-version --prefix --local --offline"
        ;;
    testref_pack)
        opt_list="-h --help --only-if-default -m --make_options --package-date --package-time --package-version"
        ;;
    test_pack)
        opt_list="-h --help --only-if-default -t --ctest_options --package-date --package-time --package-version"
        ;;
    status)
        opt_list="-h --help --only-if-default --no-svn --no-git"
        ;;
    *)
        ;;
    esac

    COMPREPLY=($(compgen -W "$cmd_list $opt_list" -- "${word}"))
    if [ -n "$COMPREPLY" ]; then
        COMPREPLY="$COMPREPLY "
    fi

#     case "$COMP_CWORD" in
#     1)
#         COMPREPLY=($(compgen -W "$cmd_list $opt_list" -- "${word}"))
#         ;;
#     *)
#         local cmd=${COMP_WORDS[1]}
#
#         case "$cmd" in
#         info)
#             ;;
#         sources)
#             ;;
#         configure)
#             ;;
#         build)
#             ;;
#         doc)
#             ;;
#         testref)
#             ;;
#         test)
#             ;;
#         pack)
#             ;;
#         install_pack)
#             ;;
#         testref_pack)
#             ;;
#         test_pack)
#             ;;
#         publish_pack)
#             ;;
#         esac
#     esac

#     if [ -z "$COMPREPLY" ]; then
#         COMPREPLY=($(compgen -f -- "${word}"))
#     fi
}


# complete -W "info sources configure build doc testref test pack install_pack testref_pack test_pack publish_pack -c -h -d -s -b --username -e --email --disable-jenkins --def --only-if-default -v --verbose --version" bv_maker

complete -F _complete_bv_maker_ -o default -o nospace bv_maker
