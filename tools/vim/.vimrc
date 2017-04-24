scriptencoding utf-8
set encoding=utf-8
"http://stackoverflow.com/a/18321539


""set tabstop=4
""set softtabstop=0 noexpandtab
""set shiftwidth=4

"For indents that consist of 4 space characters but are entered with the tab key:
"http://stackoverflow.com/a/1878983
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

""set list
"http://stackoverflow.com/a/29787362http://stackoverflow.com/a/1675752
""set list listchars=eol:$,tab:>·,trail:~,extends:>,precedes:<,space:·
""if has("patch-7.4.710")
    ""set list listchars=eol:$,tab:>.,trail:~,extends:>,precedes:<,space:_
""else
""set list listchars=eol:$,tab:>.,trail:~,extends:>,precedes:<
""set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵
""endif:

"http://stackoverflow.com/a/356130
autocmd BufWritePre *.py :%s/\s\+$//e

"http://www.vim.org/scripts/script.php?script_id=2332
"https://github.com/tpope/vim-pathogen#runtime-path-manipulation
execute pathogen#infect()
syntax on
filetype plugin indent on
