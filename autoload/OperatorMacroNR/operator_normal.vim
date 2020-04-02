" Interface to Vim's operator API 
function! OperatorMacroNR#operator_normal#OperatorNormal(type) abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(g:OperatorMacroNR_internals["vregister"], g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "normal")
    call OperatorMacroNR#operator_normal#OperatorNormalMacroExecute(a:type, l:use_this_register, g:OperatorMacroNR_internals["v:count1"])
endfunction

function! OperatorMacroNR#operator_normal#OperatorNormalVisualMode() abort
    let l:use_this_register = OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(v:register, g:OperatorMacroNR_LNO_default_register)
    call OperatorMacroNR#util#AssertValidMacroRegister(l:use_this_register, "normal")
    call OperatorMacroNR#operator_normal#OperatorNormalMacroExecute(visualmode(), l:use_this_register, v:count1)
endfunction
" 

" Repeat tricks. Kids, don't do this at home. {{{
function! OperatorMacroNR#operator_normal#OperatorNormalRepeat() abort
    " echom "op normal repeat!"
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    normal! .
endfunction

function! OperatorMacroNR#operator_normal#OperatorNormalRepeatVisual() abort
    " echom "op normal repeat visual!"
    call OperatorMacroNR#util#SaveCountBeforeRepeat()
    execute "normal! 1v\<Esc>"
    call OperatorMacroNR#operator_normal#OperatorNormalMacroExecute(visualmode(), g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"])
endfunction
" }}}

let s:operator_macro_normal_recursion_level = 0

" Operator normal core functionality {{{
function! OperatorMacroNR#operator_normal#OperatorNormalMacroExecute(type, register, count) abort
    " echom "Called OperatorMacroNR#operator_normal#OperatorNormalMacroExecute() with type= "
                \ . a:type . ", register=" . a:register . ", macro=" . eval("@" . a:register) . ", count=" . a:count

    let s:operator_macro_normal_recursion_level += 1
    if s:operator_macro_normal_recursion_level ># g:OperatorMacroNR_LNO_recursion_depth_limit
        throw "operator macro normal recursion level too big. Abort..."
    endif
    try
        if a:type ==# 'char' || a:type ==# 'line'
            let l:final_curpos = getpos("'[")
            execute "keepjumps '[,'] normal! " . a:count . "@" . a:register
            call setpos(".", l:final_curpos)
            call repeat#set("\<Plug>(operator-macro-normal-repeat)")
        elseif a:type ==# 'v' || a:type ==# 'V'
            let l:final_curpos = getpos("'<")
            execute "keepjumps '<,'> normal! " . a:count . "@" . a:register
            call setpos(".", l:final_curpos)
            call repeat#set("\<Plug>(operator-macro-normal-repeat-visual)")
        elseif a:type ==# "\<C-v>"
            let l:final_curpos = getpos("'<")
            let l:min_column = min([
                            \ OperatorMacroNR#util#GetLeftmostVirtualColumn(getpos("'<")),
                            \ OperatorMacroNR#util#GetLeftmostVirtualColumn(getpos("'<"))
                        \ ])
            execute "keepjumps '<,'> normal! " . l:min_column . "|" . a:count . "@" . a:register
            call setpos(".", l:final_curpos)
            call repeat#set("\<Plug>(operator-macro-normal-repeat-visual)")
        else
            " If this ever happens, the plugin is broken or someone tried to call the function directly.
            throw "Running OperatorNormalMacroExecute() with unrecognized type=" . a:type
        endif
    finally
        let s:operator_macro_normal_recursion_level -= 1
    endtry
endfunction
" }}}
