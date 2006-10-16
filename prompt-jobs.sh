# prompt-jobs.sh    written by Micah Cowan

# NOTE: this script is not intended to be executed (e.g., by "sh prompt-jobs.sh");
# rather, it is intended to be sourced directly into the currently running
# interactive shell (e.g., by ". prompt-jobs.sh").

# This script automatically adjusts the shell prompt to include abbreviated
# information about currently stopped jobs (jobs that have been suspended to
# the background), within the prompt itself. It is designed to be safe to use
# for all terminals, and all Bourne shells that conform to the Single Unix
# Specification version 3, plus the extended ability to expand command
# substitutions within the PS1 shell variable (which is not required by SUSv3).
# This includes bash, zsh, ash, dash, and ksh (public domain and '93, but /not/
# 88).

# The settings used to create the prompt string may be configured by running or
# sourcing the prompt-jobs-config.sh script.

# This script assumes that it can write/overwrite to all shell variables whose
# names begin with PJOBS_ .
