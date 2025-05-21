- [Using the API](#using-the-api)
- [Create outgoing inventory document from invoice](#create-outgoing-inventory-document-from-invoice)
- [Add items](#add-items)

# Using the API

You can read general API guidelines here: [General API guidelines](https://github.com/InvoiceFox/Workonomic-API-bash/blob/master/API-docs.md)

Examples use curl, which is available on all platforms and you can use to test API calls and see the results directly. 

Contact us if you have any questions: podpora AT cebelca DOT biz.

Get the api token at *Nastavitve > Nastavitve dostopa* (bottom of the page). Set it as environmental variable in your shell.

    TOKEN=`cat .token`

## List all items

To list all items available in the inventory management account use:

````
curl -k \
	-u $TOKEN:x \
	-d "page=0" \
	"https://www.cebelca.biz/API?_r=item&_m=select-all"
````
returns items:

````
[[{"id":1002,"code":" KX12-2332","descr":"Darilni paket","price":21.923442,"unit":"kos","tax":22.0,"ean":null,"ean_code":"124378211","lead_time":0,"min_order":1.0,"notes":"","extern_code":"","dont_inventory":0,"sales_item":0,"tags":"","max_disct":"","madein":"","weight":"","tariff_num":"","pack_paper":0.0,"pack_plastic":0.0,"pack_wood":0.0,"pack_metals":0.0,"pack_glass":0.0,"pack_other":0.0,"location":"","disabled":0},...]
````

## Add items

````
curl -k \
	-u $TOKEN:x \
	-d "code=T303&descr=opis izdelka&price=81.9672&unit=kos&tax=22&sales_item=0&exter_code=TEX1&weight=0.75" \
	"https://www.cebelca.biz/API?_r=item&_m=insert-into"
````
returns id of the new item:
````
[[{"id":1268}]]
````

All possible fields are:

* **code: required** - Item SKU or short name
* **descr: optional ""** - Item description or name
* **price: required and decimal** - Net price, price without tax, preferably on at least 4 decimals if you want Gross price to come exact
* **unit: optional ""** - unit of quantity: piece, kg, litre
* **tax: required** - tax level: 22, 9.5, ...
* ean_code: optional "" - barcode
* lead_time: optional 0 and integer
* min_order: optional 0 and integer
* notes: optional ""
* extern_code: optional ""
* dont_inventory: optional 0 - if 1 inventory for this item won't be calculated and checked 
* **sales_item: optional 0** - 0 for sales_item (reverse)
* tags: optional ""
* max_disct: optional "" - maximal discount
* madein: optional ""
* weight: optional "" - in kg
* tariff_num: optional ""
* pack_paper: optional "0" and decimal - packaging properties, reports can be generated from this
* pack_plastic: optional "0" and decimal
* pack_wood: optional "0" and decimal
* pack_metals: optional "0" and decimal
* pack_glass: optional "0" and decimal
* pack_other: optional "0" and decimal
* location: optional "" - location in the inventory
* disabled: optional "0" and integer - if disabled it won't show in any of the lists

## Create outgoing inventory document from invoice

* **date_created** - date when items go out of the warehouse dd.mm.yyyy.
* **id_contact_from** - ID of the warehouse where items go from.
* **id_contact_to** - ID of the customer that items go to , set -1 to leave it as it's on the invoice
  
````
INVOICE_ID=101
WAREHOUSE_ID=6
CUSTOMER_ID=-1

curl -v -k \
	-u $TOKEN:x \
	-d "id_invoice_sent=$INVOICE_ID&date_created=30.03.2024&doctype=1&docsubtype=0&id_contact_from=$WAREHOUSE_ID&id_contact_to=$CUSTOMER_ID" \
	"https://www.cebelca.biz/API?_r=transfer&_m=make-inventory-doc-smart"
````

returns the ID of the partner: 
````
[[{"ok":"DONE","docnum":"24-0005"}]]
````

## Creating a document

Documents change inventory in a specific warehouse, incoming documents add to inventory and outgoing reduce the inventory for the items. Internal documents move inventory from
one (internal) warehouse to another.

Documents have types:

* Incoming: 0
* Outgoing: 1
* Internal: 2
* Workwarrant: 3
* No-effect: 4

Documents have sub-types:

* Incoming:
  * Start: 1
  * Purchase: 2
  * Return: 3
  * Check more: 4
* Outgoing:
  * Sales: 101
  * Cancel: 102
  * Promo: 103
  * Check less: 104
  * Return you: 105
* No-effect
  * Order sent: 201
  * Order recv: 202

#### Add transfer head

Transfer has a head, where you set date, the warehouse or a partner where items come from and go to. Doctype determines if items are added to the inventory, removed from inventory or
moved between warehouses.


````
curl -v -k \
	-u $TOKEN:x \
	-d "date_created=22.06.2025&id_contact_from=101&id_contact_to=202&docnum=25-001&doctype=0&subdoctype=1" \
	"https://www.cebelca.biz/API?_r=transfer&_m=insert-select"
````
returns ID of the invoice:
````
>> ['ok',[{'id':100, ...}]] 
````

### Add transfer lines 

Each transfer document has multiple items on it. One per line. Data for the line is:

* **id_item** ID of an item (integer)
* **descr** description of an item (text)
* **qty** qty of item on the document (number)
* **mu** measuring unit of quantity
* **price** price of item on the document (purchase price in case of incoming document)
* **id_transfer** ID of the document head
* **price2** secondary price - predicted sales price in case of incoming document - required by gov, other types of documents don't need this price 

````
curl -v -k \
	-u $TOKEN:x \
	-d "id_item=42&descr=item description&qty=10&mu=kos&price=5&vat=22&discount=0&price2=12&id_transfer=100" \
	"https://www.cebelca.biz/API?_r=transfer-b&_m=insert-into"
````
