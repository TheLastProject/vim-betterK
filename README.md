## vim-betterK

vim comes with a K command, which runs a program to lookup the keyword under 
the cursor. However, by default, the K command uses man for everything.

vim-betterK improves the K command by using appropriate locally installed help 
viewers depending on the programming language in question, instead of using 
man for everything.

## How to use
vim-betterK overwrites the regular K command, functioning in the same way. Put 
your cursor on some text, or select some text in visual mode, and press K to 
get keyword information.

To call a specific manpage, regardless of the filetype-specific behaviour,
prefix K with a count. For example, to check out the selection in man 3, type
    3K

## How to install
If you're using Vundle, add `Plugin 'TheLastProject/vim-betterK'`

## Default viewers
C: man 3; man 2  
Haskell: hoogle; hoogle (online)  
Perl: perldoc  
PHP: pman  
Python: pydoc  
Ruby: ri  
sh: man 1  
vim: built-in :help  

## License
GPLv3+
