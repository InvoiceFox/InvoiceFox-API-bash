# InvoiceFox / Cebelca.biz API calls


## Making an invoice

The goal of this document is to show the API calls needed to create an Invoice, fiscalize it (or not), get PDF of it and mark it paid. Some actions can be performed via different calls, depending what is best in your situation. 

You can read general API guidelines here: (https://github.com/InvoiceFox/Workonomic-API-bash/blob/master/API-docs.md)[General API guidelines]

Examples use curl, which is available on all platforms and you can use to test API calls directly.


### Set your API toke

Get the api token at *Nastavitve > Nastavitve dostopa* (bottom of the page). Set it as environmental variable in your shell.

    TOKEN=`cat .token`


### Insert the customer (partner) to Cebelca

Assure does just that. If the partner is already in the database it returns it's ID. If it's not it adds it and 
returns it's ID.

arguments:

 * **name** - company or person's name
 * **street** - self explanatory
 * **postal** - postal code / zip code
 * **city** - self explanatory
 * **country** - self explanatory

````
curl -v -k \
	-u $TOKEN:x \
	-d "name=My Company&street=Downing street&postal=E1w201&city=London" \
	"https://www.cebelca.biz/API?_r=partner&_m=assure"
````
returns the ID of the partner: 
````
['ok',[{'id':1}]]
````


### Add the Invoice head (option 1)

Invoice consists of invoice head and multiply invoice body lines. First you add the Invoice head and get the ID of added invoice. API offers multiple ways of adding an invoice, some more suitable for specific situatuions. This is one:

arguments

* **date_sent** - date when invoice was issued, formatted in dd.mm.yyyy.
* **date_to_pay** - date to which invoice should be payed. If invoice is already paid when issued, you can show that too.
* **date_served** - date when service or item was delivered. Required in Slovenia. Could also be two dates.
* **id_partner** - ID of the partner, gotten from previous call.

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=$ARG" \
	"https://test.cebelca.biz/API?_r=invoice-sent&_m=insert-into"
````
returns ID of the invoice:
````
>> ['ok',[{'id':1}]] 
````

### Add the invoice head - smart (option 2)

This option helps API users to fill in some information automaticall, that would otherwise require more API calls.

so what's smart about it:
 * taxnum can be used instead of id_partner to find the right customer/partner, so you don't have to store the cebelca partner ID-s on your side, in this case set id_partner to 0.
 * id_document_ext can be set with your ID for this invoice (for example ID of an order **if it's unique**). Then you can use this external ID to mark invoice paid or get he PDF (which is usually separate action called later). This way you don't need to store ID-s of invoices (mapping to orders for example) on your side.
 * if invoice has foreign currency and you set conv_rate to 0 it get's the current conv_rate from Bank of Slovenia automatically.

arguments are the same as with previous call. With some additions.

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=1&id_currency=2&conv_rate=0&id_document_ext=213" \
"https://www.cebelca.biz/API?_r=invoice-sent&_m=insert-smart-2"
````

### Add the invoice line (body) into the invoice (You can add more than one of course). 

You then add one or more invoice body lines. The contents of the invoice.

* **title** - name or description of the service / item you sold (unlimited text)
* **qty** - quantity of items sold (decimal number)
* **mu** - measuring unit (like hour, piece, kg)
* **price** - price per unit (decimal)
* **vat** - Value Added Tax (or tax in general) in percentage, decimal. For Slovenia it's 0, 9.5 or 22 currently.
* **discount** - discount in percentage, decimal.
* **id_invoice_sent** - ID of invoice head, gotten from previous call

````
curl -v -k \
	-u $TOKEN:x \
	-d "title=programming&qty=10&mu=hour&price=50&vat=22&discount=0&id_invoice_sent=1" \
	"http://test.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````


### Add payment to invoice (option 1)

To add information about payment to invoice use the method below. Here you also set the amount of payment so it can be partial payment. You can add multiple payment lines to invoice, with different amounts, dates, methods.

* **date_of** - self explanatory
* **amount** - amount paid, decimal number
* **id_payment method** - integer representing payment method
  * 1 - cash
  * 2 - credit card 
  * 3 - TODO 
* **id_invoice_sent** - ID of head of invoice

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_of=22.12.2015&amount=10&id_payment_method=1&id_invoice_sent=1" \
	"http://test.cebelca.biz/API?_r=invoice-sent-p&_m=insert-into"
````

### Mark invoice paid (option 2)

If you just want to mark invoice paid and don't want to deal with amounts on your side you can use mark-paid method.

arguments are the same as above.

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_of=22.12.2015&id_invoice_sent=1&id_payment_method=1&note=no note&&id_invoice_sent_ext=0" \
"https://www.cebelca.biz/API?_r=invoice-sent-p&_m=mark-paid"
````

### Issue and Fiscalize the invoice

In slovenia you need to fiscalize (send to Tax office) all "cash" invoices in realtime. This API call does this.

"Cash" invoices are all invoices except invoices paid by direct transaction to your bank account (wire transfer) or PayPal (because PayPal is also considered your bank account). All other like payment by cash, credit card, by post are considered "cash" and must be fiscalized. Non "cash" payments can also be fiscalized, but all "cash" payments **MUST** be fiscalized.

arguments:

* **id** - id of the invoice
* **id_location** - fiscal invoice needs predefined location (more about that below). Location must also be sent to Tax Office - registered with them.
* **fiscalize** - you can have optional fiscalisation where you only fiscalize "cash" invoices. If you aren't in fiscal system at all you don't need to define location and you don't use this call at all. Also invoice numbering is different in that case. More about it later. Can be 1 or 0.
* **op-tax-id** - operators tax id. Personal tax ID of the person issuing an invoice (gets sent to Tax office)
* **op-name** - operators handle/nickname (can be name), is printed on invoice
* **test_mode** - fiscalizes to TEST Tax Office (FURS) server. Before you do this you must register your *location* at TEST FURS server too. More about it below. Can be 1 or 0.

````
curl -v -k \
	-u $TOKEN:x \
	-d "id=$ARG&id_location=7&fiscalize=1&op-tax-id=12345678&op-name=PRODAJALEC1&test_mode=1" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=finalize-invoice"
````

returns the status and EOR code:
````
[[{"docnum":"P1-B1-42","eor":"443d18e9-0f0a-48a6-a27d-7fcea373ef88"}]]
````

### Issue an Invoice outside of fiscalisation system

If you don't have any "cash" invoices you can issue them outside the fiscal system. In this case they get the regular numbering, like 18-0001. You don't need to deal with location, operator, etc.

* **id** - id of the invoice head
* **title** - leave empty and app will define it by itself, or define it here
* **doctype** - document type
  * 0 - invoice
  * 2 - credit note
  * 3 - advance payment invoice

````
curl -v -k \
	-u $TOKEN:x \
	-d "id=1&title=&doctype=0" \
"https://www.cebelca.biz/API?_r=invoice-sent&_m=finalize-invoice-2015"
````

returns
````
[[{"new_title":"18-0005"}]]
````



### Get the fiscal info

If you want to store the fiscal information of the invoice (ZOI, QR and EOR codes, etc)  use this call.

````
curl -v -k \
	-u $TOKEN:x \
	-d "id=$ARG" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=get-fiscal-info"
````
returns
````
[[{"id":80,"tax_id":"10217177","operator_tax_id":"12345678","invoice_amount":1440.0,"location_id":"P1","register_id":"B1","zoi_code":"ad3d87a26aab4a6d5a81c8cfae4b2bac","zoi_code_dec":"230275924372432379612582134529131228076","bar_code":"230275924372432379612582134529131228076102171771512240025088","eor_code":"443d18e9-0f0a-48a6-a27d-7fcea373ef88","date_time":"2015-12-24T00:25:08","operator_name":"PRODAJALEC1"}]]
````

### Get the invoice PDF

````
curl -v -k \
	-u $TOKEN:x -J -O \
	"http://test.cebelca.biz/API-pdf?id=$ARG&format=PDF&doctitle=Ra%C4%8Dun%20%C5%A1t.&lang=si&disposition=inline&res=invoice-sent&preview=0"
````

returns binary PDF data.


## More about locations

Before you can fiscalize invoices you need to register location with Tax Office (FURS). If you want to TEST fiscalize invoices you need to register location to TEST FURS server too (test_mode=1 in both cases).

### Add a location via API

You can do this in Web interface too. This is the way to do it via API. This way you also get and ID of location automatically.

arguments
* **type** - type of location
  * A - movable object (car, taxi, van, vehicle)
  * B - location on fixed address
  * C - electronic device (movable location which is where electronic device with program is)
* **location_id** - internal id of location (you determine it, must be unique in your company)
* **register_id** - internal id of register (you determine it, must be unique in this location)

````
curl -v -k \
        -u $TOKEN:x \
        -d "type=C&location_id=TEST1&register_id=B1" \
"https://www.cebelca.biz/API?_r=sales-location&_m=insert-into"
````
returns ID of added location:
````
[[{"id":1}]] 
````

### Register location with Tax office (FURS) or TEST FURS

arguments
* **id** - ID of location from previous call
* **test_mode** - register with TEST or real FURS server (1 or 0)

````
curl -v -k \
        -u $TOKEN:x \
        -d "id=1&test_mode=1" \
"https://www.cebelca.biz/API?_r=sales-location&_m=register-at-furs"
````


