function create_symlink {
	relative_path=$1
	[ -f $HOME/$1 ] && mv $HOME/$1 $HOME/$1.bak
	ln -s $HOME/dotfiles/$1 $HOME/$1
}

create_symlink .bashrc
create_symlink .gitconfig
create_symlink .config/i3/config
create_symlink .config/nvim
