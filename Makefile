.PHONY: all

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
	include Makefile-linux
endif
ifeq ($(UNAME), Darwin)
	include Makefile-macos
endif

all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."
