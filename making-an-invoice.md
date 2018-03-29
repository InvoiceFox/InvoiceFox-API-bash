# InvoiceFox / Cebelca.biz API calls
## Making an invoice

The goal of this document is to show the API calls needed to create an Invoice. Examples use curl, which is available on 
all platforms and you can use to execute calls directly.

### Set your API toke

Get the api token at *Nastavitve > Nastavitve dostopa* (bottom of the page). Set it as environmental variable in bash.

    TOKEN=`cat .token`

### Insert the customer to Cebelca

Assure partner does just that. If the partner is already in the database it returns it's ID. If it's not it adds it and 
returns it's ID.

````
curl -v -k \
	-u $TOKEN:x \
	-d "name=My Company&street=Downing street&postal=E1w201&city=London" \
	"https://www.cebelca.biz/API?_r=partner&_m=assure"
````
returns `>> ['ok',[{'id':1}]]`


### Add the Invoice head

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=$ARG" \
	"https://test.cebelca.biz/API?_r=invoice-sent&_m=insert-into"
````
returns:
````
>> ['ok',[{'id':1}]] 
````
### Add the invoice line (body) into the invoice (You can add many). 

id_invoice_sent is the ID of the invoice returned in previous call.

````
curl -v -k \
	-u $TOKEN:x \
	-d "title=programming&qty=10&mu=hour&price=50&vat=22&discount=0&id_invoice_sent=1" \
	"http://test.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````

returns:
````
````



if [[ $CMD == "rp1" && $ARG != "" && $ARG2 != "" ]]; then

    curl -v -k \
	-u $TOKEN:x \
	-d "date_of=22.12.2015&amount=10&id_payment_method=$ARG2&id_invoice_sent=$ARG" \
	"http://test.cebelca.biz/API?_r=invoice-sent-p&_m=insert-into"

fi

# prenesemo PDF računa

if [[ $CMD == "pdf" && ARG != "" ]]; then

    curl -v -k \
	-u $TOKEN:x -J -O \
	"http://test.cebelca.biz/API-pdf?id=$ARG&format=PDF&doctitle=Ra%C4%8Dun%20%C5%A1t.&lang=si&disposition=inline&res=invoice-sent&preview=0"
fi
#>> binary-pdf-data
