set nocompatible              " be iMproved, required
filetype off                  " required

" https://github.com/junegunn/vim-plug#usage
call plug#begin('~/.vim/plugged')

" let Vundle manage Vundle, required
Plug 'gmarik/Vundle.vim'

" Fun stuff
Plug 'mhinz/vim-startify'
let g:ctrlp_reuse_window  = 'startify'

" In my ~/.vim/bundle dir, need to figure out why
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-dispatch'

" Git
Plug 'tpope/vim-fugitive'

" JavaScript
Plug 'pangloss/vim-javascript'

" JSON
Plug 'elzr/vim-json'

" Breaks indentation. Check https://github.com/mxw/vim-jsx/issues/120 and
" other issues.
" Plug 'mxw/vim-jsx'
Plug 'jelera/vim-javascript-syntax'
Plug 'marijnh/tern_for_vim'

Plug 'mustache/vim-mustache-handlebars'

" Styles
Plug 'wavded/vim-stylus'

" Clojure
Plug 'guns/vim-clojure-static'
Plug 'tpope/vim-fireplace'
Plug 'tpope/vim-leiningen'
Plug 'tpope/vim-sexp-mappings-for-regular-people'
Plug 'guns/vim-sexp'

" Convenience
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'

" activate indentation guides with <Leader>ig
Plug 'nathanaelkane/vim-indent-guides'

" automatically add closing delimiters
Plug 'Raimondi/delimitMate'

" The Silver Searcher plugin, Ag for searching
Plug 'rking/ag.vim'
" Search from the project root instead of the current directory
let g:ag_working_path_mode="r"
:command -nargs=* Search Ag --ignore-dir=node_modules "<args>"

" fuzzy file finder
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMRU'
" use the silver searcher to speed up indexing
let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden
      \ --ignore .git
      \ --ignore .svn
      \ --ignore .hg
      \ --ignore .DS_Store
      \ --ignore .idea
      \ --ignore node_modules
      \ --ignore "**/*.pyc"
      \ -g ""'

" Remove and show trailing whitespace
Plug 'ntpeters/vim-better-whitespace'
autocmd BufWritePre * StripWhitespace
" let g:better_whitespace_filetypes_blacklist+=['markdown']

Plug 'scrooloose/syntastic'
" This does what it says on the tin. It will check your file on open too, not
" just on save.
" You might not want this, so just leave it out if you don't.
let g:syntastic_check_on_open=1
let g:syntastic_javascript_checkers=['eslint']

Plug 'Valloric/YouCompleteMe'

" YCM gives you popups and splits by default that some people might not
" like, so these should tidy it up a bit.
let g:ycm_add_preview_to_completeopt=0
let g:ycm_confirm_extra_conf=0
set completeopt-=preview

" Use vim airline and disable powerline within vim
Plug 'bling/vim-airline'
let g:powerline_loaded = 1

" Initialize plugin system
call plug#end()

" Replaced by vim-airline, see above
" source /usr/local/lib/python2.7/site-packages/powerline/bindings/vim/plugin/powerline.vim
" set laststatus=2

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set t_Co=256
set background="dark"

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  colorscheme distinguished
  syntax on
  " Enable code folding (zi, zc, zo)
  set fdm=syntax
  set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")
  " Automatically open files with folds expanded
  " zi	switch folding on or off
  " za	toggle current fold open/closed
  " zc	close current fold
  " zR	open all folds
  " zM	close all folds
  " zv	expand folds to reveal cursor
  " Note, perl automatically sets foldmethod in the syntax file
  autocmd Syntax c,cpp,vim,xml,html,xhtml,javascript setlocal foldmethod=syntax
  autocmd Syntax c,cpp,vim,xml,html,xhtml,perl,javascript normal zR

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 120 characters.
  autocmd FileType text setlocal textwidth=80

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

set wrap linebreak nolist
set expandtab
set shiftwidth=2
set softtabstop=2

" Put temporary backup files in a place where I will not see them
set backupdir=~/.vim/tmp,.
set directory=~/.vim/tmp,.

let g:jsx_ext_required = 0 " Allow JSX in normal JS files
let g:syntastic_javascript_checkers = ['eslint']

" enable matchit
runtime macros/matchit.vim
