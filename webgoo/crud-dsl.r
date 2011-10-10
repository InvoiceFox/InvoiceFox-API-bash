REBOL [ ]

;
;  create partner data
;  delete partner 12
;  update partner 12 data
;  read partner 12
;  ;TODO SOMETHING LIKE IT LATER 
;  read partner-s
;  update partner-s where "name = janko" with data
;  read partner-s where "..." order by "..." 
;  delete partner-s where "
;  read partner join city join country 13

do-crud-dsl: func [ dsl /make-sql /local d set-id set-data data id ] [
	d: []
	set-id: [ set idw word! ( id: get idw ) | set id integer! | set idp path! ( id: select get (first idp) (second idp) ) ]
	set-data: [ set dataw word! ( data: get dataw ) | set data block! ]
	parse dsl [ 
		'insert-into set table word! set-data ( d: [ "INSERT INTO " table " (" (list-keys data) ") VALUES (" (list-values data) ") ; " ] ) 
		| 'delete set table word! set-id ( d: [ "DELETE FROM " table " WHERE id = " id " ; " ] ) 
		| 'update set table word! set-id set-data ( d: [ "UPDATE " table " SET " list-key=value data " WHERE id = " id " ; " ] )
		| 'select set table word! set-id ( d: [ "SELECT * FROM " table " WHERE id = " id " ; " ] )
	]
	either make-sql [ rejoin d ][ SQL rejoin d ]
]

list-keys: func [ data ] [ _list-* data 'key ]
list-values: func [ data ] [ _list-* data 'val ]

_list-*: func [ data which ] [ 
	accumulate [ key val ] acc "" data [ rejoin [ acc (either empty? acc [ "" ] [ ", " ]) (either equal? which 'key [ key ][ sql-enquote val ]) ] ]
]

list-key=value: func [ data ] [ 
	accumulate [ key val ] acc "" data [ rejoin [ acc (either empty? acc [ "" ] [ ", " ]) key "=" sql-enquote val ] ]
]
