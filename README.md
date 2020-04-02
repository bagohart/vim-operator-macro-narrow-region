
# Vim-Operator-Macro-Narrow-Region
A Vim plugin built on top of [NrrwRgn](https://github.com/chrisbra/NrrwRgn) to make Vim macros even more awesome!

# Quickstart
Select a region, execute `:NRV` and save a macro in register `q`.\
Use `Qoip` to execute that macro once, on a paragraph, in a narrow region.\
Use `2Ql5j` to execute that macro twice on each of the next 6 lines, in a narrow region for each line.

# About
vim-operator-macro-narrow-region is a vim plugin that defines 3 different operators for executing macros:
* `Qn{motion}` is a small wrapper around `'[,'] normal! @{register}`
* `Ql{motion}` executes a macro **on each line** of a selection determined by `{motion}`. (A narrow region is created for each line.)
* `Qo{motion}` executes a macro **once** on a narrow region determined by `{motion}`

Why is this useful?
* Reuse the same macro in different places **without changing the macro**
* Execute a macro repeatedly on a range of lines **even if the macro adds surrounding lines**
* Repeatedly execute a macro **restricted to a selection**
* Execute Ex commands and shell commands **on any selection**
* Make complex actions based on macros **repeatable with the dot command**
* Quickly define your own operators **based on a custom macro**

Design goals:
* Make Vim's macros more versatile without sacrificing their power
* Intuitive usage without mental overhead
* Seamless integration with all your other plugins and all of Vim's features

Implementation:
* Built upon [NrrwRgn](https://github.com/chrisbra/NrrwRgn)
* 100% Vimscript

# Requirements
[NrrwRgn](https://github.com/chrisbra/NrrwRgn) must be installed, since vim-operator-macro-narrow-region uses its `NRV` command.\
Also, [vim-repeat](https://github.com/tpope/vim-repeat).
Developed and tested on Neovim 0.4.3. When I tested it on Vim 8.2, everything except Operator-Macro-Linewise worked correctly, too. (See section **Bugs**)

# Installation
Install with your favourite package manager or Vim's built-in package management system.
For example using Vim-Plug:
```
Plug 'bagohart/vim-operator-macro-narrow-region'
```

# Guide
This section illustrates various uses of this plugin.
A basic understanding of Vim macros is assumed.

## Vimrc and Single Macro Execution
First, we'll have to add some mappings to demonstrate all the functionality. I use:
```
nmap QQ <Plug>(operator-macro-run-default-at-cursor)
nmap Ql <Plug>(operator-macro-linewise)
xmap Ql <Plug>(operator-macro-linewise-visual)
nmap Qn <Plug>(operator-macro-normal)
xmap Qn <Plug>(operator-macro-normal-visual)
nmap Qo <Plug>(operator-macro-once)
xmap Qo <Plug>(operator-macro-once-visual)
nmap Qs <Plug>(operator-macro-set-default-register)
xmap . <Plug>(operator-macro-visual-block-dot-command)
```
All operators use a shared default register, which we can configure:
```
" This is also the default. You can change this value at any time.
let g:OperatorMacroNR_LNO_default_register = 'q'
```
Let's record some macros:
```
let @q = "0i(start_q)\<Esc>A(end_q)\<Esc>"
let @p = "0i(start_p)\<Esc>A(end_p)\<Esc>"
```
Enter some text
```
make me a sandwich
```
and execute the macro by pressing `QQ`:
```
(start_q)make me a sandwich(end_q)
```
This is like pressing `@q`. But press `Qsp` to change the default register to `p` and press `QQ` again:
```
(start_p)(start_q)make me a sandwich(end_q)(end_p)
```

This plugin offers 3 different operators to execute macros on selected text.
They also use the default register, but you can override it by prepending `"{register}`.\
The remainder of this guide will assume that the default register is `q`.

## Operator Macro Normal
Brief Vim 101 repetition: You can execute a macro on a range of lines using `:{range} normal! @{register}`.
(operator-macro-normal) is a thin wrapper around this functionality. Given the text
```
make me a sandwich
make me a toast
make me a mango
```
press `Qnip` to obtain:
```
(start_q)make me a sandwich(end_q)
(start_q)make me a toast(end_q)
(start_q)make me a mango(end_q)
```
Press `.` to repeat this change:
```
(start_q)(start_q)make me a sandwich(end_q)(end_q)
(start_q)(start_q)make me a toast(end_q)(end_q)
(start_q)(start_q)make me a mango(end_q)(end_q)
```
(This works only if the macro does not use the `.` command itself, see section **Limitations**)

With visual block mode you can also use (operator-macro-normal) to change the macro's starting position, which is usually the beginning of the line.
Consider the following scenario where we want to swap two values in a table:
```
make  | me | a | sandwich
bring | me | a | toast
give  | me | a | mango
```
Starting on `|`, we can swap the two words to the left and right of it with the following simple macro (with [vim-exchange](https://github.com/tommcdo/vim-exchange)):
```
let @q = mmbcxiw`mwcxiw
```
Use visual block mode to select the '|' column (with [textobj-word-column](https://github.com/coderifous/textobj-word-column.vim) use `vic`) and press `Ql`:
```
me  | make | a | sandwich
me | bring | a | toast
me  | give | a | mango
```
Afterwards, realign the table using e.g. [vim-easy-align](https://github.com/junegunn/vim-easy-align).

## Operator Macro Linewise
The usual `'<,'>normal! @q` approach has several limitations.
A first problem is that we can't use it to make the macro ignore a certain context.
If you want to run the macro 
```
let @q = "0isudo \<Esc>"
```
on the following paragraph:
```
2020-02-13: make me a sandwich
2020-02-14: make me a toast
2020-02-15: make me a mango
```
and you use `Qnip` you get:
```
sudo 2020-02-13: make me a sandwich
sudo 2020-02-14: make me a toast
sudo 2020-02-15: make me a mango
```
The same happens with `Qlip`, but if you use visual block mode to select only the text after the dates and press `Ql` you get:
```
2020-02-13: sudo make me a sandwichch
2020-02-14: sudo make me a toast
2020-02-15: sudo make me a mango
```
Much better.

A second problem is what happens if our macro adds more lines. Consider the following macro:
```
let @q = "$yiwo... a REALLY TASTY \<Esc>p"
```
Let's try to execute this macro (with operator-macro-normal) on every line of our previous paragraph using `Qnip`:
```
make me a sandwich
... a REALLY TASTY sandwich
... a REALLY TASTY sandwich
... a REALLY TASTY sandwich
make me a toast
make me a mango
```
That obviously didn't work as intended. Try again with operator-macro-normal, e.g. press `Qlip`:
```
make me a sandwich
... a REALLY TASTY sandwich
make me a toast
... a REALLY TASTY toast
make me a mango
... a REALLY TASTY mango
```
That worked.

By using the `:` register, we can also repeat Ex and shell commands. Here's a stupid example. Enter
```
:s/(a|e|i|o|u)/y/g
```
Now place your cursor on the beginning of
```
make me a sandwich
```
and hit `":Ql2aw`. You'll get:
```
myky my a sandwich
```
You could accomplish the same thing using the `tr` shell command:
```
'<,'>!tr 'aeiou' 'y'
```
This works because this plugin sets the `'< '>` marks on the whole narrow region buffer before executing the macro.

Note that `Ql` behaviour on visual block depends on its shape.
If the visual block spans only a single column, then the macro is executed on each complete line (in isolation), and the starting position of the macro is determined by the visual block.
Otherwise, it works as described in the previous examples.
In the next section, we'll look at a way to use this in combination with (operator-macro-once).

## Operator Macro Once
The first two operators, (operator-macro-normal) and (operator-macro-linewise) are useful to execute a macro on each line of a selection.
In contrast, (operator-macro-once) is useful for macros which work on more than one line.
Simple example: when writing markdown, I often need to surround some lines with ````` ``` ````` marks.
For this purpose, I use the following simple macro, which surrounds **the entire buffer** with the ````` ``` ````` marks:
```
let @q = "ggO```\<Esc>Go\<C-a>\<Esc>"
```
Now I can use e.g. `Qoil` to surround single lines (with [vim-textobj-line](https://github.com/kana/vim-textobj-line)) or `Qoip` to surround a paragraph.

Here's another (contrived) example to demonstrate 2 useful properties of (operator-macro-once):
It can be executed at the current cursor position, and it can be used in combination with (operator-macro-normal) and (operator-macro-linewise).
Consider the following text:
```
af754e: make me a sandwich
758ab4: make me a mango
17ccc5: make me a banana
2329db: make me a toast
```
Now we craft the following macros:
```
let @p = "yiw0Pa creation: \<Esc>"
let @q = "\"pQo]:"
```
where `]:` is (with [vim-after-object](https://github.com/junegunn/vim-after-object)) the part of the line to the right of `:`.
Use visual block to select **a single column** on the last word and press `Ql`. Result:
```
af754e: sandwich creation: make me a sandwich
758ab4: mango creation: make me a mango
17ccc5: banana creation: make me a banana
2329db: toast creation: make me a toast
```

(operator-macro-once) has another practical use case.
Vim 101 reminder: You can use the following idiomatic macro to repeat a change in the whole buffer:
```
let @q = "n.@q"
```
If you want to repeat that change only on a part of the buffer, use visual mode to select the desired region and press `Qo`.
(Note that in this case you cannot use `Qo` as an operator; see **Limitations**.)
Alternatively, you could use
```
let @q = "n."
```
, visually select the region and press `100Qo` (or some other number that is large enough).

Additionally, (operator-macro-once) is useful for executing shell commands that work on a range of lines.
In the section **Custom Operators**, we'll examine how we can build an operator on top of the `nl` shell command.

## Visual dot command
As we have seen, the behaviour of (operator-macro-linewise) in visual block mode depends on the shape of the visual block:
for single columns, the macro is executed on the whole line, starting at the column position.
A similar behaviour is also implemented for the dot command in visual block.
Press `.` with a single selected column, and the dot command will be executed at that position, but without using narrow region.
If the visual block spans multiple columns, then the whole block is put into a narrow region, and then the dot command is executed at the beginning of each line.
Alternatively, you could use `Ql` with a macro `let @q = "."`.

## Custom Operators
If you find yourself using a specific macro again and again, consider turning it into its own dedicated operator.
For this purpose, there are 2 dedicated functions:
* `OperatorCustomMacro(macro, operator)`
* `CustomMacroVisualMode(macro, operator)`

The first argument `macro` is your custom macro.  
The second argument `operator` must be one of `["normal", "linewise", "custom"]`.  
Each custom operator requires 3 lines in your vimrc. In this section, we'll look at 3 simple examples.

### Custom operator 1: Markdown surround block quote.
In the last section, I used a macro to quote markdown text.
This was so useful when I wrote this readme that I temporarily turned it into a dedicated operator.
I had to add the following 3 lines to my vimrc:
```
let markdown_surround_macro = "ggO```\<Esc>Go```\<Esc>"
nnoremap <expr> M OperatorCustomMacro(markdown_surround_macro, "once")
xnoremap M :<C-u>call CustomMacroVisualMode(markdown_surround_macro, "once")<CR>
```
The second argument of both functions determines which operator to use.
The allowed values are `"normal"`, `"linewise"` and `"once"`.

### Custom operator 2: Rot-N operator
Some people think it's funny to send you Rot-n encrypted text and expect you to decrypt it manually.
Here's a simple solution to this challenge.
Vim ships only with a Rot13 operator `g?`, but we can easily create a Rot-1 operator using (operator-macro-linewise) and the `tr` command-line program:
```
let rot_1_macro = ":'<,'>!tr 'a-zA-Z' 'b-zaB-ZA'\<CR>"
```
In my opinion, the `g?` operator would be more helpful as a general Rot-n operator. Let's overwrite it:
```
nnoremap <expr> g? OperatorCustomMacro(rot_1_macro, "linewise")
xnoremap g? :<C-u>call CustomMacroVisualMode(rot_1_macro, "linewise")<CR>
```
This turns g? into a Rot-1 operator.
To decrypt the entire buffer, press `g?ie` (with [vim-textobj-entire](https://github.com/kana/vim-textobj-entire)) and hit `.` until the text is decrypted correctly.
Also, you get `{n}g?` as a Rot-n operator without further effort.

### Custom operator 3: nl operator
There are many ways in Vim to add increasing numbers to lines.
We could also build a simple operator for this purpose! Here's how:
```
let nl_macro = ":'<,'>!nl\<CR>"
nnoremap <expr> S OperatorCustomMacro(nl_macro, "once")
xnoremap S :<C-u>call CustomMacroVisualMode(nl_macro, "once")<CR>
```
Note that for this operator we pass `"once"` as the employed operator.
With "linewise", every line would end up with number 1!

# Mappings
No mappings are added automatically. My suggestion:
```
nmap QQ <Plug>(operator-macro-run-default-at-cursor)
nmap Ql <Plug>(operator-macro-linewise)
xmap Ql <Plug>(operator-macro-linewise-visual)
nmap Qn <Plug>(operator-macro-normal)
xmap Qn <Plug>(operator-macro-normal-visual)
nmap Qo <Plug>(operator-macro-once)
xmap Qo <Plug>(operator-macro-once-visual)
nmap Qs <Plug>(operator-macro-set-default-register)
xmap . <Plug>(operator-macro-visual-block-dot-command)
```
(Alternatively, you could use `Q` for single macro execution and prefix all other actions with `gQ`.)\
If you press e.g. `Ql` but there's a pause between `Q` and `l`, then you would activate the `Q` command.
You could add the following to prevent that:
```
nnoremap Q <nop>
```
The `Q` command is still available via `gQ`, though you probably don't need it anyway.

If you don't want to use all functionality from this plugin, simply omit the corresponding mappings.

# Reference
This section contains a complete description of all features.

## Settings
This plugin is customizable using some global variables.
All of them start with `g:OperatorMacroNR_` and are followed by some of the letters `LNO` to indicate for which operators the option is relevant.
This is a complete list:

### `g:OperatorMacroNR_LO_close_narrow_region_without_confirmation`
**default: `1`**

If disabled, the results of the macro execution in the narrow region are not written back to the buffer automatically, so you can inspect and correct them first. When you're done, press `:wq`. To cancel, press `:q!`. For other functionality, read the documentation of NrrwRgn.\
If enabled, `wq` is executed automatically, and the invocation of NrrwRgn is invisible to the user.

### `g:OperatorMacroNR_LNO_default_register` 
**default: `'q'`**

All 3 macro operators execute the macro stored in this register.
It can be overridden for a single execution by prepending `"{register}` before the operator.

### `g:OperatorMacroNR_LNO_enable_changed_register_message` 
**default: `1`**

If enabled, a message is displayed after successful use of <Plug>(operator-macro-set-default-register).
The message contains the new register and its content.
If disabled, a message is displayed only if an invalid register was entered.

### `g:OperatorMacroNR_L_visual_block_single_column_mode_activation` 
**default: `'smart'`**

Determines when to use the special behaviour of (operator-macro-linewise).\
Allowed values:
* `'smart'`: Activated if and only if the visual block consists of exactly one column.
* `'never'`: Never activated for visual block mode.
* `'always'`: Always activated for visual block mode.

### `g:OperatorMacroNR_O_always_run_at_start_of_selection` 
**default: `0`**

If disabled, the macro is executed at the current cursor position, unless the cursor position is outside of the selection.\
If enabled, the macro is executed at the beginning of the selection, i.e. the `'[` mark.\
In visual mode, this option does not apply, and the macro is always executed at the beginning of the selection, i.e. the `'<` mark.

### `g:OperatorMacroNR_LO_linewise_motions_select_whole_lines`
**default: `1`**

If enabled, linewise motions always select complete lines.\
If disabled, the `'[` `']` marks are used and the motion is treated like a characterwise motion.\
In most cases, it is more useful to select whole lines; otherwise, you cannot use `10j` or `5k` to select whole lines.

### `g:OperatorMacroNR_LO_set_visual_selection_marks_before_macro_execution` 
**default: `1`**

If enabled, the marks `'<` and `'>` are set on the complete selection before the macro is executed.
This can be helpful to execute the `:` register if the last Ex command operates on a range.

### `g:OperatorMacroNR_valid_macro_registers`
**default: A list with all registers except `+`, `*` and `"`.**

`<Plug>(operator-macro-set-default-register)` throws an error if an invalid register is chosen.
Use this variable to prevent unlisted registers to be used as default registers.
E.g. if you think that only the registers `a-z`, `@` and `:` are reasonable default registers,
add this to your vimrc:
```
let g:OperatorMacroNR_valid_macro_registers = 
    \ [
        \ 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
        \ '@',':'
    \ ]
```

### `g:OperatorMacroNR_LNO_recursion_depth_limit`
**default value: `10`**

When the recursion depth of any operator exceeds this threshold, the operation aborts.
This is done to prevent non-termination or stack overflow in case a user writes a macro such as `n.` and tries to execute it from normal mode instead of visual mode. (See section **Limitations**.)

## Operators and Commands:
All commands and operators are available via `<Plug>` objects.
This is a complete list:

### `<Plug>(operator-macro-set-default-register)`
Sets the default register to the next pressed key.
Alternatively, you can set `g:OperatorMacroNR_LNO_default_register` directly.
Since the used macro might change often, this action deserves its own mapping.
To disable the success message, add this to your vimrc:
```
let g:OperatorMacroNR_LNO_enable_changed_register_message = 0
```

### `<Plug>(operator-macro-run-default-at-cursor)`
Executes the macro in the register specified by `g:OperatorMacroNR_LNO_default_register` at the current cursor position.
This is equivalent to `@{g:OperatorMacroNR_LNO_default_register}`, but has 2 advantages:
* Depending on your keyboard layout it may be more convenient than pressing `@@`.
* You do not need to remember in which register you stored the macro. If you store all your macros in e.g. register `q`, you do not need to specify `q` for each invocation.

### `<Plug>(operator-macro-normal)` and `<Plug>(operator-macro-normal-visual)`
Executes the macro on each line of a selection.
This is only a small wrapper around the `'<, '> normal! @q` idiom.
Therefore, a macro that is executed with this operator can modify the whole buffer.
Since the narrow region plugin is not used for this operator, (operator-macro-normal) can be faster than (operator-macro-linewise).

### `<Plug>(operator-macro-linewise)` and `<Plug>(operator-macro-linewise-visual)`
Opens a narrow region on the selection.
Then, it executes the macro in the register specified by `g:OperatorMacroNR_LNO_default_register` on every line of the selection.
This happens in a (nested) narrowed region for each line.

For visual block mode, there is an exception if and only if the shape of the visual selection is a single column:\
In this case, the macro is executed on the whole line, and the start position of the macro is determined by the visual block.

### `<Plug>(operator-macro-once)` and `<Plug>(operator-macro-once-visual)`
This works like `<Plug>(operator-macro-linewise)`, but with 2 important differences:
* The start position of the macro is determined by the cursor position. This can be turned off:
```
let g:OperatorMacroNR_O_always_run_at_start_of_selection = 1
```
* The macro is only executed once, while the whole selection is put into a narrowed region.

### `<Plug>(operator-macro-visual-block-dot-command)`
This executes the dot command on every line of the visual selection.
If the shape of the visual selection is a single column, then the macro is executed on the whole line, and the cursor position is determined by the visual block.
Narrow region is used only for visual block with multiple columns.
The internally used command is `normal .` instead of `normal! .`, so you can use this action together with [vim-repeat](https://github.com/tpope/vim-repeat).

# Limitations:
* **NrrwRgn:** (vim-operator-macro-narrow-region) uses the NrrwRgn plugin to isolate the selected text before executing the macro. Therefore, it inherits its behaviour when overwriting the selection with the result of the transformation, which may or may not be desired.
* **Dot command in macros:** You cannot use `<Plug>(operator-macro-linewise)`, `<Plug>(operator-macro-normal)` or `<Plug>(operator-macro-once)` with macros that use the dot command themselves. This sends Vim into an infinite recursion. Since Vim doesn't let the plugin developer influence what the dot command will do, this cannot be fixed. To guard against this, the operators abort when a certain recursion level is reached. It works in visual mode, though.

# Bugs:
* When I tried this plugin on Vim 8.2, the NrrwRgn feature of nesting narrowed region buffers didn't work correctly. As a result, Operator-Macro-Linewise doesn't work. This cannot be fixed in this plugin, but it can be detected. In this case, Operator-Macro-Linewise fails (without doing damage to or closing your buffer).  It leaves open a dangling and detached narrowed region buffer that you have to close yourself, so you see what happened.

# FAQ:
> Can I use `.` to repeat <Plug>(operator-macro-run-default-at-cursor)?

No, and this is by design. Repeating the last change and the last macro are fundamentally different things in Vim.

> Can I change the behaviour with respect to visual block mode?

No, because this behaviour is inherited by the NrrwRgn plugin.

> Why does this plugin have a dependency on NrrwRgn?

Without the narrow region functionality, how are you going to record the applied macros in the first place?\
Also, it enables the quite useful `g:OperatorMacroNR_LO_close_narrow_region_without_confirmation`.

# Related Plugins:
* [NrrwRgn](https://github.com/chrisbra/NrrwRgn): The backbone for this plugin, and quite useful on its own.
* [RangeMacro](https://github.com/vim-scripts/RangeMacro/): Provides a different macro operator. Its purpose is a subset of this plugin's purpose, but its implementation follows a completely different approach.
* [vim-action-macro](https://vimawesome.com/plugin/vim-action-macro): Defines a macro operator similar to (operator-macro-normal).
* [vim-visualrepeat](https://github.com/inkarkat/vim-visualrepeat): A more ambitious take on how the dot command in visual mode could be implemented.
* [vim-visual-multi](https://github.com/mg979/vim-visual-multi): A multiple cursors plugin. In particular, it offers a more flexible way to execute macros at different positions simultaneously.
* [vis](https://github.com/vim-scripts/vis): Another approach that allows you to use Ex and shell commands with a visual selection.
* [vim-operator-user](https://github.com/kana/vim-operator-user), [vim-SubstituteExpression](https://github.com/inkarkat/vim-SubstituteExpression), [vim-express](https://github.com/tommcdo/vim-express): Some other plugins that simplify defining your own operators.

# Not Really Related Plugins:
The section **Guide** contained some examples how we could use vim-operator-macro-narrow-region to turn some common tasks into operators.
Instead, you could also use the following dedicated plugins:
* [vim-operator-substitute](https://github.com/milsen/vim-operator-substitute): Substitutions on any selection.
* [vim-sandwich](https://github.com/machakann/vim-sandwich): Highly configurable surround functionality.
* [vseq.vim](https://github.com/dalance/vseq.vim): Creating vertical sequences of numbers.
* [vim-operator-rot-n](https://github.com/bagohart/vim-operator-rot-n): Provides an operator for Rot-N encryption.

# Licence
The Vim licence applies. See `:help license`.
