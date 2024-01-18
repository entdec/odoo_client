module Odoo
  class Response

    attr_reader :body, :client, :optional_params

    def initialize(client, body, optional_params = {})
      @client = client
      @body = HashWithIndifferentAccess.new(body)
      @optional_params = optional_params
      @cached_models = {}
    end

    def model_name
      body["_model"]
    end

    def get(field_name, optional_params = {})
      return nil if field_name.blank?

      field = body["data"][field_name]
      field ||= @cached_models[field_name]
      unless field.present? ||
        body["data"].key?(field_name) || @cached_models.key?(field_name)
        field = if body["data"]["#{field_name}_id"].present?
                  model_name = get_model_name("#{field_name}_id")

                  if model_name.present?
                    data = @client.search_read(model_name, [["id", "=", body["data"]["#{field_name}_id"][0]]], optional_params)&.first
                    @cached_models[field_name] = Odoo::Response.new(@client, {'data': data, '_model': model_name}, optional_params)
                  end
                elsif body["data"]["#{field_name}_ids"].present? && body["data"]["#{field_name}_ids"].is_a?(Array)
                  model_name = get_model_name("#{field_name}_ids")
                  if model_name.present?
                    data = @client.search_read(model_name, [["id", "in", body["data"]["#{field_name}_ids"]]], optional_params)
                    @cached_models[field_name] = Odoo::Response.new(@client, {'data': data, '_model': model_name}, optional_params)
                  end
                end
      end
      field
    end

    def fields
      return body["_field_info"] if body["_field_info"].present?
      return nil if @client.blank? || model_name.blank?
      body["_field_info"] = @client.call(model_name, 'fields_get', [], {attributes: %w[field_name type required relation]})
    end

    def get_model_name(field_name)
      return nil if field_name.blank?
      fields.dig(field_name, "relation") || fields.dig(field_name, "model")
    end

    def [](key)
      get(key)
    end

    def []=(key, value)
      key = key&.to_i if body["data"].is_a?(Array)
      body["data"][key] = value
    end

    def dig(*args)
      current = self
      args.each { |arg|
        current = self[arg]
        return nil if current.nil?
      }
      current
    end

    def data
      body["data"]
    end

    def method_missing(method_name, *args, &block)
      if data
        data.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      data&.respond_to?(method_name, include_private) || super
    end

  end
end
