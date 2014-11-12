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

func! phpacc#GenerateAccessors(lineno)
    let l:line = getline(a:lineno)

    if match(l:line, s:regex["attribute"])
        throw "No attribute matched on line"
    endif

    let l:matches = matchlist(l:line, s:regex["attribute"])
    let l:variable = l:matches[4]

    let l:type = s:DetermineType(a:lineno)
    let l:short = s:ShortType(l:type)

    echom "Variable: " . l:variable
    echom "Type: " . l:type
    echom "Short type: " . l:short

    let l:data = {}
    let l:data["variable"] = l:variable
    let l:data["function"] = s:GenerateFunctionName(l:variable)
    let l:data["type"] = l:type
    let l:data["shorttype"] = l:short

    let l:function = s:ProcessTemplate("getter.tpl", l:data)
    echom l:function

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
        echom "Current: " . l:currentno
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
