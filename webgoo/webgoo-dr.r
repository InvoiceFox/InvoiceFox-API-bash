REBOL [
	Purpose: "Rebol webdeb utilities for Data-resources"
]

comment {get-user-data: func [ file ] [
    get-user-data-of file session/content/user-id
]

get-user-data-of: func [ file user ] [
    load get-user-data-path file user
]

save-user-data: func [ file data ] [ 
	either get-lock file-path: get-user-data-path file session/content/user-id [
		write file-path mold data 
	] [
		print "Error with locks! Data didn't get saved!" ; TODO -- log this!!!!
	]
	; release-lock file-path
]

get-default-data: func [ file ] [
    load to-file rejoin [ "defaults/" file ".r" ]
]}

get-by-attr: func [ data attr value ] [
    foreach d data [ if equal? ( select d attr ) value [ return d ]  ]
    none
]

find-by-attr: func [ data attr value ] [
    while [ not tail? data ] [ 
        either equal? (select ( first data ) attr) value [ return data ] [ data: next data ] 
    ]
]

get-locks-dir: does [ "lock_" ]

get-lock: func [ url /local openlock fname locked opened ] [
	opened: join fname1: to-file rejoin [  get-locks-dir calc-lock-name url ] ".ope" 
	locked: rejoin [ fname1 ".loc" ]
	loop 10 [
		if exists? locked [ if greater? (third difference now to-date read locked) 5 [ delete locked ] ] ; clean timeouted locks
		write opened to-string now
		if not error? try [ rename opened locked ] [ return true ]
		wait (random 0.2) + 0.1
	]
	false
]

release-lock: func [ url ] [
	delete rejoin [ to-file get-locks-dir calc-lock-name url ".loc" ]
]

calc-lock-name: func [ url ] [ enbase/base to-string checksum url 16 ]