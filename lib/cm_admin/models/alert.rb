module CmAdmin
  module Models
    class Alert
      attr_accessor :header, :body, :type, :partial, :display_if, :html_attrs

      def initialize(attributes = {})
        set_default_values
        attributes.each do |key, value|
          send("#{key}=", value)
        end
      end

      def set_default_values
        self.header = nil
        self.body = nil
        self.type = :info
        self.partial = nil
        self.display_if = ->(_args) { true }
        self.html_attrs = {}
      end
    end
  end
end
