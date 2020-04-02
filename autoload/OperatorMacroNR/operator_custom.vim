
function! OperatorMacroNR#operator_custom#OperatorOnceCustomMacro(type) abort
    let l:backup_registers = OperatorMacroNR#util#BackupRegisterList([g:OperatorMacroNR_LNO_default_register])
    call setreg(g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["custom_macro"])
    " echom 'Called OperatorMacroNR#operator_custom#OperatorOnceCustomMacro(), custom macro is :"'
    "             \ . getreg(g:OperatorMacroNR_LNO_default_register) . '"'
    call OperatorMacroNR#operator_once#OperatorOnceMacroExecute(a:type, g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"], g:OperatorMacroNR_internals["curpos"])
    call OperatorMacroNR#util#RestoreRegisterDict(l:backup_registers)
endfunction

function! OperatorMacroNR#operator_custom#OperatorLinewiseCustomMacro(type) abort
    let l:backup_registers = OperatorMacroNR#util#BackupRegisterList([g:OperatorMacroNR_LNO_default_register])
    call setreg(g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["custom_macro"])
    " echom 'Called OperatorMacroNR#operator_custom#OperatorLinewiseCustomMacro(), custom macro is :"'
    "             \ . getreg(g:OperatorMacroNR_LNO_default_register) . '"'
    call OperatorMacroNR#operator_linewise#OperatorLinewiseMacroExecute(a:type, g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"])
    call OperatorMacroNR#util#RestoreRegisterDict(l:backup_registers)
endfunction

function! OperatorMacroNR#operator_custom#OperatorNormalCustomMacro(type) abort
    let l:backup_registers = OperatorMacroNR#util#BackupRegisterList([g:OperatorMacroNR_LNO_default_register])
    call setreg(g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["custom_macro"])
    " echom 'Called OperatorMacroNR#operator_custom#OperatorNormalCustomMacro(), custom macro is :"'
    "             \ . getreg(g:OperatorMacroNR_LNO_default_register) . '"'
    call OperatorMacroNR#operator_normal#OperatorNormalMacroExecute(a:type, g:OperatorMacroNR_LNO_default_register, g:OperatorMacroNR_internals["v:count1"])
    call OperatorMacroNR#util#RestoreRegisterDict(l:backup_registers)
endfunction

