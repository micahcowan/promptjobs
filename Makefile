TESTS=bash-test zsh-test

test: $(TESTS)
$(TESTS): terminfo/a/ansi terminfo/d/dumb

bash-test:
	@echo Running bash tests...
	bash ./prompt-jobs-tests.sh
	@echo

zsh-test:
	@echo Running zsh tests...
	zsh ./prompt-jobs-tests.sh
	@echo

terminfo/a/ansi terminfo/d/dumb: terminfo.in
	TERMINFO=./terminfo tic terminfo.in
