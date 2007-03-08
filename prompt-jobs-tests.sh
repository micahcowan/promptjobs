# prompt-jobs-tests.sh  written by Micah J Cowan <micah@cowan.name>

# Test suite for prompt-jobs.sh. Execute this script, DO NOT SOURCE

# dash has a bug in arithmetic expansions that causes this program to fail execution.
# Copyright (C) 2006  Micah J Cowan <micah@cowan.name>
# 
# Redistribution of this program in any form, with or without
# modifications, is permitted, provided that the above copyright is
# retained in distributions of this program in source form.

### Default settings

# Ensure that the terminal escapes will match up exactly, so we can
# do character-wise comparisons.
export TERMINFO=./terminfo

: ${PJOBS_SCRIPT:=./prompt-jobs.sh}
: ${PJTEST_SHELL:=${SHELL?:-sh}}
PJTEST_TOTAL_RUN=0
PJTEST_FAILED=0
PJTEST_SUCCEEDED=0
if [ ! "$PJTEST_TESTS" ]
then
    PJTEST_TESTS="
        execute
        no_awk
        no_tput
        nocolor_empty_prompt
        nocolor_prompt
        color_prompt
        special_chars
        prompt_split
        root_colors
    "
    if false    # set this to true to disable shell-specific tests.
    then
        :
    elif [ "$BASH_VERSION" ]
    then
        PJTEST_TESTS="$PJTEST_TESTS bash"
    elif [ "$ZSH_VERSION" ]
    then
        PJTEST_TESTS="$PJTEST_TESTS zsh"
    fi
fi

#   Zsh needs some tweaks.
if [ "$ZSH_VERSION" ]
then
    set -y
    unsetopt Function_ArgZero
fi

### Test facilities

assert()
{
    PJTEST_LINE=$1
    shift
    eval "$@" >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Assertion \"$*\" failed on line $PJTEST_LINE"
        exit 1
    fi
}

#   Quotemeta function
qm()
{
    echo "$1" | sed "s/'/'\\\\''/g; s/^/'/g; s/\$/'/g; s//\\\\033/g;"
}

#   Generate fake "jobs" output.
fake_jobs()
{
    job_i=1
    job_c='+'
    while read job
    do
        printf '[%d] %s %23s %s\n' $job_i $job_c 'Stopped' "$job"
        : $((job_i+=1))
        if [ $job_c = '+' ]; then job_c='-'; else job_c=' '; fi
    done
}

#   Get a prompt.
#       1: value for PS1, prior to running prompt-jobs.sh
#       2: terminal type
#       3..: commands to run
get_prompt()
{
    NEW_PS1="$1"
    shift
    NEW_TERM="$1"
    shift
    (
        exec 2>&1
        PATH="bin-test:$PATH"
        PS1="$NEW_PS1"
        TERM="$NEW_TERM"
        for cmd in "$@"; do echo "$cmd"; done | fake_jobs | \
            ( . "$PJOBS_SCRIPT" ; pjobs_gen_prompt )
    )
}

### Unit test functions

pjtest_execute()
{
    PJTEST_RESULT="$(sh "$PJOBS_SCRIPT" 2>&1 >/dev/null)"
    PJTEST_STATUS=$?
    assert $LINENO echo $(qm "$PJTEST_RESULT") \| \
        grep $(qm "^ERROR: This script should not")
    assert $LINENO [ $PJTEST_STATUS -ne 0 ]
}

pjtest_no_awk()
{
    PJTEST_RESULT="$( set +x; PATH=bin-no-awk . "$PJOBS_SCRIPT" 2>&1)"
    PJTEST_STATUS=$?
    assert $LINENO echo $(qm "$PJTEST_RESULT") \| \
        grep $(qm "^ERROR: Can't find awk")
    assert $LINENO [ $PJTEST_STATUS -eq 127 ]
}

pjtest_no_tput()
{
    PJTEST_RESULT="$( set +x; PATH=bin-no-tput . "$PJOBS_SCRIPT" 2>&1)"
    PJTEST_STATUS=$?
    assert $LINENO echo $(qm "$PJTEST_RESULT") \| \
        grep $(qm "^ERROR: Can't find tput")
    assert $LINENO [ $PJTEST_STATUS -eq 127 ]
}

pjtest_nocolor_empty_prompt()
{
    PJTEST_PROMPT=$(get_prompt '$ ' dumb)
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm '$ ') ]"
}

pjtest_nocolor_prompt()
{
    PJTEST_PROMPT=$(get_prompt '$ ' dumb 'cat' 'ls | less')
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm '(1:cat 2:ls)$ ') ]"
}

pjtest_color_prompt()
{
    PJOBS_BASE_TPUT='sgr0; setaf 4'   # signal prompt-jobs to use normal
                                      # intensity for base color.
    PJOBS_SEP_TPUT='sgr0; setaf 5'    # to distinguish from the base color.
    PJTEST_PROMPT=$(get_prompt '$ ' ansi cat 'ls | less')

    # Remove any escape-protections for the purpose of this test
    # (they'll be dealt with in the shell-specific tests).
    PJTEST_PROMPT=$(printf '%s' "$PJTEST_PROMPT" | sed 's/\\[][]\|%[{}]//g')

    BSQ='[0;10m[34m'
    SSQ='[0;10m[35m'
    NSQ='[1m[31m'
    JSQ='[1m[33m'
    CSQ='[0;10m'
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = \
                        "$(qm "${BSQ}${SSQ}(${NSQ}1${JSQ}cat${SSQ}|${NSQ}2${JSQ}ls${SSQ})${CSQ}${BSQ}$ ${CSQ}") ]"
}

pjtest_special_chars() {
    # Ensure that we use basenames, and don't allow escapes in the
    # output.
    PJTEST_PROMPT="$(get_prompt '$ ' dumb '/bin/echo' '\\ls')"
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm '(1:echo 2:ls)$ ')" ]
}

pjtest_prompt_split()
{
    # Make sure we put the joblist right before any final $, %, #.
    PJTEST_PROMPT="$(get_prompt 'micah$ ' dumb ls)"
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'micah(1:ls)$ ')" ]
    PJTEST_PROMPT="$(get_prompt 'micah$' dumb ls)" # w/o space
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'micah(1:ls)$')" ]
    PJTEST_PROMPT="$(get_prompt 'micah\$ ' dumb ls)" # With escape character
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'micah(1:ls)\$ ')" ]
    PJTEST_PROMPT="$(get_prompt 'micah%$ ' dumb ls)" # With zsh escape character
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'micah(1:ls)%$ ')" ]
    PJTEST_PROMPT="$(get_prompt 'micah% ' dumb ls)" # With csh-style prompt
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'micah(1:ls)% ')" ]
    PJTEST_PROMPT="$(get_prompt 'root# ' dumb ls)" # With root-style prompt
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = "$(qm 'root(1:ls)# ')" ]
}

pjtest_root_colors()
{
    # Make sure we get the stronger default colors as an "I'm in
    # root-mode" alert.
    PATH="./bin-fake-id:$PATH"   # Fake "id" command.

    PJTEST_PROMPT=$(get_prompt '$ ' ansi cat 'ls | less')

    # Remove any escape-protections for the purpose of this test
    # (they'll be dealt with in the shell-specific tests).
    PJTEST_PROMPT=$(printf '%s' "$PJTEST_PROMPT" | sed 's/\\[][]\|%[{}]//g')

    BSQ='[0;10m[31m'
    NSQ='[0;10m[32m'
    JSQ='[1m[33m'
    CSQ='[0;10m'
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = \
                        "$(qm "${BSQ}${BSQ}(${NSQ}1${JSQ}cat${BSQ}|${NSQ}2${JSQ}ls${BSQ})${CSQ}${BSQ}$ ${CSQ}") ]"
}

pjtest_bash()
{
    # Ensure we use the proper escape-sequence protection for bash.
    PJTEST_PROMPT=$(get_prompt '$ ' ansi cat 'ls | less')

    BSQ='\[[1m[34m\]'
    SSQ=$BSQ
    NSQ='\[[1m[31m\]'
    JSQ='\[[1m[33m\]'
    CSQ='\[[0;10m\]'
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = \
                        "$(qm "${BSQ}${SSQ}(${NSQ}1${JSQ}cat${SSQ}|${NSQ}2${JSQ}ls${SSQ})${CSQ}${BSQ}$ ${CSQ}") ]"
}

pjtest_zsh()
{
    # Ensure we use the proper escape-sequence protection for zsh.
    PJTEST_PROMPT=$(get_prompt '$ ' ansi cat 'ls | less')

    BSQ='%{[1m[34m%}'
    SSQ=$BSQ
    NSQ='%{[1m[31m%}'
    JSQ='%{[1m[33m%}'
    CSQ='%{[0;10m%}'
    assert $LINENO [ "$(qm "$PJTEST_PROMPT")" = \
                        "$(qm "${BSQ}${SSQ}(${NSQ}1${JSQ}cat${SSQ}|${NSQ}2${JSQ}ls${SSQ})${CSQ}${BSQ}$ ${CSQ}") ]"
}

### Run tests

for PJTEST_TEST in $PJTEST_TESTS
do
    echo "Running $PJTEST_TEST"
    ( pjtest_$PJTEST_TEST )
    if [ $? -eq 0 ]
    then
        : $((PJTEST_SUCCEEDED+=1))
    else
        : $((PJTEST_FAILED+=1))
    fi
    : $((PJTEST_TOTAL_RUN+=1))
done

PJTEST_RESULT_COLOR=2
if [ $PJTEST_FAILED -ne 0 ]
then
    PJTEST_RESULT_COLOR=1
fi

echo
echo "Total tests run: $PJTEST_TOTAL_RUN"
echo "Succeeded      : $PJTEST_SUCCEEDED"
tput setaf $PJTEST_RESULT_COLOR
tput bold
echo "Failed tests   : $PJTEST_FAILED"
tput sgr0

exit $PJTEST_FAILED
