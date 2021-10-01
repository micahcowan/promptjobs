# prompt jobs

prompt-jobs.sh is Bourne-ish shell code to colorize your shell prompt, and add a list of currently suspended shell jobs.

It will take a prompt like:

<pre style="background-color: black; color: silver; pading: 1em; width: 100%;">my-prompt$</pre>

and transform it like:

<pre><b>my-prompt(1 </b>man<b>|2 </b>ls<b>)$</b></pre>

(where “man” and “ls” are suspended jobs in the current shell). Except with color, too!

Demonstration video, courtesy of Asciinema (click the image to go to the video's page - however even the image itself is a decent sample transcript of using promoptjobs):

[![asciicast](https://asciinema.org/a/7410.svg)](https://asciinema.org/a/7410)

The colors and list decorations are customizable, and color can also be disabled (this happens automatically on terminals that don't advertise color support).

Only the **./prompt-jobs.sh** script is needed - the rest of the repository is devoted to test infrastructure, to ensure things run oon a variety of different Bourne-style shells.

To use the script, do not execute it; it must be sourced into your current shell environment:

```
. ./prompt-jobs.sh
```

(That’s “dot”, “space”, “dot slash prompt-jobs dot sh”.)

Once you’ve done that, your prompt should be immediately colored (if it wasn’t already). The shell script does its best to leave intact any special commands that were executed previously as part of your prompt.

Try starting a couple of shell jobs (such as `man man` or `ls | les`s, and then suspending them with `^Z`; you should see them show up in your prompt (resume them with `fg %1`, where 1 is the number of the job you wish to resume.

To automatically start your shell with these customizations, try putting the script in your home directory, as `.prompt-jobs.sh` (notice the leading dot, to hide it from normal directory listings), and then add something like the following to your `~/.profile`, `~/.bashrc`, `~/.kshrc`, `~/.zshrc`, or whatever’s appropriate for your environment:
```
    if [ -r ~/.prompt-jobs.sh ]; then
        . ~/.prompt-jobs.sh
    fi
```

The colors/graphical settings added to your prompt may be customized. Run the shell command `set | egrep '^PJOBS_.*(TPUT|LIST|STR)='` to get a list of customizable shell variables you can set (before sourcing `prompt-jobs.sh`), that will change the graphical effects and text decorations used for various bits of the customized prompt. The `TPUT` bits are semicolon (`;`)-separated terminfo capability names (which you can find in terminfo(5); `man 5 terminfo`); the other bits are used to indicate what characters surround and separate list elements with.

You can place custom settings of these variables in a file called `~/.pjobsrc`, and `prompt-jobs.sh` will source it automatically. To cause your changes to take effect, run the command `pjobs-remove`, and then re-source `prompt-jobs.sh` as you did before.

If you do not like color prompts, you can also set the variable PJOBS_HAVE_COLOR` to anything other than y, and pjobs will choose the uncolored version of the prompt.

`prompt-jobs.sh` has been tested on bash, ksh (both the modern and ’88 versions), zsh, and dash. It does not work with Bourne-incompatible shells like csh or tcsh, and can not work on shells that don’t provide a means to execute commands as part of the prompt (usually via `$(cmd)` expansion; or the `PROMPT_COMMAND` shell variable on bash).

NOTE: `prompt-jobs.sh` puts many (invisible) characters into the prompt, especially when color is used. Some shells, including bash and ksh, have been known to produce graphical glitches when moving around in shell history, or editing particularly large shell lines, if the prompt’s length (including the invisible characters) exceeds a certain length. If you experience these, consider simplifying the graphical effects you use in prompt-jobs.sh, or disabling the color support (as detailed above).

See the NOTES file for additional information.
