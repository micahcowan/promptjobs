# prompt-jobs-tests.sh  written by Micah J Cowan <micah@cowan.name>

# Test suite for prompt-jobs.sh. WARNING: may clutter the shell variable space.

# Copyright (C) 2006  Micah J Cowan <micah@cowan.name>
# 
# Redistribution of this program in any form, with or without
# modifications, is permitted, provided that the above copyright is
# retained in distributions of this program in source form.

### Default settings

: ${PJOBS_SCRIPT:=prompt-jobs.sh}
: ${PJTEST_TESTS=pjtest_execute}
PJTEST_TOTAL_RUN=0
PJTEST_FAILED=0
PJTEST_SUCCEEDED=0

### Test facilities

pjtest_assert()
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

### Unit test functions

pjtest_execute()
{
    PJTEST_RESULT="$(sh "$PJOBS_SCRIPT" 2>&1 >/dev/null)"
    PJTEST_STATUS=$?
    pjtest_assert $LINENO [ $? -ne 0 ]
    pjtest_assert $LINENO echo "$PJTEST_RESULT" \| \
        grep "^ERROR: this script should not"
}

### Run tests

for PJTEST_TEST in $PJTEST_TESTS
do
    ( $PJTEST_TEST )
    if [ $? -eq 0 ]
    then
        $((PJTEST_SUCCEEDED+=1))
    else
        $((PJTEST_FAILED+=1))
    fi
    $((PJTEST_TOTAL_RUN+=1))
done
