"by shpaq
"set termencoding=UTF-8
set encoding=UTF-8
set fileencoding=UTF-8
set noautoindent
set noshowmode
set backup
set backupdir=~/.vim/backup	        " Don't create backupfiles everywhere, but just in ~/.backup
set dir=~/.vim/backup
set nocompatible
set viminfo='20,\"50
set history=1000
set ruler
set showcmd
set incsearch
"set browsedir=buffer
set number
setlocal number
set wildmenu
set showmatch
set so=5
set laststatus=2
set hidden
set tags+=./stl_tags
set foldtext=MineFoldText()
set foldminlines=5
set foldmethod=indent
set wildmode=longest:full:full
set wmnu
set ignorecase
set t_Co=256
let g:html_use_css = "1"
let g:calendar_monday = "1"

let g:fzf_preview_use_dev_icons = 1
let g:fzf_preview_dev_icon_prefix_string_length = 3
let stripTrailingWhitespace = 1

"behave xterm

if &t_Co > 2 || has("gui_running")
        syntax on
        set hlsearch
endif
if has("gui_running")
    set nowrap
    set cursorline
		set ts=4
    set gfn=DejaVu\ Sans\ Mono\ 10
else
    set ts=4
endif

command Code2html :source $VIMRUNTIME/syntax/2html.vim|

if has("eval")
	filetype on
    filetype plugin on
endif

fun RmCR()
	t oldLine=line('.')
	e ":%s/\r//g"
	xe ':' . oldLine
endfun

map <F2> :NERDTreeToggle<CR>
map <F3> :FZF <CR>
map <F4> zi
map <F5> :tabnew <CR>
map <F6> :tabnext<CR>
map <F7> :r !date<CR>

call plug#begin('~/.config/nvim/plugged')
    Plug 'itchyny/lightline.vim'
    Plug 'itchyny/vim-gitbranch'
    Plug 'airblade/vim-gitgutter'
    Plug 'junegunn/vim-easy-align'
    Plug 'flazz/vim-colorschemes'
    Plug 'mhinz/vim-startify'
    Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'yuki-ycino/fzf-preview.vim', { 'branch': 'release/rpc' }
    Plug 'ryanoasis/vim-devicons'
    Plug 'lepture/vim-jinja'
    Plug 'frazrepo/vim-rainbow'
    Plug 'chrisbra/Colorizer'
    Plug 'sheerun/vim-polyglot'
    Plug 'maxboisvert/vim-simple-complete'
    Plug 'jiangmiao/auto-pairs'
    Plug 'matze/vim-move'
    Plug 'derekwyatt/vim-protodef'
call plug#end()

let g:lightline = {
      \ 'colorscheme': 'powerline',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ }

"colorscheme Benokai
colorscheme jellybeans
let g:rainbow_active = 1
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

set wildcharm=<C-Z>
cnoremap <expr> <up> wildmenumode() ? "\<left>" : "\<up>"
cnoremap <expr> <down> wildmenumode() ? "\<right>" : "\<down>"
cnoremap <expr> <left> wildmenumode() ? "\<up>" : "\<left>"
cnoremap <expr> <right> wildmenumode() ? " \<bs>\<C-Z>" : "\<right>"

"remove all trailing whitespace for specified files before write
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces(0, 'n')

" Remove trailing whitespace
function <SID>StripTrailingWhitespaces(force, mode) range
    if a:force != 1 && g:stripTrailingWhitespace == 0
        return
    endif

    if a:force == 1 || &ft =~ 'yaml\|json\|python\|rst\|wiki\|javascript\|css\|html\|xml'
        " Preparation: save last search, and cursor position.
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
let g:move_key_modifier = 'S'
let g:move_key_modifier_visualmode = 'S'
