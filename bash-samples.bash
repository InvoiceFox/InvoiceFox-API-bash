#
## InvoiceFox API curl examples ~~ !!WORK IN PROGRESS!!
#

# add invoice head and get the id

$ curl -v -k 
	-u cgf0a3v15ek3dlb2swg450pcd9rohz89eva:x \
	-d "title=11-0002&date_sent=2011-01-02&date_to_pay=2011-04-12&id_partner=10" \
	"https://www.invoicefox.com/API?_r=invoice-sent&_m=insert-into"

>>	['ok',[{'id':1}]]

# add invoice body and get the id

$ curl -v -k \
	-u cgf0a3v15ek3dlb2swg450pcd9rohz89eva:x \
	-d "title=programming service&qty=10&mu=piece&price=120&vat=20&discount=0&id_invoice_sent=1" \
	"https://www.invoicefox.com/API?_r=invoice-sent-b&_m=insert-into"

>> ['ok',[{'id':1}]]

# assure partner (add if it doesn't exits and get the id, otherwise just get the id)

$ curl -v -k \
	-u cgf0a3v15ek3dlb2swg450pcd9rohz89eva:x \
	-d "name=My Company&street=Downing street&postal=E1w201&city=London" \
	"https://www.invoicefox.com/API?_r=partner&_m=assure"

>> ['ok',[{'id':1}]]

# download the PDF of the invoice

$ curl -v -k \
	-u cgf0a3v15ek3dlb2swg450pcd9rohz89eva:x \
	"https://www.invoicefox.com/API-pdf?id=20&res=invoice-sent"

>> binary-pdf-data

#### TODO -- make it work (create invoice has problems with date format, add aditional methods)
