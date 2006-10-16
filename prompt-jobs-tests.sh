# prompt-jobs-tests.sh  written by Micah J Cowan <micah@cowan.name>

# Test suite for prompt-jobs.sh. Execute this script, DO NOT SOURCE

# Copyright (C) 2006  Micah J Cowan <micah@cowan.name>
# 
# Redistribution of this program in any form, with or without
# modifications, is permitted, provided that the above copyright is
# retained in distributions of this program in source form.

### Default settings

: ${PJOBS_SCRIPT:=prompt-jobs.sh}
: ${PJTEST_TESTS=execute no_path}
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
    pjtest_assert $LINENO echo '"$PJTEST_RESULT"' \| \
        grep "'^ERROR: This script should not'"
    pjtest_assert $LINENO [ $PJTEST_STATUS -ne 0 ]
}

pjtest_no_path()
{
    PJTEST_RESULT="$( set +x ;PJOBS_AWK_PATH=/usr/bloop/bin/foo . "$PJOBS_SCRIPT" 2>&1)"
    PJTEST_STATUS=$?
    pjtest_assert $LINENO echo '"$PJTEST_RESULT"' \| \
        grep '"^ERROR: Can'\''t find awk"'
    pjtest_assert $LINENO [ $PJTEST_STATUS -eq 127 ]
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
