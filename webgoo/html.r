REBOL [] 

html: context [ 

	table: func [ c ] [ wrap c "table class='payments' cellspacing='1'" ]

	table-row: func [ ns cell ] [ wrap (accumulate x acc copy "" ns [ join acc wrap x cell ]) "tr" ]

	options: func [ d c ] [ 
		accumulate [ N V ] ACC "" d [ rejoin [ 
			ACC wrap N rejoin [ "option value='" V "'" (either equal? c V [ " selected='selected' "] [ "" ]) ] 
		] ]
	]
]

; BELOW IS CEBIZ FILE

lis: func [ items inner outer ] [
    res: copy ""
    inner: any [ inner "li" ]
    foreach it items [ 
        append res wrap it inner
    ]
    wrap res any [ outer "ul" ]
]

wrap: func [ value name ] [
    rejoin [ "<" name ">" value "</" name ">" ] 
]

