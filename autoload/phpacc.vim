"
" Configuration:
"
" phpacc_generate_functions
"   This can be set to a list of functions to be generated whenever
"   GenerateAccessors() is called. If this variable is empty, the user will be
"   asked to determine the types for each attribute. To define the default
"   set, use the template names (without .tpl):
"
"       ["getter", "setter"]


let s:old_cpo = &cpo
set cpo&vim

if !exists("phpacc_template_dir")
    " TODO: Implement some guessing for template directories
    throw "Missing variable 'phpacc_template_dir'. Please configure."
endif

let s:regex = {}
let s:regex["attribute"] = '^\(\s*\)\(\(private\s*\|public\s*\|protected\s*\|static\s*\)\+\)\s*\$\([^ ;=]\+\)[ =]*\(.*\);\?$'
let s:regex["comment_end"] = '^\s* \*/'
let s:regex["comment_start"] = '^\s*/\*\*'
let s:regex["comment_var"] = '^\s*\*\s\+@var\s\+\(\S\+\)\(\s\|$\)'
let s:regex["type_short"] = '\\\([^\\]\+\)$'
let s:regex["line_last"] = '^}'

func! phpacc#GenerateAccessors() range

    let l:config = s:GetConfig()

    let l:current = a:firstline

    let l:functions = []
    while l:current <= a:lastline
        if match(getline(l:current), s:regex["attribute"]) > -1
            
            let l:generate_functions = []
            if !l:config["generate_functions"]
                let l:generate_functions = s:AskGenerateFunctions()

                if s:AskRepeatChoice()
                    let l:config["generate_functions"] = l:generate_functions
                endif
            else
                let l:generate_functions = l:config["generate_functions"]
            endif

            let l:functions = extend(l:functions, s:GenerateAccessors(l:current, l:generate_functions))
        endif

        let l:current = l:current + 1
    endwhile


    call s:AppendFunctions(l:functions)
endfunc

func! s:AskGenerateFunctions()
    let l:choice = confirm("What to generate?", "&getter\n&setter\n&both", 3)

    if l:choice == 1
        return ["getter"]
    endif
    if l:choice == 2
        return ["setter"]
    endif
    if l:choice == 3
        return ["getter", "setter"]
    endif
endfunc

func! s:AskRepeatChoice()
    let l:choice = confirm("Use this selection for all following?", "&yes\n&no", 2)

    if l:choice == 1
        return 1
    endif
    if l:choice == 2
        return 0
    endif
endfunc

func! s:GetConfig()
    let config = {}

    if exists("b:phpacc_generate_functions")
        let config["generate_functions"] = b:phpacc_generate_functions
    elseif exists("g:phpacc_generate_functions")
        let config["generate_functions"] = g:phpacc_generate_functions
    else
        let config["generate_functions"] = 0
    endif

    return config
endfunc

func! s:GenerateAccessors(lineno, function_templates)
    let l:line = getline(a:lineno)

    if match(l:line, s:regex["attribute"])
        throw "No attribute matched on line"
    endif

    let l:matches = matchlist(l:line, s:regex["attribute"])
    let l:variable = l:matches[4]

    let l:type = s:DetermineType(a:lineno)
    let l:short = s:ShortType(l:type)

    let l:data = {}
    let l:data["variable"] = l:variable
    let l:data["function"] = s:GenerateFunctionName(l:variable)
    let l:data["type"] = l:type
    let l:data["shorttype"] = l:short
    let l:data["has_type"] = l:type != ""

    echom l:data["type"]

    let l:functions = []

    for l:template in a:function_templates
        let l:functions = add(l:functions, s:ProcessTemplate(l:template . ".tpl", l:data))
    endfor

    return l:functions
endfunc

func! s:AppendFunctions(functions)
    let l:lines = []
    for l:function in a:functions
        let l:lines = extend(l:lines, [""])
        let l:lines = extend(l:lines, split(l:function, "\n")) 
    endfor

    let l:appendlineno = s:FindLastLine()
    echom string(l:lines)

    call append(l:appendlineno, l:lines)
endfunc

func! s:FindLastLine()
    let l:last = line('$')
    let l:current = l:last

    while l:current >= 0
        if match(getline(l:current), s:regex["line_last"])
            return l:current
        endif
        let l:current = l:current - 1
    endwhile

    return l:last
endfunc

func! s:GenerateFunctionName(variable)
    return toupper(strpart(a:variable, 0, 1)) . strpart(a:variable, 1)
endfunc

func! s:ProcessTemplate(filename, data)
    let l:file = g:phpacc_template_dir . '/' . a:filename
    return vmustache#RenderFile(l:file, a:data)
endfunc

func! s:DetermineType(startline)
    let l:type = ""
    let l:currentno = a:startline - 1

    if (l:currentno) < 0 || match(getline(l:currentno), s:regex["comment_end"]) < 0
        return l:type
    endif

    while l:currentno > 0
        let l:currentline = getline(l:currentno)
        if match(l:currentline, s:regex["comment_start"]) > -1
            return l:type
        endif

        if match(l:currentline, s:regex["comment_var"]) > -1
            echo "Matched"
            let l:matches = matchlist(l:currentline, s:regex["comment_var"])
            return l:matches[1]
        endif

        let l:currentno = l:currentno - 1
    endwhile

    return l:type
endfunc

func! s:ShortType(type)
    if match(a:type, s:regex["type_short"]) < 0
        return a:type
    endif

    let l:matches = matchlist(a:type, s:regex["type_short"])
    return l:matches[1]
endfunc

let &cpo = s:old_cpo
