" Use those workaround functions to deal with Vim's operator interface {{{
function! OperatorMacroNR#operator_once#OperatorOnce(type) abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(g:OperatorMacroNR_internals["vregister"], g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "once")
    call OperatorMacroNR#operator_once#OperatorOnceMacroExecute(a:type, l:use_this_register, g:OperatorMacroNR_internals["v:count1"], g:OperatorMacroNR_internals["curpos"])
endfunction

function! OperatorMacroNR#operator_once#OperatorOnceVisualMode() abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(v:register, g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "once")
    call OperatorMacroNR#operator_once#OperatorOnceMacroExecute(visualmode(), l:use_this_register, v:count1, getpos("."))
endfunction
" }}}

" Repeat tricks. Kids, don't do this at home. {{{
function! OperatorMacroNR#operator_once#OperatorOnceRepeat() abort
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    normal! .
endfunction

function! OperatorMacroNR#operator_once#OperatorOnceRepeatVisual() abort
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    execute "normal! 1v\<Esc>"
    call OperatorMacroNR#operator_once#OperatorOnceMacroExecute(visualmode(), g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"], getpos("."))
endfunction
" }}}

let s:operator_macro_once_recursion_level = 0

" Operator once core functionality {{{
function! OperatorMacroNR#operator_once#OperatorOnceMacroExecute(type, register, count, curpos) abort
    " echom "Called OperatorMacroNR#operator_once#OperatorOnceMacroExecute() with type= "
                \ . a:type . ", register=" . a:register . ", macro=" . eval("@" . a:register) . ", count=" . a:count

    let s:operator_macro_once_recursion_level += 1
    if s:operator_macro_once_recursion_level ># g:OperatorMacroNR_LNO_recursion_depth_limit
        throw "operator macro once recursion level too big. Abort..."
    endif

    try
        let l:backup_visual_selection_shape = OperatorMacroNR#util#BackupVisualSelectionShape()

        if a:type ==# 'char' || a:type ==# 'line'
            call OperatorMacroNR#util#SetVisualSelectionMarksToYankedSelectionMarks(a:type)
            let l:selection_start_pos =  getpos("'<")
            let l:selection_end_pos =  getpos("'>")
            if g:OperatorMacroNR_O_always_run_at_start_of_selection ||
                        \ !OperatorMacroNR#util#IsInsideSelection(a:curpos, l:selection_start_pos, l:selection_end_pos)
                call OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtStart(a:register, a:count,
                            \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation)
            else
                let l:narrowed_curpos = s:ComputeNarrowedPosition(a:curpos, l:selection_start_pos, l:selection_end_pos)
                call OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtPosition(a:register, a:count,
                            \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation, l:narrowed_curpos)
            endif
            call repeat#set("\<Plug>(operator-macro-once-repeat)")
        elseif a:type ==# 'v' || a:type ==# 'V' || a:type ==# "\<C-v>"
            call OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtStart(a:register, a:count,
                        \ g:OperatorMacroNR_LO_close_narrow_region_without_confirmation)
            call repeat#set("\<Plug>(operator-macro-once-repeat-visual)")
        else
            " If this ever happens, the plugin is broken or someone tried to call the function directly.
            throw "Running OperatorOnceMacroExecute() with unrecognized type=" . a:type
        endif

        call OperatorMacroNR#util#RestoreVisualSelectionShape(l:backup_visual_selection_shape)
        call setpos(".", getpos("'["))
    finally
        let s:operator_macro_once_recursion_level -= 1
    endtry
endfunction

function! s:ComputeNarrowedPosition(curpos, selection_start_pos, selection_end_pos)
    if !OperatorMacroNR#util#IsInsideSelection(a:curpos, a:selection_start_pos, a:selection_end_pos)
        return [0, 1, 1, 0]
    else
        let l:narrowed_line = a:curpos[1] - a:selection_start_pos[1] + 1
        if a:curpos[1] !=# a:selection_start_pos[1]
            let l:narrowed_column = a:curpos[2]
        else
            let l:narrowed_column = a:curpos[2] - a:selection_start_pos[2] + 1
        endif
        return [0, l:narrowed_line, l:narrowed_column, 0]
    endif
endfunction
" }}}
