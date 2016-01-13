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

let s:keywordhelpers = {
    \ 'c':
    \   [{'name': 'man 3', 'type': 'command', 'query': 'man 3 %s', 'error': 'No manual entry for'},
    \    {'name': 'man 2', 'type': 'command', 'query': 'man 2 %s', 'error': 'No manual entry for'}],
    \ 'haskell':
    \   [{'name': 'hoogle', 'type': 'command', 'query': 'hoogle search --info %s', 'error': 'No results found'},
    \    {'name': 'hoogle (online)', 'type': 'jsonurl', 'query': 'https://www.haskell.org/hoogle/?mode=json&hoogle=%s&count=1', 'result': 'results/0/docs'}],
    \ 'python':
    \   [{'name': 'pydoc', 'type': 'command', 'query': 'pydoc %s', 'error': 'no Python documentation found for'}],
    \ 'ruby':
    \   [{'name': 'ri', 'type': 'command', 'query': 'ri --format=rdoc %s'}]
    \ }

function! GetKeywordInfo(mode)
    "Grab the user selection
    if a:mode ==# 'n'
        let l:selection = expand('<cword>')
    elseif a:mode ==# 'v'
        "Public domain: http://stackoverflow.com/a/6271254
        let [lnum1, col1] = getpos("'<")[1:2]
        let [lnum2, col2] = getpos("'>")[1:2]
        let lines = getline(lnum1, lnum2)
        let lines[-1] = lines[-1][: col2 - (&selection ==# 'inclusive' ? 1 : 2)]
        let lines[0] = lines[0][col1 - 1:]
        let l:selection = join(lines, " ")
    else
        echo 'GetKeywordInfo was called with an invalid mode'
        return
    endif

    "Use the internal :help command for vim, instead of a third-party command
    if &filetype ==# 'vim'
        execute ':help ' . l:selection
    elseif has_key(s:keywordhelpers, &filetype)
        "Store possible failures to show the user if we get no result
        let l:helperfails = {}

        for helper in s:keywordhelpers[&filetype]
            "Prevent a key error
            if has_key(helper, 'error')
                let l:error = helper['error']
            else
                let l:error = ''
            endif

            "Execute proper type for command (currently, only one type exists)
            if helper['type'] ==# 'command'
                let l:result = s:RunKeywordLookupCommand(helper['query'], l:error, l:selection)
            elseif helper['type'] ==# 'jsonurl'
                let l:result = s:RunKeywordLookupJsonURL(helper['query'], helper['result'], l:error, l:selection)
            else
                let l:helperfails[helper['name']] = 'Invalid helper type'
                continue
            endif

            "Check if the command returned an error
            if l:result[0] != 0
                let l:helperfails[helper['name']] = l:result[1]
                continue
            endif

            "If we have an open buffer, clear it, otherwise create a new one
            "Based on code in http://www.vim.org/scripts/script.php?script_id=120
            if exists("s:betterkbufnr") && bufwinnr(s:betterkbufnr) > 0
                exe 'keepjumps ' . bufwinnr(s:betterkbufnr) . 'wincmd W'
                exe 'normal! ggdG'
            else
                exe 'keepjumps silent! new'
                let s:betterkbufnr = bufnr('%')
            end

            "Output result
            put = l:result[1]

            "Go to the top of the output
            exe 'normal! gg'

            "Make it temporary so it can be closed easily
            setlocal buftype=nofile bufhidden=wipe noswapfile

            "We have found and showed the user a result, we are done
            return
        endfor

        "No results could be found, tell the user what went wrong
        for [name, error] in items(l:helperfails)
            echo name . ': ' . error
        endfor
    else
        echo 'Sorry, no documentation helper known for ' . &filetype
    endif
endfunction

function! s:RunKeywordLookupCommand(query, error, selection)
    if !executable(split(a:query, ' ')[0])
        return [1, 'Cannot use, not installed']
    endif

    let l:result = system(substitute(a:query, '%s', shellescape(a:selection), ''))

    if v:shell_error != 0 || !empty(a:error) && l:result =~ a:error
        return [2, 'No result found for ' . a:selection]
    endif

    return [0, l:result]
endfunction

function! s:RunKeywordLookupJsonURL(query, result, error, selection)
    if !g:betterK_allow_online
        return [1, 'Online checks are disabled. Set g:betterK_allow_online to 1 to allow online checks']
    endif

    if !has('python3')
        return [2, 'Python 3 support is needed for JSON requests']
    endif

    if !executable('curl')
        return [3, 'Dependency curl is not installed']
    endif

    let l:result = system('curl -s ' . shellescape(substitute(a:query, '%s', a:selection, '')))

    let l:parsedresult = ''
    let l:jsonparsefailed = 0

python3 << EOF

import vim
import json
parsedJSON = json.loads(vim.eval('l:result'))
datalocation = vim.eval('a:result')

for part in datalocation.split('/'):
    try:
        part = int(part)
    except ValueError:
        pass

    try:
        parsedJSON = parsedJSON[part]
    except IndexError:
        vim.command('let l:jsonparsefailed = 1')
        break

vim.command('let l:parsedresult = "%s"' % parsedJSON)

EOF

    if v:shell_error != 0 || l:jsonparsefailed == 1 || !empty(a:error) && l:result =~ a:error
        return [4, 'No result found for ' . a:selection]
    endif

    return [0, l:parsedresult]
endfunction

"Set defaults
if !exists('g:betterK_allow_online')
    let g:betterK_allow_online = 0
endif

nnoremap K :call GetKeywordInfo('n')<CR>
vnoremap K :call GetKeywordInfo('v')<CR>
