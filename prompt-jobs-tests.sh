# prompt-jobs-tests.sh  written by Micah J Cowan <micah@cowan.name>

# Test suite for prompt-jobs.sh. Execute this script, DO NOT SOURCE

# dash has a bug in arithmetic expansions that causes this program to fail execution.
# Copyright (C) 2006  Micah J Cowan <micah@cowan.name>
# 
# Redistribution of this program in any form, with or without
# modifications, is permitted, provided that the above copyright is
# retained in distributions of this program in source form.

### Default settings

: ${PJOBS_SCRIPT:=./prompt-jobs.sh}
: ${PJTEST_TESTS=execute no_awk}
PJTEST_TOTAL_RUN=0
PJTEST_FAILED=0
PJTEST_SUCCEEDED=0

#   Zsh needs some tweaks.
if [ "$ZSH_NAME" ]
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
    echo "$1" | sed "s/'/'\\\\''/g; s/^\\|\$/'/g"
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
tput setaf $PJTEST_RESULT_COLOR
tput bold
echo "Total tests run: $PJTEST_TOTAL_RUN"
echo "Failed tests:    $PJTEST_FAILED"
echo "Succeeded   :    $PJTEST_SUCCEEDED"
tput sgr0

exit $PJTEST_FAILED
