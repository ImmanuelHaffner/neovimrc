all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."

install:
	rm -rf ~/.config/nvim
	mkdir -p ~/.config/nvim
	cp init.lua ~/.config/nvim/init.lua
	cp -Rf lua/ ~/.config/nvim
	cp -Rf after/ ~/.config/nvim
	cp -Rf ftdetect/ ~/.config/nvim
	cp -Rf ftplugin// ~/.config/nvim
	cp -Rf indent/ ~/.config/nvim
	cp -Rf syntax/ ~/.config/nvim
	# Install nvimdiff thin wrapper
	mkdir -p ~/.local/bin
	cp nvimdiff ~/.local/bin
	chmod a+x ~/.local/bin/nvimdiff
	cp -Rf assets/ ~/.config/nvim
