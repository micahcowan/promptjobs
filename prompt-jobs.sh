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

# Escape backslashes for awk.
pjobs_esc()
{
    echo "$1" | sed 's/\\/\\\\/g'
}

pjobs_gen_joblist()
{
    "${PJOBS_AWK_PATH}" -v PJOBS_PRE_LIST_STR="$(pjobs_esc "$PJOBS_PRE_LIST_STR")" \
        -v PJOBS_MID_LIST_STR="$(pjobs_esc "$PJOBS_MID_LIST_STR")" \
        -v PJOBS_IN_JOBS_STR="$(pjobs_esc "$PJOBS_IN_JOBS_STR")" \
        -v PJOBS_POST_LIST_STR="$(pjobs_esc "$PJOBS_POST_LIST_STR")" \
        -v PJOBS_CLEAR_SEQ="$(pjobs_esc "$PJOBS_CLEAR_SEQ")" \
        -v PJOBS_BASE_SEQ="$(pjobs_esc "$PJOBS_BASE_SEQ")" -v PJOBS_NUM_SEQ="$(pjobs_esc "$PJOBS_NUM_SEQ")" \
        -v PJOBS_JOB_SEQ="$(pjobs_esc "$PJOBS_JOB_SEQ")" -v PJOBS_SEP_SEQ="$(pjobs_esc "$PJOBS_SEP_SEQ")" \
        -v PJOBS_ESCAPE_CHAR='\\' \
        '
BEGIN {
    started=0;
}

{
    rol = $0;

    # Find job id
    if (!match(rol, "^[[:space:]]*[[][[:space:]]*[[:digit:]]+[]]([[:space:]]*[+-])?"))
        next;
    
    job_id = substr(rol, 1, RLENGTH);
    rol = substr(rol, 1+RLENGTH);

    # Pare job id down to number
    match(job_id, "[[:digit:]]+");
    job_id = substr(job_id, RSTART, RLENGTH);

    # Find status (and require it to be "Stopped" or "Suspended")
    if (!match(rol, "^[[:space:]]*([Ss]topped|[Ss]uspended)[[:space:]]*(\\(SIG[^)]+\\))?"))
        next;
    rol = substr(rol, 1+RLENGTH);

    # Get first word
    if (!match(rol, "[^[:space:]]+"))
        next;
    cmdname = substr(rol, RSTART, RLENGTH);
    # Get a basename version
    if (match(cmdname, "[^/]*$"))
        cmdname = substr(cmdname, RSTART, RLENGTH);
    # Strip any escape characters
    new_cmdname="";
    for (i=1; i<=length(cmdname); ++i) {
        c = substr(cmdname, i, 1);
        if (c != PJOBS_ESCAPE_CHAR)
            new_cmdname = new_cmdname c;
    }
    cmdname = new_cmdname

    if (!started) {
        printf("%s", PJOBS_SEP_SEQ PJOBS_PRE_LIST_STR);
        started=1
    } else {
        printf("%s", PJOBS_SEP_SEQ PJOBS_MID_LIST_STR);
    }

    printf("%s%d%s", PJOBS_NUM_SEQ, job_id, PJOBS_IN_JOBS_STR PJOBS_JOB_SEQ cmdname);
}

END {
    if (started) {
        printf("%s", PJOBS_BASE_SEQ PJOBS_POST_LIST_STR PJOBS_CLEAR_SEQ);
    }
}
'
}

pjobs_gen_prompt()
{
    pjobs_gen_joblist
    printf '%s' "${PJOBS_BASE_SEQ}${PJOBS_ORIG_PS1}${PJOBS_CLEAR_SEQ}"
}

# Generate an escape sequence that will set a color/bold combo, given a
# color number and bold (as boolean).
pjobs_gen_seq()
{
    printf '%s' "$PJOBS_SEQ_PROTECT_START"
    if [ "$2" -eq 1 ]
    then
        "$PJOBS_TPUT_PATH" bold
    else
        "$PJOBS_TPUT_PATH" sgr0
    fi
    "$PJOBS_TPUT_PATH" setaf "$1"
    printf '%s' "$PJOBS_SEQ_PROTECT_END"
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
: ${PJOBS_AWK_PATH:="$(command -v awk 2>/dev/null)"}
if [ ! -x "$PJOBS_AWK_PATH" ]
then
    #   No awk.
    pjobs_warn "ERROR: Can't find awk! Please make sure that awk is in your path."
    return 127
fi

#   Do we have tput?
: ${PJOBS_TPUT_PATH:="$(command -v tput 2>/dev/null)"}
if [ ! -x "$PJOBS_TPUT_PATH" ]
then
    #   No tput.
    pjobs_warn "ERROR: Can't find tput! Please make sure that tput is in your path."
    return 127
fi

#   Do we have color?

"$PJOBS_TPUT_PATH" setaf 1 >/dev/null
if [ $? -eq 0 ]
then
    PJOBS_HAVE_COLOR=y
else
    PJOBS_HAVE_COLOR=n
fi

if [ "$PJOBS_HAVE_COLOR" = y ]
then
    # Figure out terminal-protecting sequences.
    # XXX: currently bash-specific.
    PJOBS_SEQ_PROTECT_START='\['
    PJOBS_SEQ_PROTECT_END='\]'
    
    : ${PJOBS_BASE_COLOR:=4}    # blue
    : ${PJOBS_BASE_BOLD:=1}     # bright
    : ${PJOBS_NUM_COLOR:=1}     # red
    : ${PJOBS_NUM_BOLD:=1}      # bright
    : ${PJOBS_JOB_COLOR:=3}     # yellow
    : ${PJOBS_JOB_BOLD:=1}      # bright
    : ${PJOBS_SEP_COLOR:="$PJOBS_BASE_COLOR"}
    : ${PJOBS_SEP_BOLD:="$PJOBS_BASE_BOLD"}

    # Generate coloring sequences: $PJOBS_BASE_SEQ, $PJOBS_NUM_SEQ, etc.
    for x in BASE NUM JOB SEP
    do
        eval "PJOBS_${x}_SEQ="'$(pjobs_gen_seq "$'"PJOBS_${x}_COLOR"'" "$'"PJOBS_${x}_BOLD"'")'
    done

    PJOBS_CLEAR_SEQ="${PJOBS_SEQ_PROTECT_START}$("$PJOBS_TPUT_PATH" sgr0)${PJOBS_SEQ_PROTECT_END}"
fi

### Guess workable defaults for config variables.

#   What is the current value of PS1?
: ${PJOBS_ORIG_PS1:="$PS1"}
: ${PJOBS_PRE_LIST_STR='('}
: ${PJOBS_POST_LIST_STR=')'}

# Define PJOBS_MID_LIST_STR; default differs depending on whether we have
# color.
if [ "$PJOBS_MID_LIST_STR" ]
then
    : # defined already. Do nothing.
elif [ "$PJOBS_HAVE_COLOR" = 'y' ]
then
    PJOBS_MID_LIST_STR='|'
else
    PJOBS_MID_LIST_STR=' '
fi

# Define PJOBS_IN_JOBS_STR; default differs depending on whether we have
# color.
if [ "$PJOBS_IN_JOBS_STR" ]
then
    : # defined already. Do nothing.
elif [ "$PJOBS_HAVE_COLOR" = 'y' ]
then
    PJOBS_IN_JOBS_STR=''
else
    PJOBS_IN_JOBS_STR=':'
fi

### Cleanup definitions

unset pjobs_warn
unset PJOBS_FORMAT

# XXX: bash-only:
PROMPT_COMMAND='PS1="$(jobs | pjobs_gen_prompt)"'
