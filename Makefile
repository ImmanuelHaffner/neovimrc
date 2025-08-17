.PHONY: all install

all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."

install:
	# Remove existing configuration
	rm -rf ${HOME}/.config/nvim
	# Install configuration files
	install -D init.lua ${HOME}/.config/nvim/init.lua
	find lua/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find after/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find ftdetect/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find ftplugin/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find indent/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find syntax/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	find assets/ -type f -exec install -D {} ${HOME}/.config/nvim/{} \;
	# Install nvimdiff thin wrapper
	install -D -m 755 nvimdiff ${HOME}/.local/bin/nvimdiff
