- [Making an invoice with Cebelca API](#making-an-invoice-with-cebelca-api)
  - [Set your API token](#set-your-api-token)
  - [Insert the customer](#insert-the-customer)
  - [Creating invoice](#creating-invoice)
    - [Add the invoice head](#add-the-invoice-head)
    - [Add the invoice head - smart](#add-the-invoice-head---smart)
    - [Add the invoice lines](#add-the-invoice-lines)
    - [Add payment to invoice - option 1](#add-payment-to-invoice---option-1)
    - [Mark invoice paid - option 2](#mark-invoice-paid---option-2)
  - [Finalizing the invoice](#finalizing-the-invoice)
    - [Issue and Fiscalize the invoice](#issue-and-fiscalize-the-invoice)
    - [Issue a regular invoice - noncash](#issue-a-regular-invoice---noncash)
    - [Get the fiscal info](#get-the-fiscal-info)
  - [Get the invoice PDF](#get-the-invoice-pdf)
  - [Using external ID](#using-external-id)
  - [More about location](#more-about-locations)
    - [Add a location via API](#add-a-location-via-api)
    - [Register location with Tax office](#register-location-with-tax-office)
- [Proforma invoice](#proforma-invoice)
  - [Creating proforma](#creating-proforma)
    - [Add the proforma head](#add-the-proforma-head)
    - [Add the proforma invoice lines](#add-the-proforma-invoice-lines)
  - [Get the proforma PDF](#get-the-proforma-pdf)
  - [From proforma to invoice](#from-proforma-to-invoice)

# Making an invoice with Cebelca API

The goal of this document is to show the API calls needed to create an invoice, fiscalize it (or not), get PDF of it and mark it paid. Some actions can be performed via different calls, depending what is best in your situation. 

You can read general API guidelines here: [General API guidelines](https://github.com/InvoiceFox/Workonomic-API-bash/blob/master/API-docs.md)

Examples use curl, which is available on all platforms and you can use to test API calls and see the results directly. 

Please remember that this is not all Cebelca API provides. ANYTHING (and more) you can do by hand in our web-application, can be done via API. We are preparing API Explorer and better documentation. This is the very first version.

Contact us if you have any questions: podpora AT cebelca DOT biz.


## Set your API token

Get the api token at *Nastavitve > Nastavitve dostopa* (bottom of the page). Set it as environmental variable in your shell.

    TOKEN=`cat .token`


## Insert the customer

Assure does just what it says. If the partner is already in the database it returns it's ID. If it's not it adds it and 
returns it's ID.

arguments:

 * **name** - company or person's name
 * **street** - self explanatory
 * **postal** - postal code / zip code
 * **city** - self explanatory
 * **country** - self explanatory

There are more data fields possible. See the webapp for field names.

````
curl -v -k \
	-u $TOKEN:x \
	-d "name=My Company&street=Downing street&postal=E1w201&city=London" \
	"https://www.cebelca.biz/API?_r=partner&_m=assure"
````
returns the ID of the partner: 
````
['ok',[{'id':123}]]

PARID=123
````

## Creating invoice

#### Add the Invoice head

Invoice consists of invoice head and multiple invoice body lines. First you add the Invoice head and get the ID of added invoice. API offers multiple ways of adding an invoice, some more suitable for specific situatuions. This is a basic one:

arguments

* **date_sent** - date when invoice was issued, formatted in dd.mm.yyyy.
* **date_to_pay** - date to which invoice should be payed. If invoice is already paid when issued, you can show that too.
* **date_served** - date when service or item was delivered. Required in Slovenia. Could also be two dates.
* **id_partner** - ID of the partner, gotten from previous call.

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=$ARG" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=insert-into"
````
returns ID of the invoice:
````
>> ['ok',[{'id':1}]] 
````

### Add the invoice head - smart

This option helps API users to fill in some information automatically, that would otherwise require more API calls or clined side info.

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

### Add the invoice lines 

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
	"http://www.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````


### Add payment to invoice - option 1

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
	"http://www.cebelca.biz/API?_r=invoice-sent-p&_m=insert-into"
````

### Mark invoice paid - option 2

If you just want to mark invoice paid and don't want to deal with amounts on your side you can use mark-paid method.

arguments are the same as above.

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_of=22.12.2015&id_invoice_sent=1&id_payment_method=1&note=no note&&id_invoice_sent_ext=0" \
"https://www.cebelca.biz/API?_r=invoice-sent-p&_m=mark-paid"
````

This method for example 

## Finalizing the invoice

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

**WARNING**: Because FURS changed it's rules, that must be implemented by all applications before 30.6.2019 parameter **fiscalize** is deprecated. Currently it's still there but on 20.04.2019 API call will return an error if fiscalize in set to 0. Invoices that are fiscalized, by the new rule, must strictly follow eachother. There can't be any gaps between them. So non-fiscalized invoices must be numbered in a differeny numbering scheme. If you have optional fiscalisation instead of fiscalize=0 you should now call method describer in the next chapter: **finalize-invoice-2015** . 

Web application already implemented the change in february. You can read more about this in our blog:
https://cebelca-biz.blogspot.com/2019/01/sprememba-pri-opcijskem-potrjevanju.html

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

### Issue a regular invoice - noncash

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

## Get the invoice PDF

````
curl -v -k \
	-u $TOKEN:x -J -O \
	"http://test.cebelca.biz/API-pdf?id=$ARG&format=PDF&doctitle=Ra%C4%8Dun%20%C5%A1t.&lang=si&disposition=inline&res=invoice-sent&preview=0"
````

returns binary PDF data.

## Using external ID

During the steps shown above you need to remember (or store) the invoice ID. You get that ID when you create the invoice head. But there is another option. When 
you create invoice head you can define your external ID. This is ID of the order (or something similat) that you already have in your system. Then when you make calls to ....:::::....
you just provide this external ID that you already have on your side or in your system.

When you create invoice head using insert-smart-2 use the **id_document_ext** argument.

````
EXTERN_ID=1234

curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=$ARG&id_currency=2&conv_rate=0&id_document_ext=$EXTERN_ID" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=insert-smart-2"
````

To add the line items (services) to the invoice you use the normal invoice ID, that you receive after creating a invoice head above. Because you do this inside same routin
you have the ID right there so this is not problematic.

You can then (later) **fiscalize cash** invoices by sending the same external ID as **id_invoice_sent_ext** argument:

````
curl -v -k \
	-u $TOKEN:x \
	-d "id=0&id_location=7&fiscalize=1&op-tax-id=12345678&op-name=PRODAJALEC1&test_mode=1&id_invoice_sent_ext=$EXTERN_ID" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=finalize-invoice"
````

For **non-cash** invoices you can finalize them using **id_invoice_sent_ext** also:

````
curl -v -k \
	-u $TOKEN:x \
	-d "id=1&title=&doctype=0" \
"https://www.cebelca.biz/API?_r=invoice-sent&_m=finalize-noncash-invoice&id_invoice_sent_ext=$EXTERN_ID"
````

Mark them **paid** using external ID:

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_of=22.12.2015&id_invoice_sent=0&id_payment_method=1&note=no note&&id_invoice_sent_ext=$EXTERN_ID" \
"https://www.cebelca.biz/API?_r=invoice-sent-p&_m=mark-paid"
````

# More about locations

Before you can fiscalize invoices you need to register location with Tax Office (FURS). If you want to TEST fiscalize invoices you need to register location to TEST FURS server too (test_mode=1 in both cases).

## Add a location via API

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

## Register location with Tax office

arguments
* **id** - ID of location from previous call
* **test_mode** - register with TEST or real FURS server (1 or 0)

````
curl -v -k \
        -u $TOKEN:x \
        -d "id=1&test_mode=1" \
"https://www.cebelca.biz/API?_r=sales-location&_m=register-at-furs"
````

# Proforma invoice

## Creating proforma

### Add the proforma head

Proforma invoice consists of document head and multiple proforma body lines. First you add the Proforma head and get the ID of added proforma:

arguments

* **date_sent** - date when proforma was issued, formatted in dd.mm.yyyy.
* **days_valid** - integer number of days that proforma is valid
* **id_partner** - ID of the partner, gotten from call: [Insert your customer](#insert-your-customer-partner)
* **taxnum** - can be 0 or the taxnumber of the customer. If id_partner (customer id) is zero "0", then it uses taxnum to find a customer in your list this way

````
curl -v -k
	-u $TOKEN:x
	-d "date_sent=22.12.2015&days_valid=30&id_partner=$PARID&taxnum=0"
	"https://www.cebelca.biz/API?_r=preinvoice&_m=insert-smart"
````
returns ID of the proforma invoice:
````
>> ['ok',[{'id':202}]]

PROID=202
````

### Add the proforma invoice lines 

You then add one or more proforma body lines. The contents of the proforma.

* **title** - name or description of the service / item you sold (unlimited text)
* **qty** - quantity of items sold (decimal number)
* **mu** - measuring unit (like hour, piece, kg)
* **price** - price per unit (decimal)
* **vat** - Value Added Tax (or tax in general) in percentage, decimal. For Slovenia it's 0, 9.5 or 22 currently.
* **discount** - discount in percentage, decimal.
* **id_preinvoice** - ID of invoice head, gotten from previous call

````
curl -v -k
	-u $TOKEN:x
	-d "title=programming&qty=10&mu=hour&price=50&vat=22&discount=0&id_preinvoice=$PROID"
	"https://www.cebelca.biz/API?_r=preinvoice-b&_m=insert-into"
````

## Get the proforma PDF

````
curl -v -k \
	-u $TOKEN:x -J -O \
	"https://www.cebelca.biz/API-pdf?id=$PROID&format=PDF&doctitle=Predra%C4%8Dun%20%C5%A1t.&lang=si&disposition=inline&res=preinvoice&preview=0"
````

returns binary PDF data and save it to file.


## From proforma to invoice

If you have a proforma or estimate already made, you can turn in into an invoice in one API call.

````
PROFORMA_ID=42

curl -v -k
	-u $TOKEN:x
	-d "id=$PROFORMA_ID&date_sent=03.03.2024&date_to_pay=23.03.2024&date_served=03.03.2024"
	"https://www.cebelca.biz/API?_r=preinvoice&_m=make-invoice-from"
````


## Creating Advance and Final Invoice and more

#### Invoice doctypes

When you are creating invoice head you can set the doctype to define invoice as the regular invoice, advance invoice, credit note (dobropis), or cancelation (storno). Other data is the same.

* 0 - regular invoice
* 1 - advance invoice
* 2 - credit note
* 3 - cancelation
* 10 - final invoice

#### Example of creating a final invoice

Invoice consists of invoice head and multiple invoice body lines. First you add the Invoice head and get the ID of added invoice. API offers multiple ways of adding an invoice, some more suitable for specific situatuions. This is a basic one:

arguments

* **date_sent** - date when invoice was issued, formatted in dd.mm.yyyy.
* **date_to_pay** - date to which invoice should be payed. If invoice is already paid when issued, you can show that too.
* **date_served** - date when service or item was delivered. Required in Slovenia. Could also be two dates.
* **id_partner** - ID of the partner, gotten from previous call.
* **doctype** - 10

````
curl -v -k \
	-u $TOKEN:x \
	-d "date_sent=22.12.2015&date_to_pay=30.12.2015&date_served=22.12.2015&id_partner=$ARG&doctype=10" \
	"https://www.cebelca.biz/API?_r=invoice-sent&_m=insert-into"
````
returns ID of the invoice:
````
>> ['ok',[{'id':100}]] 
````

### Add the final invoice lines 

Final invoice has to list all the services or items you are billing and below them, at least two additional somewhat special lines. 

First one should have value zero (0) and should be a placeholder where PDF will show the Sum and VAT of all lines above it.

Next one should represent an already paid and billed advance invoice and should be negative, reducing the total amount. Final invoice can also
be already paid in full, meaning theat the total amount is zero. It must always have the Sum line we mentioned above.

You add ordinary items or services like in a regular invoice. Look above for specification.

````
curl -v -k \
	-u $TOKEN:x \
	-d "title=programming&qty=10&mu=hour&price=50&vat=22&discount=0&id_invoice_sent=100" \
	"https://www.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````

Then you add the Sum line, qty price and vat are zero. This is achieved by using a special character "%" as the first character in title.
This is the same as using "Vnesi posebno vrstico > Seštevek in DDV" in the Cebelca UI.

````
curl -v -k \
	-u $TOKEN:x \
	-d "title=%&qty=0&mu=&price=50&vat=0&discount=0&id_invoice_sent=100" \
	"https://www.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````

And lasty you add one or more advance invoices as negative values to the invoice. These also have a special first character which causes the PDF
to show just Title and Value on the right (hides qty, price, vat, discount). The special character is "*".

It is again the same as using "Vnesi posebno vrstico > Naziv in znesek z DDV". The title now includes a text and Advance number. The price is net value
of the advance. And VAT is the VAT of the advance. If Advance had more than one VAT level you must add one line per level here.

You can add multiple advances in this manner.

````
curl -v -k \
	-u $TOKEN:x \
	-d "title=* Predplačilo po avansu A25-0001&qty=-1&mu=&price=160&vat=0&discount=0&id_invoice_sent=100" \
	"https://www.cebelca.biz/API?_r=invoice-sent-b&_m=insert-into"
````

#### Advance and final invoice from proforma
