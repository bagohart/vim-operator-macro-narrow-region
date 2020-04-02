" Use those workaround functions to deal with Vim's operator interface {{{
function! OperatorMacroNR#operator_linewise#OperatorLinewiseVisualMode() abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(v:register, g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "linewise")
    call OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute(visualmode(), l:use_this_register, v:count1)
endfunction

function! OperatorMacroNR#operator_linewise#OperatorLinewise(type) abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(g:OperatorMacroNR_internals["vregister"], g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "linewise")
    call OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute(a:type, l:use_this_register, g:OperatorMacroNR_internals["v:count1"])
endfunction
" }}}

" Repeat tricks. Kids, don't do this at home. {{{
function! OperatorMacroNR#operator_linewise#OperatorLinewiseRepeat() abort
    " echom "op linewise repeat!"
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    normal! .
endfunction

function! OperatorMacroNR#operator_linewise#OperatorLinewiseRepeatVisual() abort
    " echom "op linewise repeat visual!"
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    execute "normal! 1v\<Esc>"
    call OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute(visualmode(), g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"])
endfunction
" }}}

let s:operator_macro_linewise_recursion_level = 0

" Operator linewise core functionality {{{
function! OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute(type, register, count) abort
    " echom "Called OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute() with type= "
                \ . a:type . ", register=" . a:register . ", count=" . a:count 
    " echom "recursionlevel" . s:operator_macro_linewise_recursion_level
    let s:operator_macro_linewise_recursion_level += 1
    if s:operator_macro_linewise_recursion_level ># g:OperatorMacroNR_LNO_recursion_depth_limit
        throw "operator macro linewise recursion level too big. Abort..."
    endif

    let l:backup_visual_selection_shape = OperatorMacroNR#util#BackupVisualSelectionShape()

    try
        if a:type ==# 'char' || a:type ==# 'line'
            " call OperatorMacroNR#util#PrintYankedSelection()
            call OperatorMacroNR#util#SetVisualSelectionMarksToYankedSelectionMarks(a:type)
            let l:selection_start_pos =  getpos("'<")
            let l:selection_end_pos =  getpos("'>")
            " call OperatorMacroNR#util#PrintVisualSelection()
            call s:ExecuteMacroOnVisualSelectionLinewise(a:register, a:count,
                        \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation)
            call repeat#set("\<Plug>(operator-macro-linewise-repeat)")
        elseif a:type ==# 'v' || a:type ==# 'V'
            " call OperatorMacroNR#util#PrintVisualSelection()
            call s:ExecuteMacroOnVisualSelectionLinewise(a:register, a:count,
                        \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation)
            call repeat#set("\<Plug>(operator-macro-linewise-repeat-visual)")
        elseif a:type ==# "\<C-v>"
            " call OperatorMacroNR#util#PrintVisualSelection()
            let l:single_column_activation = g:OperatorMacroNR_L_visual_block_single_column_mode_activation
            call OperatorMacroNR#util#AssertSingleColumnModeValidOption(l:single_column_activation)
            if l:single_column_activation == "never" ||
                    \ ( l:single_column_activation == "smart" && virtcol("'<") !=# virtcol("'>") )
                call s:ExecuteMacroOnVisualSelectionLinewise(a:register, a:count,
                            \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation)
            elseif l:single_column_activation == "always" ||
                    \ ( l:single_column_activation == "smart" && virtcol("'<") ==# virtcol("'>") )
                " echom "Call ExecuteMacroOnVisualSelectionLinewiseSingleColumn() with vcol=" . virtcol("'<")
                call s:ExecuteMacroOnVisualSelectionLinewiseSingleColumn(a:register, a:count, 
                            \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation, virtcol("'<"))
            endif
            call repeat#set("\<Plug>(operator-macro-linewise-repeat-visual)")
        else
            " If this ever happens, the plugin is broken or someone tried to call the function directly.
            throw "Running OperatorLinewiseMacroExecute() with unrecognized type=" . a:type
        endif

        call OperatorMacroNR#util#RestoreVisualSelectionShape(l:backup_visual_selection_shape)
        call setpos(".", getpos("'["))
    finally
        let s:operator_macro_linewise_recursion_level -= 1
    endtry
endfunction

function! s:ExecuteMacroOnVisualSelectionLinewise(register, count, close)
    try
        let original_buffer_number = bufnr()
        keepjumps silent NRV
        let narrowed_region_buffer_number = bufnr()
    catch /.*/
        throw "Opening narrow region on visual selection failed with error: " . v:exception .
                    \ ". Abort linewise macro execution."
    endtry
    try
        let l:num_selected_lines = line("$")
        for i in range(1, l:num_selected_lines)
            execute "keepjumps normal! V\<Esc>"
            " This is necessary to mimic the behaviour of :'<,'> normal @{register},
            " which also continues after an error.
            try
                call OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtStart(a:register, a:count, 1)
                " sometimes, NarrowRegion doesn't handle nested narrowed regions correctly.
                " We can't fix this, but we can prevent further damage here.
                let error_dont_close = 0
                if narrowed_region_buffer_number != bufnr()
                    echom "There was an error with nested narrowed regions." .
                                \ "Abort Operator-Macro-Narrow-Region and try to switch back to " .
                                \ "original buffer with number " . original_buffer_number
                    " buffer! original_buffer_number
                    execute original_buffer_number . "buffer! "
                    let error_dont_close = 1
                    return
                endif
            catch /.*/
                echom "Error occurred during execution of macro " . getreg(a:register, 1) . " in register " .
                            \ a:register . " on line " . i . ": " . v:exception . ". Continue on next line..."
            endtry
            keepjumps normal! `]j
        endfor
    finally
        if a:close && !error_dont_close
            " todo: check this first if something wrt narrow region ever fails unexpectedly
            silent wq
        endif
    endtry
endfunction

function! s:ExecuteMacroOnVisualSelectionLinewiseSingleColumn(register, count, close, vcol)
    " echom "Called s:ExecuteMacroOnVisualSelectionLinewiseSingleColumn() with vcol=" . a:vcol
    execute "keepjumps normal! `<V`>\<Esc>"
    try
        keepjumps silent NRV
    catch /.*/
        throw "Opening narrow region on visual selection failed with error: " . v:exception
    endtry
    try
        let l:num_selected_lines = line("$")
        for i in range(1, l:num_selected_lines)
            execute "keepjumps normal! V\<Esc>"
            call OperatorMacroNR#util#ExecuteMacroOnVisualLineSelectionAtVirtualColumn(a:register, a:count, 1, a:vcol)
            keepjumps normal! `]j
        endfor
    finally
        if a:close
            silent wq
        endif
    endtry
endfunction
" }}}
