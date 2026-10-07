" by shpaq
" latest version 20231027
" updated 20261007

set nocompatible              " required
filetype off                  " required
set hidden
set showtabline=0

" plugins
call plug#begin('~/.config/nvim/plugged')
    Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }   " Project and file navigation
    Plug 'Xuyuanp/nerdtree-git-plugin'                        " NerdTree git functionality
    Plug 'majutsushi/tagbar'                                  " Class/module browser
    Plug 'mileszs/ack.vim'                                    " Ag/Grep
    Plug 'itchyny/lightline.vim'                              " Lean & mean status/tabline for vim
    Plug 'yuttie/comfortable-motion.vim'                      " Smooth scrolling
    Plug 'thaerkh/vim-indentguides'                           " Visual representation of indents
"    Plug 'Valloric/YouCompleteMe'                             " Code Completion
"    Plug 'codota/tabnine-nvim', { 'do': './dl_binaries.sh' }  " Code Completion
    Plug 'tpope/vim-surround'                                 " Parentheses, brackets, quotes, XML tags, and more
    Plug 'flazz/vim-colorschemes'                             " Colorschemes
    Plug 'ryanoasis/vim-devicons'                             " Dev Icons
    Plug 'mhinz/vim-startify'                                 " Vim Start Page
    Plug 'itchyny/vim-gitbranch'                              " Git stuff
    Plug 'airblade/vim-gitgutter'                             " Git stuff
    Plug 'junegunn/vim-easy-align'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }       " Fuzzy finder
    Plug 'junegunn/fzf.vim'                                   " Fuzzy finder
    Plug 'yuki-ycino/fzf-preview.vim', { 'branch': 'release/rpc' }
    Plug 'lepture/vim-jinja'
    Plug 'frazrepo/vim-rainbow'                               " Rainbow Parentheses
    Plug 'chrisbra/Colorizer'
    Plug 'sheerun/vim-polyglot'
    Plug 'maxboisvert/vim-simple-complete'
    Plug 'jiangmiao/auto-pairs'
    Plug 'derekwyatt/vim-protodef'
    " UltiSnips errors on every start when neovim has no python3 provider (pynvim)
    if has('python3')
        Plug 'SirVer/ultisnips'                               " Snippets Server
        Plug 'honza/vim-snippets'                             " Snippets are separated from the engine.
    endif
"    Plug 'saltstack/salt-vim'
call plug#end()

" All of your Plugins must be added before the following line
filetype on
filetype plugin on
filetype plugin indent on

" General settings
"set termencoding=UTF-8
set encoding=UTF-8
set fileencoding=UTF-8
set t_Co=256                                " 256 colors
syntax enable                               " enable syntax highlighting
set number                                  " show line numbers
set ruler
set ttyfast                                 " terminal acceleration
set showtabline=1                           " show tabs when present
set tabstop=4                               " 4 whitespaces for tabs visual presentation
set shiftwidth=4                            " shift lines by 4 spaces
set smarttab                                " set tabs for a shifttabs logic
set expandtab                               " expand tabs into spaces
set softtabstop=4

set autoindent                              " indent when moving to the next line while writing code
set cursorline                              " shows line under the cursor's line
set showmatch                               " shows matching part of bracket pairs (), [], {}

set noshowmode
set nobackup
set nowritebackup                           " only in case you don't want a backup file while editing
set noswapfile 	                            " no swap files

set nocompatible
set viminfo='20,\"50
set history=1000
set backspace=indent,eol,start              " backspace removes all (indents, EOLs, start) What is start?
set scrolloff=20                            " let 10 lines before/after cursor during scroll
if has('clipboard')
    set clipboard=unnamedplus               " use system clipboard when a provider exists
endif
set exrc                                    " enable usage of additional .vimrc files from working directory
set secure                                  " prohibit .vimrc files to execute shell, create files, etc...

set showcmd
"set browsedir=buffer
set wildmenu
set showmatch

set laststatus=2

set hidden
set tags+=./stl_tags
set foldtext=MineFoldText()
set foldminlines=6
set foldmethod=indent
set wildmode=longest:full:full
set wmnu
set ignorecase

let g:html_use_css = "1"
let g:calendar_monday = "1"
" fzf preview
let g:fzf_preview_use_dev_icons = 1
let g:fzf_preview_dev_icon_prefix_string_length = 3
let g:fzf_vim = {}
let g:fzf_vim.preview_window = ['hidden,right,50%,<70(up,40%)', 'ctrl-/']
let g:fzf_vim.buffers_jump = 1
let g:fzf_vim.commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
let g:fzf_vim.tags_command = 'ctags -R'

let stripTrailingWhitespace = 1

"" Search settings
set incsearch	                            " incremental search
set hlsearch	                            " highlight search results

"behave xterm

command Code2html :source $VIMRUNTIME/syntax/2html.vim|

fun RmCR()
	t oldLine=line('.')
	e ":%s/\r//g"
	xe ':' . oldLine
endfun

map <F2> :NERDTreeToggle<CR>
map <F3> zi
map <F4> :tabprev<CR>
map <F5> :tabnew<CR>
map <F6> :tabnext<CR>
map <F7> :r !date<CR>
map <F8> :TagbarToggle<CR>
map <F10> :q!<CR>
map <C-p> :FZF<CR>

let g:lightline = {
      \ 'colorscheme': 'deus',
      "\ 'colorscheme': 'powerline',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ }

"colorscheme 256-grayvim
"colorscheme Benokai
colorscheme wombat256dave
"colorscheme wombat256mod
"colorscheme tango-desert
"colorscheme jellybeans
let g:rainbow_active = 1

set wildcharm=<C-Z>
cnoremap <expr> <up> wildmenumode() ? "\<left>" : "\<up>"
cnoremap <expr> <down> wildmenumode() ? "\<right>" : "\<down>"
cnoremap <expr> <left> wildmenumode() ? "\<up>" : "\<left>"
cnoremap <expr> <right> wildmenumode() ? " \<bs>\<C-Z>" : "\<right>"

"remove all trailing whitespace for specified files before write
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces(0, 'n')

" Comfortable Motion Settings
let g:comfortable_motion_scroll_down_key = "j"
let g:comfortable_motion_scroll_up_key = "k"
let g:comfortable_motion_no_default_key_mappings = 1
let g:comfortable_motion_impulse_multiplier = 25  " Feel free to increase/decrease this value.
nnoremap <silent> <C-d> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * 2)<CR>
nnoremap <silent> <C-u> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -2)<CR>
nnoremap <silent> <C-f> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * 4)<CR>
nnoremap <silent> <C-b> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -4)<CR>

" Remove trailing whitespace
function <SID>StripTrailingWhitespaces(force, mode) range
    if a:force != 1 && g:stripTrailingWhitespace == 0
        return
    endif
if a:force == 1 || &ft =~ 'yaml\|json\|python\|rst\|wiki\|javascript\|css\|html\|xml' " Preparation: save last search, and cursor position.
        let _s=@/
        let l = line(".")
        let c = col(".")
        " Do the business:
        if a:mode == 'v'
            '<,'>s/\s\+$//e
        else
            %s/\s\+$//e
        endif
        " Clean up: restore previous search history, and cursor position
        let @/=_s
        call cursor(l, c)
    endif
endfunction
command -bang StripTrailingWhitespaces call <SID>StripTrailingWhitespaces(<bang>0, 'n')


let g:UltiSnipsExpandTrigger="<c-[>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

"lua <<EOF
"require('tabnine').setup({
"  disable_auto_comment=true,
"  accept_keymap="<c-p>",
"  dismiss_keymap = "<c-]>",
"  debounce_ms = 800,
"  suggestion_color = {gui = "#808080", cterm = 244},
"  exclude_filetypes = {"TelescopePrompt", "NvimTree"},
"  log_file_path = nil, -- absolute path to Tabnine log file
"})
"EOF
