REBOL []

make-date-formater: func [ frmt ] [
	func [ date ] copy [ from-db-date date frmt ]
]

from-db-date: func [ d fo /local r dp ] [  
	either string? d [ 
		dp: parse d "-" ; warn .. d can have time appended
		r: copy ""
		parse separate-str lowercase fo [ 
			any [ 
				#"y" (append r dp/1 ) |
				#"m" (append r (z-fill dp/2 2 "0")) |
				#"d" (append r (z-fill dp/3 2 "0")) |
				set sep char! (append r sep )
			]
		] 
		r
	] [
		none
	]
]

to-db-date: func [ d fo /local sepa dp fp r f ] [ ; TODO: limitation - expects one kind of separator
	either string? d [ 
		sepa: to-string second fo
		dp: parse d sepa
		fp: parse lowercase fo sepa
		r: copy [ none none none ]
		repeat idx 3 [ 
			switch fp/:idx [
				"y" [ r/1: dp/:idx ]
				"m" [ r/2: dp/:idx ]
				"d" [ r/3: dp/:idx ]
			]
		] 
		rejoin [ r/1 "-" (z-fill r/2 2 "0") "-" (z-fill r/3 2 "0") ]
	] [
		none
	]
]

assure-date?: func [ d [ string! ] /local ps ] [
	ps: parse d "-"
	if/else error? try [ 
		y-ok: ( ( to-integer ps/1 ) > 2008 ) AND ( ( to-integer ps/1 ) < 2020 )
		m-ok: ( ( to-integer ps/2 ) > 0 ) AND  ( ( to-integer ps/2 ) <= 12 )
		d-ok: ( ( to-integer ps/3 ) > 0 ) AND ( ( to-integer ps/3 ) <= 33 )
	] [ false ] [
		if/else y-ok AND m-ok AND d-ok [ 
			rejoin [ ps/1 "-" ( z-fill ps/2 2 "0" ) "-" ( z-fill ps/3 2 "0" ) ]
		] [ 
			false
		]
	]
]

build-date?: func [ y m d ] [ assure-date? rejoin [ y "-" m "-" d ] ]

comment {
to-db-date: func [ d lang ] [ 
	switch lang [
		en-us [ from-us-date d ]
		en [ from-us-date d ] ; improve LATER, based on mysetup dateformat
		si [ from-slo-date d ] ]
]




from-db-date: func [ d lang ] [ 
	switch lang [
		en-us [ to-us-date d ]
		si [ to-slo-date d ] ]
]

from-us-date: func [ date ] [ from-x-date date [ m d y ] "/" ]
from-slo-date: func [ date ] [ from-x-date date [ d m y ] "." ]

from-x-date: func [ idate parts separator /local ps date ] [ 
	either not error? try [ 
		set :parts parse idate separator
		date: build-date? y m d
	] [ date ] [ 0 ]  
]

to-slo-date: func [ date ] [ to-x-date date [ d "." m "." y ] ]
to-us-date: func [ date ] [ to-x-date date [ m "/" d "/" y ] ]

to-x-date: func [ date formula /local y m d ] [ 
	either not error? try [ 
		set [ y m d ] parse date "-"
	] [ rejoin bind formula 'y ] [ none ]  
]
}
