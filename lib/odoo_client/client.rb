require "xmlrpc/client"
require_relative "filter"

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
      models.execute_kw(@db, @uid, @password, model_name, 'search_count', filters, {})
    end

    def read(model_name, filters = [], optional_params = {})
      filters = [filters] unless filters.is_a?(Array)
      models.execute_kw(@db, @uid, @password, model_name, 'read', filters, optional_params)
    end

    def create(model_name, params)
      models.execute_kw(@db, @uid, @password, model_name, 'create', [params])
    end

    def update(model_name, record_ids, params, optional_params = {})
      optional_params = optional_params.deep_stringify_keys
      optional_params['context'] = @default_context.merge(optional_params['context'] || {})
      models.execute_kw(@db, @uid, @password, model_name, 'write', [record_ids, params], optional_params)
    end

    def delete(model_name, record_ids)
      models.execute_kw(@db, @uid, @password, model_name, 'unlink', [record_ids])
    end

    def model_attributes(model_name, info = ['field_name', 'field_label', 'string', 'help', 'type'])
      models.execute_kw(@db, @uid, @password, model_name, 'fields_get', [], {'attributes': info})
    end

    def search(model_name, filters = [], optional_params = {})
      filters = convert_filters(filters)
      models.execute_kw(@db, @uid, @password, model_name, 'search', [filters], optional_params.deep_stringify_keys)
    end

    def search_read(model_name, filters = [], optional_params = {})
      filters = convert_filters(filters)
      models.execute_kw(@db, @uid, @password, model_name, 'search_read', [filters], optional_params.deep_stringify_keys)
    end

    def search_read_all(model_name, filters = [], optional_params: {}, page_size: 100)
      offset = 0
      loop do
        optional_params = optional_params.merge({offset: offset, limit: page_size})
        records = search_read(model_name, filters, optional_params)
        break if records.empty?

        result = yield records
        break if result == false || result.nil? || records.length < page_size

        offset += page_size
      end
    end

    def model_ids(model_names)
      operator = model_names.is_a?(Array) ? 'in' : '='
      search_read('ir.model', [['model', operator, model_names]], {fields: %w[id name]})
    end

    def group_ids(group_names)
      operator = group_names.is_a?(Array) ? 'in' : '='
      search_read('res.groups', [['name', operator, group_names]], {fields: %w[id name]})
    end

    def field_ids(model_name, field_names)
      operator = field_names.is_a?(Array) ? 'in' : '='
      search_read('ir.model.fields', [['name', operator, field_names], ['model', '=', model_name]], {fields: %w[id name]})
    end

    def model(model_class)
      model_class = if model_class.is_a?(String)
                      model_class.constantize
                    elsif model_class.is_a?(Class)
                      model_class
                    end

      model_class.new(self)
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
