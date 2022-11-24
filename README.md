## Odoo Client - Ruby Client for Odoo ERP

* Odoo API docs (latest version)
	* https://www.odoo.com/documentation/16.0/api_integration.html
* Odoo ORM docs (latest version)
	* https://www.odoo.com/documentation/16.0/reference/orm.html

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'odoo_client'
```

And then execute:

```sh
$ bundle install
```

## Usage

```ruby
client = Odoo::Client.new(url, database_name, username, password, options = {})

# get server version
result = client.version

# get logged user
result = client.me

# client.find allows ActiveRecord-like find of any model by id
# This example return a partner record with id=4
result = client.find('res.partner', 4)

# client.list returns an array of ids with given criteria
# This example returns all tag ids with the name attribute set to 'Web Lead'
result = client.list('crm.lead.tag', [['name', '=', 'Web Lead' ]] )

# client.read returns an array of full records with given criteria
# This example returns all sales teams records with the name not set to 'Direct Sales'
result = client.read('crm.team', [['name', '!=', 'Direct Sales' ]] )

# client.read with optional parameters (select_fields, offset, limit)
# This example returns only select fields for 50 leads modified since the beginning of the week
result = client.read('crm.lead', [['write_date', '>=', Time.now.beginning_of_week ]], ["user_id", "stage_id", "priority", "date_deadline", "date_closed"], 0, 50)

# client.delete removes all records with matching criteria 
# This example deletes all recgistrations attached to an event id
registrations = client.list("event.registration", [["event_id", "=", 6]])
client.delete("event.registration", registrations)

# client.count returns a count of records with given criteria
# This example counts event registrations for a given event id
result = client.count("event.registration", [["event_id", "=", 6]])

# count, delete, read, and list allow multiple filters seperated by commas
result = client.count("event.registration", [["event_id", "=", 6],["name", "!=", "Paul Vachon"]])

# client.create creates a new record
# This example creates a new leads
record_params = { "contact_name" => "Paul Vachon", 
				  "display_name" => "Customer : Paul Vachon",
					  	  "phone" => "0407602374",
					  	  "city" => "Antibes",
					  	  "email_from" => "paulvachon@jourrapide.com",
					  	  "user_id" => false,
					  	  "type" => "customer"}	
result = client.create('crm.lead', record_params)

# client.update update fields on a record for a given model
# This example updates the name and email of a customer record with id=5
result = client.update("res.partner", 5, {"name" => "Paul Vachon", "email" => "paulvachon@jourrapide.com"})

# client.update update fields for more than 1 record
result = client.update("crm.lead", [5,6,7], {"referred" => "Yelp"})

# client.model_attributes returns a hash of all fields for a given model
result = client.model_attributes("crm.lead")
```

## TODO:

* Retrofit specs to gem
* Include service objects to manage common tasks in Odoo (requires schema knowledge of different Odoo versions "crm.case.categ vs lead.tags")