>> gen-where-filter [ name 1 ]
== "name = 1"
>> gen-where-filter [ name "asdasd1" ]
== "name = 'asdasd1'"
>> gen-where-filter [ name "asdasd'1" ]
== "name = 'asdasd''1'"
>> gen-where-filter [ name "Janko's" age 213 ]
== "name = 'Janko''s' AND age = 213"
