" Workaround for Vim's operator API. Explicitly save input for operator before execution. {{{
function! OperatorMacroNR#util#SaveCursorCountMacro(macro) abort
    let g:OperatorMacroNR_internals["curpos"] = getcurpos()
    let g:OperatorMacroNR_internals["v:count1"] = v:count1
    let g:OperatorMacroNR_internals["custom_macro"] = a:macro
endfunction

function! OperatorMacroNR#util#SaveCursorCountMacroIndex(macro_index) abort
    let g:OperatorMacroNR_internals["curpos"] = getcurpos()
    let g:OperatorMacroNR_internals["v:count1"] = v:count1
    let g:OperatorMacroNR_internals["custom_macro"] = g:OperatorMacro_custom_macros[a:macro_index]
endfunction

function! OperatorMacroNR#util#SaveCountMacro(macro) abort
    let g:OperatorMacroNR_internals["v:count1"] = v:count1
    let g:OperatorMacroNR_internals["custom_macro"] = a:macro
endfunction

function! OperatorMacroNR#util#SaveCursorCountRegister() abort
    let g:OperatorMacroNR_internals["curpos"] = getcurpos()
    let g:OperatorMacroNR_internals["v:count1"] = v:count1
    let g:OperatorMacroNR_internals["vregister"] = v:register
endfunction

function! OperatorMacroNR#util#SaveCountRegister() abort
    let g:OperatorMacroNR_internals["v:count1"] = v:count1
    let g:OperatorMacroNR_internals["vregister"] = v:register
endfunction

function! OperatorMacroNR#util#SaveCountBeforeRepeat() abort
    if g:OperatorMacroNR_LNO_reuse_count_on_repeat
        let g:OperatorMacroNR_internals["v:count1"] = v:count > 0 ? v:count : g:OperatorMacroNR_internals["v:count1"]
    else
        let g:OperatorMacroNR_internals["v:count1"] = v:count1
    endif
endfunction
" }}}

" Utility functions for the used register {{{
function! OperatorMacroNR#util#GetSpecifiedRegisterIfGiven(vregister, default_register)
    if a:vregister ==# '"' || a:vregister ==# '*' || a:vregister ==# '+'
        return a:default_register
    else
        return a:vregister
    endif
endfunction

function! OperatorMacroNR#util#SetDefaultRegister()
    let l:register_chosen_by_user = nr2char(getchar())
    if s:IsValidRegister(l:register_chosen_by_user)
        let g:OperatorMacroNR_LNO_default_register = l:register_chosen_by_user
        if g:OperatorMacroNR_LNO_enable_changed_register_message
            echom "Success: set new default register '" . g:OperatorMacroNR_LNO_default_register . "' for Operator-Macro."
            echom "Current register content of '" . l:register_chosen_by_user . "' is '" . getreg(g:OperatorMacroNR_LNO_default_register) . "'"
        endif
    else
        echoerr "Invalid register '" . l:register_chosen_by_user . "' for OperatorMacro. " .
                    \ "Register must be one of [" . join(g:OperatorMacroNR_valid_macro_registers, '') . "]"
    end
endfunction

function! s:IsValidRegister(register)
    return count(g:OperatorMacroNR_valid_macro_registers, a:register) ># 0
endfunction

function! OperatorMacroNR#util#AssertValidMacroRegister(register, operator)
    if !s:IsValidRegister(a:register)
        throw "Invalid register '" . a:register . "' for OperatorMacro, operator " . a:operator
                    \ "Register must be one of [" . join(g:OperatorMacroNR_valid_macro_registers, '') . "]"
    endif
endfunction
" }}}

" Check options for validity {{{
function! OperatorMacroNR#util#AssertSingleColumnModeValidOption(single_column_activation_option)
    if a:single_column_activation_option !=# "always" &&
                \ a:single_column_activation_option !=# "never" &&
                \ a:single_column_activation_option !=# "smart"
        throw 'Invalid value for single column activation: "' . a:single_column_activation_option . '". Value must be one of ["always", "never", "smart"]'
    endif
endfunction
" }}}

" Manage the visual selection {{{

" saves the last visual selection shape.
" caveat: in visual block mode, < can be a bigger column than >
" this function always saves < in the smaller column.
" Otherwise this function becomes illegible.
" We cannot simply save the result of getpos(), since that saves the column in bytes instead of the screen column,
" which breaks for tabs and multiline characters
" Also does not preserve the $ information on visual block.
" It does not work via marks (otherwise I would have to change marks...), therefore the last position is lost if text
" before the marks is changed
function! OperatorMacroNR#util#BackupVisualSelectionShape() abort
    let l:pos_vs_start = getpos("'<")
    let l:pos_vs_end = getpos("'>")
    return {
            \ "vs_start_line": l:pos_vs_start[1],
            \ "vs_end_line": l:pos_vs_end[1],
            \ "vs_start_virtcol": min([
                    \ OperatorMacroNR#util#GetLeftmostVirtualColumn(l:pos_vs_start),
                    \ OperatorMacroNR#util#GetLeftmostVirtualColumn(l:pos_vs_end)
                \ ]),
            \ "vs_end_virtcol": max( [
                    \ virtcol("'<"),
                    \ virtcol("'>")
                \ ]),
            \ "vs_type": visualmode()
          \}
endfunction

function! OperatorMacroNR#util#RestoreVisualSelectionShape(vs_shape)
    " We could use m< and m> to set the marks, but not the type!
    " Therefore, we have to do it this way manually
    execute "keepjumps normal! " . a:vs_shape["vs_start_line"] . "G" . a:vs_shape["vs_start_virtcol"] . "|" .
                \ a:vs_shape["vs_type"] .
                \ a:vs_shape["vs_end_line"] . "G" . a:vs_shape["vs_end_virtcol"] . "|\<Esc>"
endfunction

" Activates a linewise visual selection on the whole buffer
function! OperatorMacroNR#util#SetVisualSelectionOnWholeBuffer()
    execute "keepjumps normal! ggVG\<Esc>"
endfunction

" }}}

" Selection utility functions {{{
function! OperatorMacroNR#util#SetVisualSelectionMarksToYankedSelectionMarks(type)
    if a:type ==# 'char'
        execute "keepjumps normal! `[v`]\<Esc>"
    elseif a:type ==# 'line'
        if g:OperatorMacroNR_LO_linewise_motions_select_whole_lines
            execute "keepjumps normal! `[V`]\<Esc>"
        else
            execute "keepjumps normal! `[v`]\<Esc>"
        endif
    else
        throw "Called OperatorMacroNR#util#SetVisualSelectionMarksToYankedSelectionMarks() with wrong type=" . a:type
    endif
endfunction

function! OperatorMacroNR#util#IsInsideSelection(pos, selection_start, selection_end) abort
    let l:position_line = a:pos[1]
    let l:position_column = a:pos[2]
    let l:selection_start_line = a:selection_start[1]
    let l:selection_end_line = a:selection_end[1]
    let l:selection_start_column = a:selection_start[2]
    let l:selection_end_column = a:selection_end[2]
    return !(
        \    l:position_line <# l:selection_start_line ||
        \    l:position_line ># l:selection_end_line ||
        \    ( l:position_line ==# l:selection_start_line && l:position_column <# l:selection_start_column ) ||
        \    ( l:position_line ==# l:selection_end_line && l:position_column ># l:selection_end_column )
        \   )
endfunction
" }}}

" Useful functions for printf-debugging {{{
function! OperatorMacroNR#util#PrintListWithName(list, name)
    echom "Contents of list " . a:name . " with length " . len(a:list)
   for l:item in a:list
       echom string(l:item)
   endfor
endfunction

function! OperatorMacroNR#util#PrintVisualSelection()
    keepjumps normal! gv"zy
    echom "visual selection=" . @z
endfunction

function! OperatorMacroNR#util#PrintYankedSelection()
    keepjumps normal! `[v`]"zy
    echom "yanked selection=" . @z
endfunction
" }}}

" Register backup functions {{{
function! s:BackupRegister(register) abort
    " see :h setreg() and getreg() for the last two crazy arguments
    let l:register_value = getreg(a:register, 1, 1)
    let l:register_type = getregtype(a:register)
    return {'register_value': l:register_value, 'register_type': l:register_type}
endfunction

function! s:RestoreRegister(register, register_backup) abort
    let l:register_value = a:register_backup['register_value']
    let l:register_type = a:register_backup['register_type']
    call setreg(a:register, l:register_value, l:register_type)
endfunction

function! OperatorMacroNR#util#BackupRegisterList(register_list) abort
    let l:registers_backup = {}
    for l:register in a:register_list
        let l:registers_backup[l:register] = s:BackupRegister(l:register)
    endfor
    return l:registers_backup
endfunction

function! OperatorMacroNR#util#RestoreRegisterDict(registers_backup) abort
	for [l:register, l:register_backup] in items(a:registers_backup)
        call s:RestoreRegister(l:register, l:register_backup)
	endfor
endfunction
" }}}

" Macro execution with NarrowRegion plugin {{{
function! OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtStart(register, count, close) abort
    call OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtPosition(a:register, a:count, a:close, [0,1,1,0])
endfunction

function! OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtPosition(register, count, close, pos) abort
    " echom "Called OperatorMacroNR#util#ExecuteMacroOnVisualSelectionAtPosition() with count=" . a:count
    try
       keepjumps silent NRV
    catch /.*/
        throw "Opening narrow region on visual selection failed with error: " . v:exception
    endtry
    try
        if g:OperatorMacroNR_LO_set_visual_selection_marks_before_macro_execution
            call OperatorMacroNR#util#SetVisualSelectionOnWholeBuffer()
        endif
        call setpos('.', a:pos)
        " execute 'normal! ' . a:count . '@' . a:register
        " ^ das tut nicht, wenn das macro wiederum normal aufruft, dann geht der count kaputt o_O
        " :execute "normal! I(anfang)\<Esc>j"
        " . verschachtelte normal (execute?) befehle failen also irgendwie mit count?
        for i in range(a:count)
            execute "keepjumps normal! @" . a:register
        endfor
    finally
        if a:close
            " This closes the narrowed region. Without this, after a prevented infinite recursion you have 15 new split windows.
            silent wq
        endif
    endtry
endfunction

" Precondition: visual selection on a single line
function! OperatorMacroNR#util#ExecuteMacroOnVisualLineSelectionAtVirtualColumn(register, count, close, vcol) abort
    " echom "Called OperatorMacroNR#util#ExecuteMacroOnVisualLineSelectionAtVirtualColumn() with count=" . a:count
    try
        keepjumps silent NRV
    catch /.*/
        throw "Opening narrow region on visual selection failed with error: " . v:exception
    endtry
    try
        if g:OperatorMacroNR_LO_set_visual_selection_marks_before_macro_execution
            call OperatorMacroNR#util#SetVisualSelectionOnWholeBuffer()
        endif
        execute 'keepjumps normal! ' . a:vcol . "|"
        for i in range(a:count)
            execute "keepjumps normal! @" . a:register
        endfor
    finally
        if a:close
            silent wq
        endif
    endtry
endfunction

" input: result of getpos()
function! OperatorMacroNR#util#GetLeftmostVirtualColumn(pos)
    let l:save_cursor = getcurpos()
    call setpos(".", a:pos)
    let l:virtcol_pos = virtcol(".")
    keepjumps normal! h
    let l:virtcol_left_neighbour = virtcol(".")
    call setpos('.', l:save_cursor)
    if l:virtcol_left_neighbour ==# l:virtcol_pos
        " the cursor didn't move, so we were at the first character of the line already!
        return 1
    else
        return l:virtcol_left_neighbour + 1
    endif
endfunction
" }}}
