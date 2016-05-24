all:
	@echo -e "Invoke\n  $$ make install\nto install configuration files."

install:
	@./install-vim_plug.sh
	mkdir -p ~/.config/nvim
	cp init.vim ~/.config/nvim/init.vim
	cp -R after/ ~/.config/nvim
	cp -R ftdetect/ ~/.config/nvim
	cp -R syntax/ ~/.config/nvim
