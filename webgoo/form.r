REBOL []

*form-data*: copy [ ]

make-rates-list: func [ rates ] [
	join (accumulate x acc "[ " rates [ 
		rejoin [ 
			acc
			(either equal? x first rates [" "][", "]) 
			{[ "} x {", "} x {%" ]}  
		]
	]) " ]"
]

prepare-form-data: does [ 
    if select session/content 'form-data [ 
        *form-data*: copy session/content/form-data
        session/content/form-data: none
    ]
]

preserve-form-data: does [ 
    session/content/form-data: request/content
]


is-suffix: func [ sfs ] [
    to-logic? find sfs logo-suffix: suffix? filedata/1 
]
        ; either find suffixes logo-suffix: suffix? filedata/1 [
        ; ][ "" ]

handle-uploaded-file: func [ req-name file-to-write ][ 
    if all [ file: select request/content req-name  greater? length? file 1 ][
		request/store/as request/content/:req-name join file-to-write suffix? file/1
	]
]

zzz___handle-uploaded-file: func [ req-name file-to-write ][ 
    if all [ file: select request/content req-name  greater? length? file 1 ][
        either file? file/2 [
            ; write/binary join get-user-dir filename read/binary join incomingdir filedata/2
        ][
            if file/2 [
                write/binary join file-to-write suffix? file/1 file/2
            ]
        ]
	]
]

;
; START FORM

make-param: func [ N P ] [
    rejoin [ " " N "='" P "'" ]
]

make-param-if: func [ N P /local P2 ] [
	P2: to-string P
    either empty? P2 [ "" ] [ make-param N P2 ]  
]

append-param: func [ S N P] [
    append S make-param N P
]

make-input-field: func [ N T V CL SI ] [
	rejoin [ 
		"<input " make-param "type" (to-string T)  make-param "name" N 
		(either not equal? T 'file [ make-param-if "value" V ] [ "" ])
		make-param-if "class" CL  make-param-if "size" SI  "/>"
	]
]

make-textarea: func [ N T V CL SI ] [
	rejoin [ 
		"<textarea " make-param "name" N 
		make-param-if "class" CL  
		(either SI [ 
				either pair? SI 
				[ join make-param "cols" SI/1 make-param "rows" SI/2 ] 
				[ make-param "cols" SI ] 
		] [ "" ]) ">" V "</textarea>"
	]
]

make-input-block: func [ N T V CL NT SI ] [ 
    R: copy ""
    case [ 
        any-is? [ equal? T ] copy [ 'text 'submit 'password 'file ] [ 
            rejoin [ "<div class='field'>" (make-input-field N T V CL SI) "<em>" NT "</em>" "</div>" ]
        ]
        equal? T 'textarea [ 
            rejoin [ "<div class='field'>" (make-textarea N T V CL SI) "<em>" NT "</em>" "</div>" ]
        ]
    ]
]

make-input-row: func [ N T L V CL NT SI ] [
    rejoin [ "<div class='row'><label for='" N "'>"
            either none? L [ name-to-label N ] [ either empty? L [ "" ] [ L ] ]
             "</label>" make-input-block N T V CL NT SI
            "</div>" ]
]

name-to-label: func [ name ] [
	label: copy name
	uppercase/part (replace/all label  "_" " ") 1
]

get-form-value: func [ N V ] [
    ;print [ N " " V ]
    any [ ( select *form-data* to-word N ) V  ]
]

start-fieldset: func [ L CL ] [
	rejoin [ {<fieldset class="} CL {"><legend>} L {</legend>} ]	
]

end-fieldset: func [ ] [
	rejoin [ {</fieldset><br style='clear: both;'/>} ]	
]

make-form: func [ d ] [
    prepare-form-data
    F: copy ""
    parse d [ ( append F "<form " ) 
        'that SOME [ 'posts ( M: 'post ) | 'gets ( M: 'get ) ] ( append-param F "method" M )
        OPT [ 'multipart ( append-param F "enctype" "multipart/form-data" ) ]
        'to set P string! ( append-param F "action" P )
        OPT [ 'with SOME [ 
                'onsubmit set P string! ( append-param F "onsumit" rejoin [ "return " P ";" ] ) |
                'id set P string! ( append-param F "id" P ) |
                'class set CL string!  ( append-param F "class" CL )
            ] 'end
        ] ( append F ">" )
		ANY [ 
			( HN: HV: copy "" ) 
			'make 'hidden 'field set HN string!
			OPT [ 'with SOME [ 'value set HV string! ] 'end ]  (  append F make-input-field HN 'hidden HV "" "")
		]
        ANY [ ( CL: "" dont: false L: ID: ST: none)
			'begin 'fieldset set L string! 
				OPT [ 'with SOME [
						'id set ID string! |
						'style set ST string! |
						'class set CL string!
					] 'end
				] ( append F rejoin [ "^/<fieldset " (make-param-if "id" ID) " " (make-param-if "class" CL) " " 
										(make-param-if "style" ST) "><legend>" L "</legend>" ] ) |
			'end 'fieldset ( append F "^/</fieldset>") |
			[	'skip (dont: true) | 
				'make |
			]
			SOME [ 
				'text 'field set N string! ( T: 'text ) |
				'password 'field set N string! ( T: 'password ) |
				'file 'field set N string! ( T: 'file ) |
				'submit 'button set N string! ( T: 'submit ) |
				'text 'area set N string! ( T: 'textarea )
			]
			( L: none C: V: NT: CL: SI: copy "" )
			OPT [ 'with SOME [ 
					'no 'label ( L: copy "" ) |
					'label set L string! |
					'caption set C string! |
					'value set V string! |
					'note set NT string! |
					'size set SI integer! |
					'size set SI pair! |
					'class set CL string!
				] 'end
			] ( if not dont [ append F make-input-row N T L ( get-form-value N V ) CL NT SI ] )
			|
			'raw set rawstr string! ( append F rawstr )
			
        ]
        ( append F "<div class='row'></div></form>" )
    ]
    F
]

make-form-sample: [
	session: [ content [ form-data []  messages [] ]]
    print make-form [ that posts to "act.html" with id "form" onsubmit "check()" end
		make text field "username" with label "Username" class "CLASS1" end
		make text field "email" with label "Your Email" end
		make password field "password" with label "Password" end
		make submit button "addbtn"
    ]

    print make-form [ that posts to "act.html" 
		make text field "username" with label "Username" class "CLASS1" end
		make submit button "addbtn"
    ]

    print make-form [ that posts to "act.html" 
		make hidden field "timi"
		make text field "username" with label "Username" class "CLASS1" end
		make submit button "addbtn"
    ]
]

