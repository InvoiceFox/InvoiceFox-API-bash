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

## Add items

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
['ok',[{'id':123}]]
````
