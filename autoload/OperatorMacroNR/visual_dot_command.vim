function! OperatorMacroNR#visual_dot_command#VisualModeDotCommand(type) abort
    " echom "Called VisualModeDotCommand() s:vcount1 = " . v:count1
    if a:type ==# 'v' || a:type ==# 'V'
        let l:line_begin = min([line("'<"), line("'>")])
        let l:line_end = max([line("'<"), line("'>")])
        execute "keepjumps " . l:line_begin . ',' . l:line_end . " global /.*/ normal " . v:count1 . "."
    elseif a:type ==# "\<C-v>"
        let l:single_column_activation = g:OperatorMacroNR_L_visual_block_single_column_mode_activation
        call OperatorMacroNR#util#AssertSingleColumnModeValidOption(l:single_column_activation)
        if l:single_column_activation == "never" ||
                \ ( l:single_column_activation == "smart" && virtcol("'<") !=# virtcol("'>") )
            try
                keepjumps silent NRV
            catch /.*/
                throw "Opening narrow region on visual selection failed with error: " . v:exception .
                            \ ". Abort VisualModeDotCommand."
            endtry
            " Note: we use 'normal' instead of 'normal!' to make this usable with Vim-repeat
            execute "keepjumps 1, $ normal " . v:count1 . "."
            silent wq
        elseif l:single_column_activation == "always" ||
                \ ( l:single_column_activation == "smart" && virtcol("'<") ==# virtcol("'>") )
            let l:final_curpos = getpos("'<")
            let l:line_begin = min([line("'<"), line("'>")])
            let l:line_end = max([line("'<"), line("'>")])
            execute "keepjumps " . l:line_begin . ',' . l:line_end . " global /.*/ normal :call s:ExecuteDotAtVirtcolWithCount(" . virtcol("'<") . ", " . v:count1 . ")\<CR>"
            call setpos(".", l:final_curpos)
        endif
    endif
endfunction

function! s:ExecuteDotAtVirtcolWithCount(virtcol, count)
    execute 'keepjumps normal! ' . a:virtcol . '|'
    " Note: we use 'normal' instead of 'normal!' to make this usable with Vim-repeat.
    execute 'keepjumps normal ' . a:count . '.'
endfunction
