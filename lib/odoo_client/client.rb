require "xmlrpc/client"

module Odoo
	class Client

		VERSION = "0.1.0"

		class AuthenticationError < StandardError
		end

		##
		# Initialize a new Odoo client
		# @param url [String] The URL of the Odoo server
		# @param database [String] The name of the database to connect to
		# @param username [String] The username to use for authentication
		# @param password [String] The password to use for authentication
		def initialize(url, database, username, password, options={})
			@url = url
			@common = XMLRPC::Client.new2("#{@url}/xmlrpc/2/common")

			@common.instance_variable_get(:@http).verify_mode = OpenSSL::SSL::VERIFY_NONE if options[:skip_tls]

			@db = database
			@password = password
			
			@common.call('version')
			@uid = @common.call('authenticate', @db, username, @password, {})

			raise AuthenticationError.new if @uid == false
		end

		##
		# Get the Odoo instance version
		# @return [String] The version of the Odoo instance
		def version
			@common.call('version')["server_version"]
		end

		##
		# Get logged user id
		# @return [Integer] The user id
		def me
			@uid
		end

		def count(model_name, filters=[])
			models.execute_kw(@db, @uid, @password, model_name, 'search_count', [filters], {})
		end	

		def list(model_name, filters=[])
			models.execute_kw(@db, @uid, @password, model_name, 'search', [filters], {})
		end

		def read(model_name, filters=[], select_fields=[], offset=nil, limit=nil)
			optional_params = {fields: select_fields}
			optional_params[:offset] = offset unless offset.nil?
			optional_params[:limit] = limit unless limit.nil?
			models.execute_kw(@db, @uid, @password, model_name, 'read', [filters], optional_params)
		end

		def create(model_name, params)
			models.execute_kw(@db, @uid, @password, model_name, 'create', [params])
		end

		def update(model_name, id, params)
			update_records(model_name, [id], params)
		end

		def update(model_name, record_ids, params)
			models.execute_kw(@db, @uid, @password, model_name, 'write', [record_ids, params])
		end

		def delete(model_name, params)
			models.execute_kw(@db, @uid, @password, model_name, 'unlink', [params])
		end

		def model_attributes(model_name, info=['string', 'help', 'type'])
			models.execute_kw(@db, @uid, @password, model_name, 'fields_get', [], {'attributes': info})
		end

		def find(model_name, id, select_fields=[])
			result = read_records(model_name, [["id", "=", id]], select_fields)
			result[0] unless result.empty?
		end	

		private

		def models
			@models ||= XMLRPC::Client.new2("#{@url}/xmlrpc/2/object").proxy
		end
	end	
end
