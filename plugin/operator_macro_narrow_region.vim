" Autoloading hack: Activate this to enforce local reloading. {{{
" call OperatorMacroNR#util#Baaaaad()
" call OperatorMacroNR#operator_custom#Baaaaad()
" call OperatorMacroNR#operator_linewise#Baaaaad()
" call OperatorMacroNR#operator_normal#Baaaaad()
" call OperatorMacroNR#operator_once#Baaaaad()
" call OperatorMacroNR#visual_dot_command#Baaaaad()
" }}}

" reload guard {{{
if exists("g:loaded_operator_macro_narrow_region")
  " deactivate this for simple local reloading
  finish
endif
let g:loaded_operator_macro_narrow_region = 1
" }}}

" Options {{{
" If you are the user of this plugin: do not modify this dictionary ever!!!
" This exists only to share several values between multiple files, since Vimscript
" does not have plugin-local variables.
" It is a dictionary to not introduce a million global variables.
let g:OperatorMacroNR_internals = {}

let g:OperatorMacroNR_LNO_recursion_depth_limit = get(g:, 'OperatorMacroNR_recursion_depth_limit', 10)
let g:OperatorMacroNR_LO_close_narrow_region_without_confirmation = get(g:, 'OperatorMacroNR_LO_close_narrow_region_without_confirmation', '1')
let g:OperatorMacroNR_LNO_default_register = get(g:, 'OperatorMacroNR_default_register', 'q')
let g:OperatorMacroNR_LNO_enable_changed_register_message = get(g:, 'OperatorMacroNR_enable_changed_register_message', 1)
let g:OperatorMacroNR_L_visual_block_single_column_mode_activation = get(g:, 'OperatorMacroNR_L_visual_block_single_column_mode_activation', 'smart')
let g:OperatorMacroNR_O_always_run_at_start_of_selection = get(g:, 'OperatorMacroNR_O_always_run_at_start_of_selection', 0)
let g:OperatorMacroNR_LO_set_visual_selection_marks_before_macro_execution = get(g:, 'OperatorMacroNR_LO_set_visual_selection_marks_before_macro_execution', 1)
let g:OperatorMacroNR_LNO_reuse_count_on_repeat = get(g:, 'OperatorMacroNR_LNO_reuse_count_on_repeat', 0)
let g:OperatorMacroNR_LO_linewise_motions_select_whole_lines = get(g:, 'OperatorMacroNR_LO_linewise_motions_select_whole_lines', 1)

" Macros can be run from any register in this list.
" By default, this is any register except the "+* registers.
" If those were included, the v:register mechanism would not work as expected.
" If you think that only e.g. the alpabetic registers and @ and : are useful as default registers,
" then you can modify this list accordingly (e.g. in your vimrc).
let g:OperatorMacroNR_valid_macro_registers = get(g:, 'OperatorMacroNR_valid_macro_registers',
    \ [
        \ 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
        \ '@',':',
        \ '0','1','2','3','4','5','6','7','8','9',
        \ '-','/','.','%','#', '='
    \ ]
\ )
" }}}

" <Plug> objects for user mappings {{{
" Operator Once
nnoremap <silent> <Plug>(operator-macro-once)
            \ :<C-u>call OperatorMacroNR#util#SaveCursorCountRegister()<CR>
            \:<C-u>set operatorfunc=OperatorMacroNR#operator_once#OperatorOnce<CR>g@

xnoremap <silent> <Plug>(operator-macro-once-visual)
            \ :<C-u>call OperatorMacroNR#operator_once#OperatorOnceVisualMode()<CR>

nnoremap <silent> <Plug>(operator-macro-once-repeat) :<C-u>call OperatorMacroNR#operator_once#OperatorOnceRepeat()<CR>
nnoremap <silent> <Plug>(operator-macro-once-repeat-visual) :<C-u>call OperatorMacroNR#operator_once#OperatorOnceRepeatVisual()<CR>

" Operator Normal
nnoremap <silent> <Plug>(operator-macro-normal)
            \ :<C-u>call OperatorMacroNR#util#SaveCountRegister()<CR>
            \:<C-u>set operatorfunc=OperatorMacroNR#operator_normal#OperatorNormal<CR>g@

nnoremap <silent> <Plug>(operator-macro-normal-repeat) :<C-u>call OperatorMacroNR#operator_normal#OperatorNormalRepeat()<CR>
nnoremap <silent> <Plug>(operator-macro-normal-repeat-visual) :<C-u>call OperatorMacroNR#operator_normal#OperatorNormalRepeatVisual()<CR>

xnoremap <silent> <Plug>(operator-macro-normal-visual)
            \ :<C-u>call OperatorMacroNR#operator_normal#OperatorNormalVisualMode()<CR>

" Operator Linewise
nnoremap <silent> <Plug>(operator-macro-linewise)
            \ :<C-u>call OperatorMacroNR#util#SaveCountRegister()<CR>
            \:<C-u>set operatorfunc=OperatorMacroNR#operator_linewise#OperatorLinewise<CR>g@

xnoremap <silent> <Plug>(operator-macro-linewise-visual)
            \ :<C-u>call OperatorMacroNR#operator_linewise#OperatorLinewiseVisualMode()<CR>

nnoremap <silent> <Plug>(operator-macro-linewise-repeat) :<C-u>call OperatorMacroNR#operator_linewise#OperatorLinewiseRepeat()<CR>
nnoremap <silent> <Plug>(operator-macro-linewise-repeat-visual) :<C-u>call OperatorMacroNR#operator_linewise#OperatorLinewiseRepeatVisual()<CR>

" Run default macro at cursor
nnoremap <silent> <expr> <Plug>(operator-macro-run-default-at-cursor)
            \ "@" . g:OperatorMacroNR_LNO_default_register

" Set default register
nnoremap <silent> <Plug>(operator-macro-set-default-register)
            \ :<C-u>call OperatorMacroNR#util#SetDefaultRegister()<CR>

" Execute linewise dot command on visual block with (optional) single column distinction 
xnoremap <silent> <Plug>(operator-macro-visual-block-dot-command)
            \ :<C-u>call OperatorMacroNR#visual_dot_command#VisualModeDotCommand(visualmode())<CR>
" }}}

" Use these functions to define custom operators with macros. {{{

" Example usage in your vimrc:
" let markdown_surround_macro = "ggO```\<Esc>Go```\<Esc>"
" nnoremap <expr> M OperatorCustomMacro(markdown_surround_macro, "once")
" xnoremap M :<C-u>call CustomMacroVisualMode(markdown_surround_macro, "once")<CR>

" Those functions are not autoloaded because that would not look nice in your vimrc.
function! OperatorCustomMacro(macro, mode)
    call OperatorMacroNR#util#SaveCursorCountMacro(a:macro)
    " echom "Called OperatorCustomMacro() with mode=" . a:mode . ", count=" . g:OperatorMacroNR_internals["v:count1"] . ", macro=" . g:OperatorMacroNR_internals["custom_macro"]
    let l:opfunc_val = get(s:custom_operator_func, a:mode, "normal")
    " setting operatorfunc after returning this function is a bit of a hack;
    " it is only done to prevent the count being prepended to 'g@'
     " There may be a better way to do this.
     return ":\<C-u>set operatorfunc=" . l:opfunc_val . "\<CR>g@"
 endfunction

function! CustomMacroVisualMode(macro, mode)
    " Saving the cursor is actually unnecessary since it will never be used.
    call OperatorMacroNR#util#SaveCursorCountMacro(a:macro)
    " echom "Called CustomMacroVisualMode() with mode=" . a:mode . ", count=" . g:OperatorMacroNR_internals["v:count1"] . ", macro=" . g:OperatorMacroNR_internals["custom_macro"]
    execute "call " . s:custom_operator_func[a:mode] . "(visualmode())"
endfunction

let s:custom_operator_func = {
            \ "once": "OperatorMacroNR#operator_custom#OperatorOnceCustomMacro",
            \ "linewise": "OperatorMacroNR#operator_custom#OperatorLinewiseCustomMacro",
            \ "normal": "OperatorMacroNR#operator_custom#OperatorNormalCustomMacro" 
            \ }
" }}}

" usermappings {{{
" nmap Ql <Plug>(operator-macro-linewise)
" xmap Ql <Plug>(operator-macro-linewise-visual)
" nmap Qn <Plug>(operator-macro-normal)
" xmap Qn <Plug>(operator-macro-normal-visual)
" nmap Qo <Plug>(operator-macro-once)
" xmap Qo <Plug>(operator-macro-once-visual)
" nmap Qs <Plug>(operator-macro-set-default-register)
" nmap QQ <Plug>(operator-macro-run-default-at-cursor)
" nmap Q <nop>
" xmap . <Plug>(operator-macro-visual-block-dot-command)
" }}}
