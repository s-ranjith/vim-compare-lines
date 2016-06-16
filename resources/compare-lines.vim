" Vim plugin to diff two lines of a buffer and navigate through the changes
" File:     compare-lines.vim
" Author:   statox
" License:  This file is distributed under the MIT License

" Create the commands
command! -nargs=* CL2                call <SID>PreTreatmentFunction("Compare2", <f-args>)
command! -nargs=* CL                 call <SID>PreTreatmentFunction("Compare", <f-args>)
command! -nargs=* CompareLines       call <SID>PreTreatmentFunction("Compare", <f-args>)
command! -nargs=* FL                 call <SID>PreTreatmentFunction("Focus", <f-args>)
command! -nargs=* FocusLines         call <SID>PreTreatmentFunction("Focus", <f-args>)
command! -nargs=* FCL                call <SID>PreTreatmentFunction("CompareFocus", <f-args>)
command! -nargs=* FocusCompareLines  call <SID>PreTreatmentFunction("CompareFocus", <f-args>)

command! XL call <SID>RestoreAfterCompare()

" This function is called to
" - get the line numbers
" - check their existence in the buffer
" - save the foldmethod
" - create the mappings of the plugin
function! s:PreTreatmentFunction(function, ...)
    " Depending on the number of arguments define which lines to treat
    if len(a:000) == 0
        let l1=line(".")
        let l2=line(".")+1
    elseif len(a:000) == 1
        let l1 =line(".")
        let l2 =str2nr(a:1)
    elseif len(a:000) == 2
        let l1 = str2nr(a:1)
        let l2 = str2nr(a:2)
    else
        echom "Bad number of arguments"
        return
    endif

    " Sort the lines
    if ( l1 > l2 )
        let temp = l2
        let l2 = l1
        let l1 = temp
    endif

    " Check that the lines are in the buffer
    if (l1 < 1 || l1 > line("$") || l2 < 1 || l2 > line("$"))
        echom ("A selected line is not in the buffer")
        return
    endif

    " Save user configurations
    " Handle foldmethod configuration
    let s:foldmethod_save=&foldmethod
    let s:hlsearch_save=&hlsearch
    execute "mkview! " . &viewdir . "compare-lines"

    " Change foldmethod to do ours foldings
    set foldmethod=manual

    " Create a mapping to quit the compare mode
    if !empty(maparg('<C-c>', 'n')) 
        let s:mapping_save = maparg('<C-c>', 'n', 0, 1)
    endif
    nnoremap <C-c> :XL<CR>

    " Depending on the command used call the corresponding function
    if a:function == "Compare"
        call <SID>CompareLines(l1, l2)
    elseif a:function == "Compare2"
        call <SID>CompareLines2(l1, l2)
    elseif a:function == "Focus"
        call <SID>FocusLines(l1, l2)
    elseif a:function == "CompareFocus"
        call <SID>CompareLines(l1, l2)
        call <SID>FocusLines(l1, l2)
    else
        echoe "Unkown function call"
        return
    endif
endfunction

function! s:RestoreAfterCompare()
    " Remove search highlight
    nohlsearch

    " Remove foldings created by the plugin
    normal! zE

    " Restore user configuration
    execute "loadview " . &viewdir ."compare-lines"
    let &foldmethod=s:foldmethod_save
    let &hlsearch=s:hlsearch_save

    " Restore the mapping to its previous value
    unmap <C-c>
    if exists("s:mapping_save")
        execute (s:mapping_save.noremap ? 'nnoremap ' : 'nmap ') .
             \ (s:mapping_save.buffer ? ' <buffer> ' : '') .
             \ (s:mapping_save.expr ? ' <expr> ' : '') .
             \ (s:mapping_save.nowait ? ' <nowait> ' : '') .
             \ (s:mapping_save.silent ? ' <silent> ' : '') .
             \ s:mapping_save.lhs . " "
             \ s:mapping_save.rhs
    endif
endfunction

" Get two different lines and put the differences in the search register
function! s:CompareLines2(l1, l2)
    let l1 = a:l1
    let l2 = a:l2

    " Get the content of the lines
    let line1 = getline(l1)
    let line2 = getline(l2)

    let pattern = ""

    echo "LCS: " . LCSdynamic(line1, line2)

    "let permutationsL1 = GenerateStringPermutations(line1, line2)
    "echo "nombre de permutations: " . len(permutationsL1)
    "echo permutationsL1

    " Search and highlight the diff
    "execute "let @/='" . pattern . "'"
    "set hlsearch
    "normal! n
endfunction

function! FillRecursive(len1, len2, char)
  if a:len2 == -1
    return map(range(a:len1), a:char)
  endif

  return map(range(a:len1), 'FillRecursive(a:len2, -1, a:char)')
endfunction

function! LCSdynamic(l1, l2)
    let len1 = len(a:l1)
    let len2 = len(a:l2)

    " Initialize the matrix with zeros
    let lengths = FillRecursive(len1 + 1, len2 + 1, 0)
    
    " Caculate the values of the matrix
    for i in range(len1)
        let x = a:l1[i]
        for j in range(len2)
            let y = a:l2[j]
            if x == y
                let lengths[i+1][j+1] = lengths[i][j] + 1
            else
                let lengths[i+1][j+1] = max([lengths[i+1][j], lengths[i][j+1]])
            endif
        endfor
    endfor

    " Read the substring out from the matrix
    let result = ""
    let x = len1
    let y = len2
    let cpt = 2
    let continue = 1

    while (x != 0 && y != 0)
       if ( lengths[x][y] == lengths[x-1][y] )
            let x -= 1
        elseif ( lengths[x][y] == lengths[x][y-1] )
            let y -= 1
        else
            "TEST

            if ( a:l1[x-1] != a:l2[y-1] )
                throw "AssertionError"
            endif

            "TEST


            let result = a:l1[x-1] . result
            let x -= 1
            let y -= 1
        endif 
    endwhile

    return result
endfunction

function! LCSrecu(l1, l2)
    "http://rosettacode.org/wiki/Longest_common_subsequence#Java

    let len1 = len(a:l1)
    let len2 = len(a:l2)

    if (len1 == 0 || len2 == 0)
        return ""
    elseif (a:l1[len1-1] == a:l2[len2-1])
        return LCS(strpart(a:l1, 0, len1-1),strpart(a:l2, 0, len2-1)) . a:l1[len1-1]
    else
        let x = LCS(a:l1, strpart(a:l2, 0, len2-1))
        let y = LCS(strpart(a:l1, 0, len1-1), a:l2)

        if len(x) > len(y)
            return x
        else
            return y
        endif
    endif
endfunction


function! GenerateStringPermutations(l1, l2)
    let permutations = []
    let continue = 1
    let iterations = 0

    for startIndex in range(0, len(a:l1)-1)
        let permutationsIndex = []
        let continue = 1
        let permutationSize = len(a:l1)-startIndex

        for permutationSize in range(1, len(a:l1)-startIndex)
            let iterations += 1
            let permutation = strpart(a:l1, startIndex, permutationSize)
            if match(a:l2, permutation) != -1
                call add(permutationsIndex, permutation)
            else
                let continue = 0
            endif
        endfor
        call add(permutations, permutationsIndex)
    endfor

    echo "iterations: " . iterations
    return permutations
endfunction

" Get two different lines and put the differences in the search register
function! s:CompareLines(l1, l2)
    let l1 = a:l1
    let l2 = a:l2

    " Get the content of the lines
    let line1 = getline(l1)
    let line2 = getline(l2)

    let pattern = ""

    " Compare lines and create pattern of diff
    for i in range(strlen(line1))
        if strpart(line1, i, 1) != strpart(line2, i, 1)
            if pattern != ""
                let pattern = pattern . "\\|"
            endif
            let pattern = pattern . "\\%" . l1 . "l" . "\\%" . ( i+1 ) . "c"
            let pattern = pattern . "\\|" . "\\%" . l2 . "l" . "\\%" . ( i+1 ) . "c"
        endif
    endfor

    " Search and highlight the diff
    execute "let @/='" . pattern . "'"
    set hlsearch
    normal! n
endfunction

" Creates foldings to focus on two lines
function! s:FocusLines(l1, l2)
    let l1 = a:l1
    let l2 = a:l2

    if (l1 > 1)
        execute "1, " . ( l1 - 1 ) . "fold"
    endif

    if ( l2-l1 > 2 )
        execute (l1 + 1) . "," . (l2 - 1) . "fold"
    endif

    if (l2 < line('$'))
        execute (l2 + 1) . ",$fold"
    endif
endfunction