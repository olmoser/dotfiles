"Builtin
set wrap
set tabstop=4
set shiftwidth=4
" set expandtab
set autoindent
set smartindent
set wildchar=<Tab>
set nonumber
set foldmethod=marker
set hidden
set wmh=0
set bg=dark
"set textwidth=120

filetype on

" Ermöglicht das Navigieren zwischen split Fenstern
" horizontal und vertikal
nmap <C-J> <C-W>j<C-W>_
nmap <C-K> <C-W>k<C-W>_
nmap <c-h> <c-w>h<c-w><bar>
nmap <c-l> <c-w>l<c-w><bar>

" Arbeiten in Terminalfenstern mit dunklem und hellem Hintergrund
" einfach umschalten mit F11 und F12
map <F10> :set bg=light<CR>
map <F9> :set bg=dark<CR>

" Esc ist soo weit weg - daher umschalten in Kommandomodus mit Shift-Leertaste
imap <S-Space> <Esc>

"Extras
"winmanager
"map <F2> :set pastetoggle<CR>
"taglist
map <F3> :Tlist<CR>

nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

"call togglebg#map("<F5>")

autocmd BufRead *.vala,*.vapi set efm=%f:%l.%c-%[%^:]%#:\ %t%[%^:]%#:\ %m
au BufRead,BufNewFile *.vala,*.vapi setfiletype vala

execute pathogen#infect()
"let g:solarized_termcolors=256
let g:solarized_termtrans=1
colorscheme solarized

filetype plugin indent on
syntax on

let g:vim_json_syntax_conceal = 0
nnoremap <F4> :set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣ list!<CR>
