scriptencoding=utf-8

" word-count.vimは現在開いているバッファの文字数をリアルタイムにステータス行へ
" 表示するプラグインです。
" 内部的には`g<C-g>`コマンドを利用していますが、改行コードの違いによって文字数
" が変化してしまう`g<C-g>`と違い、純粋な文字数をカウントすることができます。
"
" 以下を.vimrcへ追加してください。
" set statusline+=[wc:%{WordCount()}]
" set updatetime=500

" 以降は.vimrc等に追加するか、pluginフォルダへこのファイル自体をコピーします。
" autocmd で使用されているWordCount('char') のパラメータを変更すると文字数では
" なく、単語数やバイト数を表示可能です。
" 文字数は改行を除いた純粋な文字数になります。
"
" :call WordCount('char') " count char
" :call WordCount('byte') " count byte
" :call WordCount('word') " count word

augroup WordCount
  autocmd!
  autocmd BufWinEnter,CursorHold,CursorMoved * call WordCount('char',30)
augroup END

let s:WordCountStr = ''
let s:WordCountDict = {'word': 2, 'char': 3, 'byte': 4}
let s:VisualWordCountDict = {'word': 1, 'char': 2, 'byte': 3}
let s:FileSize = FileSize()
function! WordCount(...)
  if a:0 == 0
    return s:WordCountStr
  elseif a:0 == 2 && mode() == 'n'
      if a:2 < s:FileSize
          return s:WordCountStr
      endif
  endif
  " g<c-g>の何番目の要素を読むか
  let cidx = 3
  " 選択モードと行選択モードの場合はwordcountdictの値を-1することで合わせる
  " 矩形選択モードでこの調整は不要
  if mode() =~ "^v"
    silent! let cidx = s:VisualWordCountDict[a:1]
  else
    silent! let cidx = s:WordCountDict[a:1]
  endif

  " g<c-g>の結果をパースする
  let s:WordCountStr = ''
  let s:saved_status = v:statusmsg
  exec "silent normal! g\<c-g>"
  if v:statusmsg !~ '^--'
    let str = ''
    silent! let str = split(v:statusmsg, ';')[cidx]
    let cur = str2nr(matchstr(str,'\s\d\+',0,1))
    let end = str2nr(matchstr(str,'\s\d\+',0,2))
    " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
    if a:1 == 'char' && mode() == "n"
      " ノーマルモードの場合は1行目からの行数として改行文字の数を得る
      let cr = &ff == 'dos' ? 2 : 1
      let cur -= cr * (line('.') - 1)
      let end -= cr * line('$')
      let s:WordCountStr = printf('%d/%d', cur, end)
    elseif a:1 == 'char' && mode() =~ "^v"
      " 選択モード,行選択モードならば，g-<C-g>にある 選択 より改行文字の数を得る
      " 矩形選択ではこの処理はしない
      silent! let str = split(v:statusmsg, ';')[0]
      let vcur = str2nr(matchstr(str,'\s\d\+',0,1)) -1
      let vend = str2nr(matchstr(str,'\s\d\+',0,2)) -1
      " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
      let cr = &ff == 'dos' ? 2 : 1
      let cur -= cr * vcur
      let end -= cr * vend
      let s:WordCountStr = printf('%d/%d/%d', vcur+1, cur, end)
    endif
  endif
  let v:statusmsg = s:saved_status
  return s:WordCountStr
endfunction
