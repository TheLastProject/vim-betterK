"This program is free software: you can redistribute it and/or modify
"it under the terms of the GNU General Public License as published by
"the Free Software Foundation, either version 3 of the License, or
"(at your option) any later version.

"This program is distributed in the hope that it will be useful,
"but WITHOUT ANY WARRANTY; without even the implied warranty of
"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"GNU General Public License for more details.

"You should have received a copy of the GNU General Public License
"along with this program.  If not, see <http://www.gnu.org/licenses/>.

let s:keywordhelpers = {'haskell': 'hoogle search --info', 'python': 'pydoc', 'ruby': 'ri --format=rdoc'}
let s:failuretext = {'haskell': 'No results found', 'python': 'no Python documentation found for'}

function! GetKeywordInfo(mode)
    if a:mode ==# 'n'
        let s:selection = expand('<cword>')
    elseif a:mode ==# 'v'
		"Public domain: http://stackoverflow.com/a/6271254
		let [lnum1, col1] = getpos("'<")[1:2]
		let [lnum2, col2] = getpos("'>")[1:2]
		let lines = getline(lnum1, lnum2)
		let lines[-1] = lines[-1][: col2 - (&selection ==# 'inclusive' ? 1 : 2)]
		let lines[0] = lines[0][col1 - 1:]
		let s:selection = join(lines, " ")
	else
		return
	endif

    "Use the internal :help command for vim, instead of a third-party command
    if &filetype ==# 'vim'
        execute ':help ' . s:selection
    elseif has_key(s:keywordhelpers, &filetype)
        "Ensure app is installed
        if !executable(split(s:keywordhelpers[&filetype], ' ')[0])
            echo 'Please install ' . split(s:keywordhelpers[&filetype], ' ')[0] . ' for ' . &filetype . ' keyword lookups'
            return
        endif

        "Prevent screen glitching
		redraw

		"Run the helper
		let s:result = system(s:keywordhelpers[&filetype] . ' ' . shellescape(s:selection))

        "Don't put error in buffer
        if v:shell_error != 0 || has_key(s:failuretext, &filetype) && s:result =~ s:failuretext[&filetype]
            echo 'Sorry, no result found for ' . s:selection
            return
        endif

        "If we have an open buffer, clear it, otherwise create a new one
        "Based on code in http://www.vim.org/scripts/script.php?script_id=120
        if exists("t:betterkbufnr") && bufwinnr(t:betterkbufnr) > 0
            exe 'keepjumps ' . bufwinnr(t:betterkbufnr) . 'wincmd W'
            exe 'normal! ggdG'
        else
            exe 'keepjumps silent! new'
            let t:betterkbufnr = bufnr('%')
        end

        "Output result
        put = s:result

        "Go to the top of the output
        exe 'normal! gg'

        "Make it temporary so it can be closed easily
        setlocal buftype=nofile bufhidden=wipe noswapfile
    else
        echo 'Sorry, no documentation helper known for ' . &filetype
    endif
endfunction

nnoremap K :call GetKeywordInfo('n')<CR>
vnoremap K :call GetKeywordInfo('v')<CR>
