require "xmlrpc/client"

module Odoo
  class Client

    class AuthenticationError < StandardError; end

    def initialize(url, database, username, password, options = {})
      @url = url
      @db = database
      @password = password
      @default_context = options[:default_context]
      @common = XMLRPC::Client.new2("#{@url}/xmlrpc/2/common")
      @common.instance_variable_get(:@http).verify_mode = OpenSSL::SSL::VERIFY_NONE if options[:skip_tls]
      authenticate(@username = username)
    end

    def version
      @common.call('version')["server_version"]
    end

    def me
      @uid
    end

    def username
      @username
    end

    def password
      @password
    end

    def count(model_name, filters = [])
      filters = convert_filters(filters)
      result = models.execute_kw(@db, @uid, @password, model_name, 'search_count', filters, {})
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def read(model_name, filters = [], optional_params = {})
      filters = [filters] unless filters.is_a?(Array)
      optional_params = optional_params.deep_stringify_keys
      result = models.execute_kw(@db, @uid, @password, model_name, 'read', filters, optional_params)
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def create(model_name, params)
      models.execute_kw(@db, @uid, @password, model_name, 'create', [params])
    end

    def update(model_name, record_ids, params, optional_params = {})
      optional_params = optional_params.deep_stringify_keys
      optional_params['context'] = @default_context.merge(optional_params['context'] || {})
      result = models.execute_kw(@db, @uid, @password, model_name, 'write', [record_ids, params], optional_params)
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def delete(model_name, record_ids)
      result = models.execute_kw(@db, @uid, @password, model_name, 'unlink', [record_ids])
      Response.new(self, {"_model": model_name, "data": result})
    end

    def model_attributes(model_name, info = ['field_name', 'field_label', 'string', 'help', 'type'])
      optional_params = {attributes: info}
      result = models.execute_kw(@db, @uid, @password, model_name, 'fields_get', [], optional_params)
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def search(model_name, filters = [], optional_params = {})
      filters = convert_filters(filters)
      optional_params = optional_params.deep_stringify_keys
      result = models.execute_kw(@db, @uid, @password, model_name, 'search', [filters], optional_params)
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def search_read(model_name, filters = [], optional_params = {})
      filters = convert_filters(filters)
      optional_params = optional_params.deep_stringify_keys
      result = models.execute_kw(@db, @uid, @password, model_name, 'search_read', [filters], optional_params)
      Response.new(self, {"_model": model_name, "data": result}, optional_params)
    end

    def search_read_all(model_name, filters = [], optional_params: {}, page_size: 100)
      offset = 0
      loop do
        optional_params = optional_params.merge({offset: offset, limit: page_size})
        records = search_read(model_name, filters, optional_params)
        break if records.empty?

        yield Response.new(self, {"_model": model_name, "data": records}, optional_params)
        break if records.length < page_size

        offset += page_size
      end
    end

    def model_ids(model_names)
      operator = model_names.is_a?(Array) ? 'in' : '='
      optional_params = {fields: %w[id model]}
      search_read('ir.model', [['model', operator, model_names]], optional_params)
    end

    def group_ids(group_names)
      operator = group_names.is_a?(Array) ? 'in' : '='
      optional_params = {fields: %w[id name]}
      search_read('res.groups', [['name', operator, group_names]], optional_params)
    end

    def field_ids(model_name, field_names)
      operator = field_names.is_a?(Array) ? 'in' : '='
      search_read('ir.model.fields', [['name', operator, field_names], ['model', '=', model_name]], {fields: %w[id name]})
    end

    def call(model_name, method, *args)
      models.execute_kw(@db, @uid, @password, model_name, method, *args)
    end

    def authenticate(username)
      @uid = @common.call('authenticate', @db, username, @password, {})
      raise AuthenticationError.new if @uid == false
    end

    private

    def convert_filters(filters)
      filters = [filters] unless filters.is_a?(Array)
      filters
    end

    def models
      @models ||= XMLRPC::Client.new2("#{@url}/xmlrpc/2/object").proxy
    end
  end
end
