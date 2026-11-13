.PHONY: all test test_file

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
	include Makefile-linux
endif
ifeq ($(UNAME), Darwin)
	include Makefile-macos
endif

all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."

# Headless tests (mini.test).  `-i NONE` keeps test runs out of the shada file.
NVIM_TEST := nvim --headless --noplugin -i NONE -u tests/minimal_init.lua

test: deps/mini.nvim
	$(NVIM_TEST) -c "lua MiniTest.run()"

# make test_file FILE=tests/test_harness.lua
test_file: deps/mini.nvim
	$(NVIM_TEST) -c "lua MiniTest.run_file('$(FILE)')"

deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@
