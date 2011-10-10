REBOL []

[
   inv-create [
   	      resource invoice-sent
	      method insert-into
   	      descr "Creates an invoice head."
	      options [
	      	      n [ "Docnum" r v title   def "11-0001" ]
		      c [ "Contact ID" r v id_partner ]
		      d [ "Date sent" r v date_sent  ]
		      p [ "Payment deadline" r v date_to_pay ]
		      s [ "Payment deadline" r v date_served ]
		      f [ "Response format: json, csv, html, xml" v _f  def "json" ]
	      ]
   ]   
   inv-list [
   	      resource invoice-sent
	      method select-all
   	      descr "Lists all invoices."
	      options [
		      f [ "Response format: json, csv, html, xml" v _f  def "json" ]
	      ]
   ]
   contact-list [
   	      resource partner
	      method select-all
   	      descr "Lists all invoices."
	      options [
		      f [ "Response format: json, csv, html, xml" v _f  def "json" ]
	      ]
   ]
   items-list [
   	      resource invoice-sent-o
	      method select-all
   	      descr "Lists all invoices."
	      options [
		      f [ "Response format: json, csv, html, xml" v _f  def "json" ]
	      ]
   ]
   inv-next-doc [
   	      resource invoice-sent
	      method select-next-title
   	      descr "Get the document number of next invoice."
	      options [
		      f [ "Response format: json, csv, html, xml" v _f  def "json" ]
	      ]
   ]
]