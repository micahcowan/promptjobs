# prompt-jobs.sh    written by Micah J Cowan <micah@cowan.name>

# NOTE: this script is not intended to be executed (e.g., by "sh prompt-jobs.sh");
# rather, it is intended to be sourced directly into the currently running
# interactive shell (e.g., by ". ./prompt-jobs.sh").
# 
# This script automatically adjusts the shell prompt to include abbreviated
# information about currently stopped jobs (jobs that have been suspended to
# the background), within the prompt itself. It is designed to be safe to use
# for all terminals, and all Bourne shells that conform to the Single Unix
# Specification version 3, plus the extended ability to expand command
# substitutions within the PS1 shell variable. This script also relies
# on the shell having some ability to hook a command to be run for each
# prompt. In bash and zsh, this is accomplished via PROMPT_COMMAND and
# precmd(), respectively; in some other shells (ksh93 and pdksh), this
# is done via command substitition on the value of the special PS1
# variable. My understanding is that ksh88 (as opposed to the clone,
# pdksh) does not support command substitution, so this code is unlikely
# to work there.
#
# This code will refuse to enable color support if it does not recognize
# a shell that either provides support for protecting escape sequences
# (so that the shell isn't confused about the remaining space on a
# line). Color support can be forced (assuming a
# terminal supported by the "tput" command) by setting:
#       PJOBS_SEQ_PROTECT_START=''
#       PJOBS_SEQ_PROTECT_END=''
# (Or, if the shell does have escape-sequence protection characters, by
# specifying those in the corresponding values.)
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

### Preliminary Initialization

# Source any user-specific config

: ${PJOBS_CONFIG:=~/.pjobsrc}
if [ -f "$PJOBS_CONFIG" ]
then
    . "$PJOBS_CONFIG"
fi

# What shell is this?
unset PJOBS_BASH
unset PJOBS_DASH
unset PJOBS_PDKSH
unset PJOBS_KSH93
unset PJOBS_KSH
unset PJOBS_ZSH

if   [ "$BASH_VERSION" ];   then PJOBS_BASH=y
elif [ "$ZSH_VERSION" ];    then PJOBS_ZSH=y
elif [ "$KSH_VERSION" -a "${KSH_VERSION#'@(#)PD KSH'}" != "${KSH_VERSION}" ]
then
    PJOBS_PDKSH=y
    PJOBS_KSH=y
elif ( eval '[ "${.sh.version}"  ]' ) 2>/dev/null  # Non-ksh shells will complain
then
    PJOBS_KSH93=y
    PJOBS_KSH=y
fi

# Make sure we use prompt substitution in zsh
if [ "$PJOBS_ZSH" ]
then
    setopt prompt_subst prompt_percent
fi

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
        -v PJOBS_NUM_SEQ="$(pjobs_esc "$PJOBS_NUM_SEQ")" \
        -v PJOBS_JOB_SEQ="$(pjobs_esc "$PJOBS_JOB_SEQ")" \
        -v PJOBS_SEP_SEQ="$(pjobs_esc "$PJOBS_SEP_SEQ")" \
        -v PJOBS_ESCAPE_CHAR='\\' \
        '
BEGIN {
    started=0;
    spc = " \t\f\v";
    dgt = "0-9";
}

{
    rol = $0;

    # Find job id
    if (!match(rol, "^[" spc "]*[[][" spc "]*[" dgt "]+[]]([" spc "]*[+-])?"))
        next;
    
    job_id = substr(rol, 1, RLENGTH);
    rol = substr(rol, 1+RLENGTH);

    # Pare job id down to number
    match(job_id, "[" dgt "]+");
    job_id = substr(job_id, RSTART, RLENGTH);

    # Find status (and require it to be "Stopped" or "Suspended")
    if (!match(rol, "^[" spc "]*([Ss]topped|[Ss]uspended)[" spc "]*(\\(SIG[^)]+\\))?"))
        next;
    rol = substr(rol, 1+RLENGTH);

    # Get first word
    if (!match(rol, "[^" spc "]+"))
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
        printf("%s", PJOBS_SEP_SEQ PJOBS_POST_LIST_STR PJOBS_CLEAR_SEQ);
    }
}
'
}

pjobs_gen_prompt()
{
    printf '%s' "${PJOBS_KSH_PREFIX}${PJOBS_BASE_SEQ}${PJOBS_BEFORE_LIST}"
    pjobs_gen_joblist
}

# Generate an escape sequence from a semicolon-separated list of tput
# arguments.
pjobs_gen_seq()
{
    printf '%s' "$PJOBS_SEQ_PROTECT_START"
    printf '%s' "$1" | awk -v RS=';' '{ system("tput " $0) }'
    printf '%s' "$PJOBS_SEQ_PROTECT_END"
}

# Find where to put the jobs list. First arg should be 'pre' or 'post',
# second should be original prompt.
pjobs_get_list_loc()
{
    echo "$2" | "$PJOBS_AWK_PATH" -v PREPOST="$1" '
        BEGIN { buffer=""; spc=" \t\f\v\n"; }
        { buffer = buffer $0 "\n" }
        END {
            if ( match(buffer, "[%\\\\]?[%$#][" spc "]*$") ) {
                pre = substr(buffer,1,RSTART-1);
                post = substr(buffer,RSTART,RLENGTH);
            } else {
                pre = "";
                post = buffer;
            }
            printf("%s", PREPOST == "pre" ? pre : post);
        }
'
}

if [ "$PJOBS_ZSH" ]
then
    # We'll write our own version of the "jobs" command, since zsh's is
    # a nonstandard output format. Producing this intermediate format is
    # less efficient than simply using $jobstates, $jobtexts directly to
    # produce the prompt, but it allows us to easily reuse the logic that's
    # already in pjobs_gen_joblist().
    # 
    # We'll put it in a var, though, instead of standard output, so we
    # can run it in the current shell and access the value easily from
    # another.
    eval '
    pjobs_jobs()
    {
        PJOBS_JOBS=""
        for i in ${(k)jobstates}
        do
            if [ "${"${jobstates[$i]}"%%:*}" = "suspended" ]
            then
                # Note trailing newline
                PJOBS_JOBS="${PJOBS_JOBS}[$i]   Stopped ${jobtexts[$i]}
"
            fi
        done
    }'

    # Here's our pre-prompt hook.
    precmd()
    {
        pjobs_jobs
        PS1="$(printf '%s' "$PJOBS_JOBS" | pjobs_gen_prompt)"
    }
fi

### Try to detect our environment

#   Was this script executed?
if [ "$(basename -- "$0")" = prompt-jobs.sh ]
then
    if [ ! "$PJOBS_ZSH" ] || ( setopt | grep '^nofunctionargzero$' 2>&1 )
    then
        pjobs_warn "ERROR: This script should not be executed directly. Source it instead."
        exit 1
    # else: assume it's fine, since zsh sets argzero for inclusions by
    # default.
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

#   Find tput path.
: ${PJOBS_TPUT_PATH:="$(command -v tput 2>/dev/null)"}

#   Do we have color?
if [ "$PJOBS_HAVE_COLOR" -a "$PJOBS_HAVE_COLOR" != y ]
then
    : # User has specified that they don't want color.
elif [ ! -x "$PJOBS_TPUT_PATH" ]
then
    #   No tput.
    PJOBS_HAVE_COLOR=n
else
    "$PJOBS_TPUT_PATH" setaf 1 >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        PJOBS_HAVE_COLOR=y
    else
        PJOBS_HAVE_COLOR=n
    fi
fi

if [ "$PJOBS_HAVE_COLOR" = y ]
then
    # Figure out terminal-protecting sequences.
    PJOBS_KSH_PREFIX=''
    if [ "$PJOBS_BASH" ]
    then
        PJOBS_SEQ_PROTECT_START='\['
        PJOBS_SEQ_PROTECT_END='\]'
    elif [ "$PJOBS_ZSH" ]
    then
        PJOBS_SEQ_PROTECT_START='%{'
        PJOBS_SEQ_PROTECT_END='%}'
    elif [ "$PJOBS_KSH" ]
    then
        PJOBS_SEQ_PROTECT_START="$(printf '\017')"  # The SHIFT-OUT control.
        PJOBS_SEQ_PROTECT_END="$(printf '\017')"    # The SHIFT-OUT control.
        PJOBS_KSH_PREFIX="$(printf '\017\r')"           # Special sequence to define
                                                    # SHIFT-OUT as the
                                                    # escape protector.
    fi
    
    if [ "$(id -u)" -ne 0 ]
    then
        : ${PJOBS_BASE_TPUT='bold; setaf 4'} # bright blue
        : ${PJOBS_NUM_TPUT='bold; setaf 1'} # bright red
    else
        : ${PJOBS_BASE_TPUT='sgr0; setaf 1'} # red
        : ${PJOBS_NUM_TPUT='sgr0; setaf 2'} # green
    fi
    : ${PJOBS_JOB_TPUT='bold; setaf 3'} # bright yellow
    : ${PJOBS_SEP_TPUT="$PJOBS_BASE_TPUT"}

    # Generate coloring sequences: $PJOBS_BASE_SEQ, $PJOBS_NUM_SEQ, etc.
    for x in BASE NUM JOB SEP
    do
        eval "PJOBS_${x}_SEQ="'$(pjobs_gen_seq "$'"PJOBS_${x}_TPUT"'")'
    done

    PJOBS_CLEAR_SEQ="${PJOBS_SEQ_PROTECT_START}$("$PJOBS_TPUT_PATH" sgr0)${PJOBS_SEQ_PROTECT_END}"
fi

### Guess workable defaults for config variables.

#   What is the current value of PS1?
: ${PJOBS_ORIG_PS1="$PS1"}
: ${PJOBS_ORIG_PROMPT_COMMAND="$PROMPT_COMMAND"}
: ${PJOBS_PRE_LIST_STR='('}
: ${PJOBS_POST_LIST_STR=')'}
: ${PJOBS_BEFORE_LIST="$(pjobs_get_list_loc pre "$PJOBS_ORIG_PS1")"}
: ${PJOBS_AFTER_LIST="$(pjobs_get_list_loc post "$PJOBS_ORIG_PS1")"}

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

PS1='$(jobs | pjobs_gen_prompt)${PJOBS_BASE_SEQ}${PJOBS_AFTER_LIST}${PJOBS_CLEAR_SEQ}'
# The above line isn't sufficient for bash, because bash does it's
# prompt escape processing before it does command substitution. We'll
# use PROMPT_COMMAND to get the job done.
if [ "$PJOBS_BASH" ]
then
    PROMPT_COMMAND="PS1=\"\$(jobs | pjobs_gen_prompt)\"; PS1=\"\${PS1}\${PJOBS_BASE_SEQ}\${PJOBS_AFTER_LIST}\${PJOBS_CLEAR_SEQ}\""
    if [ "$PJOBS_ORIG_PROMPT_COMMAND" ]
    then
        PROMPT_COMMAND="$PJOBS_ORIG_PROMPT_COMMAND; $PROMPT_COMMAND"
    fi
fi
