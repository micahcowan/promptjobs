test: terminfo/a/ansi terminfo/d/dumb
	bash ./prompt-jobs-tests.sh

terminfo/a/ansi terminfo/d/dumb: terminfo.in
	TERMINFO=./terminfo tic terminfo.in
