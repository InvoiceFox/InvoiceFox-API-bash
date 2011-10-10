REBOL [ ]

pformat-int: func [ int ] [
	either integer? int [
		a: to-string int
		d: tail a loop to-integer ((length? a) - 1) / 3 [ d: back back back d  insert d "," ]
		head d
	] [
		int
	]
]

pretty-format-num: func [ num kilo decim /local a d d2 ] [
	if error? try [ num: to-decimal num ] [ num: 0 ]
	a: to-string round num * 100
	either equal? to-integer a 0 [ 
		rejoin [ "0" decim "00" ]
	] [ 
		d: tail a  d: back back d  insert d decim
		loop to-integer ((length? a) - 1 - 3) / 3 [ 
			d: back back back d  insert d kilo ]
		join either equal? first d2: head d to-char decim [ "0" ][ "" ] 
		d2
	]
]

leave-decimals-format-num: func [ num /local n ] [
	n: replace/all to-string num "." ","
	join either found? n2: find n "," [ 
		either greater? length? n2 2 [ n ] [ join n "0" ]
	] [
		rejoin [ n "," "00" ]
	] "€"
]

pretty-format-num-short: func [ num kilo decim /local a cursr ] [ 
	num: to-string num
	a: reverse copy num 
	either found? cursr: any [ find a decim find a kilo ] [
		either zero? to-integer copy/part a cursr
			[ copy/part num find num first cursr ] [ replace num kilo decim ] 
	] [ num ]
]

make-money-formater: func [ before after kilo decim /short ] [
	func [ num ] copy [ 
		rejoin [ before ( pretty-format-num num kilo decim ) after ]
	]
]

make-money-formater-short: func [ before after kilo decim /short ] [
	func [ num ] copy [ 
		rejoin [ before ( pretty-format-num-short num kilo decim ) after ]
	]
] ; TODO WARN -- we would have to use closures here (and have it in just one formater

is-email?: func [ a ] [ parse a [ to "@" to "." to end ] ]

fix-decimal: func [ s ] [
	dot1: find s "." comm1: find s "," 
	if all [ dot1 comm1 ] [
		s: replace/all s either lesser? index? dot1  index? comm1 ["."][","] ""
	]
	if comm1 [
		s: replace/all s "," "."
	]
	s
]

templatize: func [ tpl data /local r ] [ 
	r: copy tpl
	forskip data 2 [ replace/all r rejoin [ "{" first data "}" ] second data ]
	r
 ]


to-js-nl: func [ a ] [
	replace/all copy a "^/" "\n"
]

