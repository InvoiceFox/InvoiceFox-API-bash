REBOL []
enc-html: func [
    "Make HTML tags into HTML viewable escapes (for posting code)"
    text /no-copy
][
	if not found? no-copy [ text: copy text ]
    foreach [from to] ["&" "&amp;"  "<" "&lt;"  ">" "&gt;" "'" "&apos;" {"} "&quot;"] [
        replace/all text from to
    ]
]

enc-js: func [ text ] [
    foreach [from to] [ {"} {\"} {'} {\'} ] [
        replace/all text from to
    ]
]

to-safe-for-js: func [ text ] [
    foreach [from to] [ {'} {`} {"} {} ] [
        if not none? text [ replace/all text from to ]
    ]
]

any-is?: func [ 'PRE s ] [ 
	while [ not tail? s ] [ s: next insert s PRE ]
	any reduce head s 
]

any-is??: func ['fun data][
	repeat _x_ data compose [if (fun) get _x_ [break/return true]] false
]

calc-with: func [ 'wrd bs ] [ 
	foreach b bs [ set wrd do b ] 
]

z-fill: func [ str num char ] [ 
	either string? str [
		insert/dup str char ( num - length? str ) 
		head str 
	] [
		str
	]
]

smart-uc-after: func [ str sep ] [
	parse str [ ANY [ thru sep mark: ( uppercase/part trim mark 1 insert mark " " ) :mark ] ]
	str
] 

smart-case: func [ str ] [
	calc-with X [ 	
		[ lowercase str ]
		[ uppercase/part X 1 ]
		[ smart-uc-after X "." ]
		[ smart-uc-after X "?" ]
		[ smart-uc-after X "!" ]
]]

map: func [ 'word data body ] [
    foreach :word data reduce [:append [] to-paren body]
]

accumulate: func [ 'word 'accum start data body ] [
	either none? data [ none ] [
		set :accum start
		foreach :word data compose [ set :accum ( body ) ]
		get :accum
	]
]

join3: func [ a b c ] [ join join a b c ]

is-win?: does [ system/version/4 = 3 ] 
is-mac?: does [ all [ system/version/4 = 2 system/version/5 <= 3 ] ]  
is-nix?: does [ not any [is-win? is-mac?] ]  

separate-str: func [ s /local r ] [ r: copy [] foreach a s [ append r a ] r ]

epoch: func [ ] [
        date: now
        seconds: ((date - 1-1-1970) * 86400) + (date/time/hour * 3600) + (date/time/minute * 60) + date/time/second
        zone: now/zone
        zone: zone/hour
        zone: zone * 3600
        to-integer seconds: seconds - zone ; minus a minus gives plus
]

osys: context [
	get-temp-dir: func [] [ 
		either is-win? 
			[ %/d/temp/ ] 
			[ %/tmp/ ]
	]
]
calc-next-doc-title-old: func [ t /local inc-y splt maint aftert splt2 numt beforet ] [
        debug/probe t
        t: trim t
        inc-y: func [ t ] [ z-fill (to-string (+ 1 to-integer t)) length? t "0" ]
        splt: find t " "
        maint: either found? splt [ copy/part t splt ] [ t ]
        aftert: either found? splt [ copy splt ] [ "" ]
        splt2: any [ find/last maint "-" find/last maint "/" ]
        either splt2 [
		splt2: next splt2
                numt: copy splt2
                beforet: copy/part maint splt2
                either not error? try [ numt2: inc-y numt ] [
                        rejoin [ beforet numt2 aftert ]
                ] [
			""
		]
        ] [
		""
        ]
]

calc-next-doc-title-old1: func [ t /local d2 d4 is-y inc-y cpp m p1 p2 p3 p4 p5 y1 y2 ] [
	debug/probe t
        inc-y: func [ t ] [ z-fill (to-string (+ 1 to-integer t)) length? t "0" ]
	either parse t [ copy n1 [ thru "-" | thru "/" ] copy n2 to end ] [
		rejoin [ n1 inc-y n2 ]
	] [
		""
	]
]

calc-next-doc-title-new: func [ t /last-year /local d2 d4 is-y inc-y cpp m p1 p2 p3 p4 p5 y1 y2 aftert ] [
	debug/probe "--"
	debug/probe t
        d2: next next d4: to-string either last-year [ now/year - 1 ] [ now/year ]
        either none? t [
                join d2 "-0001"
        ] [
                is-y: func [ t ] [ parse t [ d4 | d2 ] ]
                inc-y: func [ t ] [ z-fill (to-string (+ 1 to-integer t)) length? t "0" ]
                cpp: func [ m n ] [ copy/part m n ]

		aftert: any [ find t " "  "" ]	
		if not empty? aftert [ t: copy/part t aftert ]

                either parse t [ (p2: "")
                        m: any letter n: (p1: cpp m n)
                        opt [ separator (p2: first n) ]
                        m: some digit n: (p3: cpp m n)
                        separator (p4: first n)
                        m: some digit n: (p5: cpp m n)
                ] [
                        either all [ any [ y1: is-y p3  y2: is-y p5 ] not equal? y1 y2 ] [
                                rejoin [ p1 p2 (either is-y p3 [ p3 ][ inc-y p3 ]) p4 (either is-y p5 [ p5 ][ inc-y p5 ]) aftert ]
                        ] [
                                either last-year [ "" ] [ calc-next-doc-title-new/last-year t ]
                        ]
                ] [
                        ""
                ]
        ]
]

calc-next-doc-title: func [ t /local doct ] [
	debug/probe either empty? doct: calc-next-doc-title-new t [
		calc-next-doc-title-old t
	] [
		doct	
	]
]


SKV: context [ ; STUPID KEY VALUE SERIALIZATION --- add validation dialect we use already later

	decode: func [ raw rules /local d k v ] [
		d: copy []
		parse raw [ any [ copy k to "::" 2 skip copy v [ to ";;" | to end ]
			(append d reduce [ to-word (replace k ";;" "") v ] ) ] ]
		validator/go d rules
	]
]

gen-where-filter-from: func [ decoder raw rules /local filter acc ] [
	either all [ first filter: decoder/decode raw rules ] [
		gen-where-filter second filter
	] [
		"1 = 0" ; if no falidation allow no data rather than all data
	]				
]
gen-where-filter: func [ filter /local acc ] [
	acc: copy ""
	forskip filter 2 [ 
		if not any-none? second filter [
			acc: rejoin [ acc (either empty? acc [ "" ] [ " AND " ]) first filter " = " enquote/sql second filter ]
		]
	] 
	either empty? acc [
		"1 = 1"
	] [
		acc 	
	]				
]
