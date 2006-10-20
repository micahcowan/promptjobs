# prompt-jobs.sh    written by Micah J Cowan <micah@cowan.name>

# NOTE: this script is not intended to be executed (e.g., by "sh prompt-jobs.sh");
# rather, it is intended to be sourced directly into the currently running
# interactive shell (e.g., by ". prompt-jobs.sh").
# 
# This script automatically adjusts the shell prompt to include abbreviated
# information about currently stopped jobs (jobs that have been suspended to
# the background), within the prompt itself. It is designed to be safe to use
# for all terminals, and all Bourne shells that conform to the Single Unix
# Specification version 3, plus the extended ability to expand command
# substitutions within the PS1 shell variable (which is not required by SUSv3).
# This includes bash, zsh, ash, dash, and ksh (public domain and '93, but /not/
# 88).
# 
# The settings used to create the prompt string may be configured by running or
# sourcing the prompt-jobs-config.sh script.
# 
# This script assumes that it can write/overwrite to all shell variables whose
# names begin with PJOBS_ or pjobs_ .

# Copyright (C) 2006  Micah J Cowan <micah@cowan.name>
# 
# Redistribution of this program in any form, with or without
# modifications, is permitted, provided that the above copyright is
# retained in distributions of this program in source form.

### Utility functions

pjobs_warn()
{
    PJOBS_FORMAT="$1\n"
    shift
    printf "$PJOBS_FORMAT" "$@" >&2
}

pjobs_gen_joblist()
{
    awk -v PJOBS_PRE_LIST_STR="$PJOBS_PRE_LIST_STR" \
        -v PJOBS_POST_LIST_STR="$PJOBS_POST_LIST_STR" '
BEGIN {
    started=0;
}

{
    rol = $0;

    # Find job id
    if (!match(rol, "^[[:space:]]*[[][[:space:]]*[[:digit:]]+[]]"))
        next;
    
    job_id = substr(rol, 1, RLENGTH);
    rol = substr(rol, 1+RLENGTH);

    # Pare job id down to number
    match(job_id, "[[:digit:]]+");
    job_id = substr(job_id, 1, RLENGTH);

    # Find status (and require it to be "Stopped" or "Suspended")
    if (!match(rol, "^[[:space:]]*(Stopped|Suspended)[[:space:]]*\\(SIG[^)]+\\)"))
        next;
    rol = substr(rol, 1+RLENGTH);

    # Get first word
    if (!match(rol, "[^[:space:]]+"))
        next;
    cmdname = substr(rol, RSTART, RLENGTH);

    if (!started) {
        printf("%s", PJOBS_PRE_LIST_STR);
        started=1
    } else {
        printf(" ");
    }

    printf("%d:%s", job_id, cmdname);
}

END {
    if (started) {
        printf("%s", PJOBS_POST_LIST_STR);
    }
}

### Functions

function print_job()
{
}
'
}

pjobs_gen_prompt()
{
    pjobs_gen_joblist
    printf '%s' "$PJOBS_ORIG_PS1"
}

### Try to detect our environment

#   Was this script executed?
if [ "$(basename "$0")" = prompt-jobs.sh ]
then
    pjobs_warn "ERROR: This script should not be executed directly. Source it instead."
    if [ "$ZSH_NAME" ]
    then
        pjobs_warn "Please run 'unsetopt Function_ArgZero' in zsh before sourcing this script."
        return 1
    else
        exit 1
    fi
fi

#   Do we have awk?
: ${PJOBS_AWK_PATH:=$(command -v awk 2>/dev/null)}
if [ ! -x "$PJOBS_AWK_PATH" ]
then
    #   No awk.
    pjobs_warn "ERROR: Can't find awk! Please make sure that awk is in your path."
    return 127
fi

#   Do we have tput?
: ${PJOBS_TPUT_PATH:=$(command -v tput 2>/dev/null)}
if [ ! -x "$PJOBS_TPUT_PATH" ]
then
    #   No tput.
    pjobs_warn "ERROR: Can't find tput! Please make sure that tput is in your path."
    return 127
fi

#   Do we have color?

### Guess workable defaults for config variables.

#   What is the current value of PS1?
: ${PJOBS_ORIG_PS1:=$PS1}
: ${PJOBS_PRE_LIST_STR='('}
: ${PJOBS_POST_LIST_STR=')'}

### Cleanup definitions

unset pjobs_warn
unset PJOBS_FORMAT
