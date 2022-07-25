all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."

install:
	mkdir -p ~/.config/nvim
	#rm -f ~/.config/nvim/init.lua
	#cp init.vim ~/.config/nvim/init.vim
	rm -f ~/.config/nvim/init.vim
	cp init.lua ~/.config/nvim/init.lua
	cp -R lua/ ~/.config/nvim/lua
	cp -R after/ ~/.config/nvim
	cp -R ftdetect/ ~/.config/nvim
	cp -R ftplugin// ~/.config/nvim
	cp -R indent/ ~/.config/nvim
	cp -R syntax/ ~/.config/nvim
