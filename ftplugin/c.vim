au BufEnter *.c         let b:fswitchdst = 'h'
au BufEnter *.h         let b:fswitchdst = 'c,cpp,cc'

au BufEnter *.cpp,*.cc  let b:fswitchdst = 'hpp,hh,h'
au BufEnter *.hpp,*.hh  let b:fswitchdst = 'cpp,cc'
