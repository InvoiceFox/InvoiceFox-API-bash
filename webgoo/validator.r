REBOL []

validator: context [

    go: func [ data [block!] rules [block!] 
        /local vnotes rdata vn current previous codeb skip key
    ] [
		forskip data 2 [ change data to-word first data ] ; todo -- this is because of bug in cheyenne, was fixed in latest v.
		data: copy data
		vnotes: copy rdata: copy [] previous: copy "" 
        parse rules [ (  )
            some
            [ ( current: copy "" skip: false )
                set name set-word! (key: to-word name) 
                [ 
                    'required ( 
                        unless all 
                            [ (current: select data key) (not empty? to-string current) ]
                            [ skip: true  add-vnote vnotes key "required" ] )
					| 'optional 
						[ set def string! | set def integer! | set def decimal! | 'none (def: 'none) ] ( 
							unless all 	[(current: select data key) (not empty? current)] 
								[ current: def ] )
;                    | 'optional 
;                        [ set def string! | set def integer! | 'none (def: 'none) ] ( 
;                            unless all 
;                                [ (current: select data key) (not empty? to-string current) ] 
;                                [ skip: true  current: to-string def ] )
                    | 'create set code paren! ( current: do code ) 
                ] 
                any 
                [ 'and 
                    [ 
                        'integer ( 
                            unless skip [ 
                                if error? try [ current: to-integer current ] 
                                              [ skip: true   add-vnote vnotes key "not integer" ] ] )
						| 'decimal ( if error? try 
								[ current: to-decimal fix-decimal trim current ] 
								[ append vnotes reduce [ key "not decimal" ] ] )
                        | 'email ( unless skip [ 
                                unless is-email? current [ skip: true   add-vnote vnotes key "not email" ] ] )
                        | 'url ( ) ;todo
                        | 'only-ascii (  ) ;todo
                        | 'single-word ( unless skip [ 
                                current: trim current 
                                if find current " " [ skip: true  add-vnote vnotes key "not single word" ] ] )
                        | 'file ( unless skip 
                            [ unless greater? length? current 1 
                                [ skip: true  add-vnote vnotes key "not file" ] ] ) 
                            opt [ 'of set sfs block! ( unless skip
                                    [ unless has-suffix? current sfs 
                                        [ skip: true  add-vnote vnotes key "wrong suffix" ] ] ) ]
                        ; actionable words
                        | 'trim-it ( unless skip [ current: trim current ] )
                        | 'clear-http ( unless skip [ current: trim current ] )
                        | 'ensure-http ( unless skip [ current: trim current ] )
                        | 'hash-it ( unless skip [ 
                                current: checksum/secure join current "refaktor-salt-0123456789" ] )
						| 'suffix-of ( unless skip [ current: suffix? current/1 ] )
                    ]
                ]
                opt
                [ 'check set code paren! ( codeb: to-block code
                    unless none? vn: (do bind codeb 'current) [ add-vnote vnotes key vn ] ) ]
                opt [ 'do set code paren! ( codeb: to-block code  do bind codeb 'current ) ]
                opt [ 'calculate set code paren! ( codeb: to-block code  current: do bind codeb 'current ) ]
                ( 
		    if logic? current [ current: to-integer current ]
		    append rdata reduce [ key current ]
                    if error? try [ previous: copy current ][ previous: current ] )
            ]
        ]
        reduce either empty? vnotes [ [ true rdata ] ] [ [ false vnotes ] ]
    ]
    is-email?: func [ a ] [ parse a [ to "@" to "." to end ] ]
    add-vnote: func [ vnotes key msg ][ append vnotes reduce [ key msg ] ]
    has-suffix?: func [ current sfs ] [ find sfs to-word to-string next suffix? current/1 ]
]
