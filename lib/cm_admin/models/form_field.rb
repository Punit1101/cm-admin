require_relative 'utils/helpers'

module CmAdmin
  module Models
    class FormField
      include Utils::Helpers

      attr_accessor :field_name, :label, :header, :input_type, :collection, :disabled, :helper_method,
                    :placeholder, :display_if, :html_attrs, :target, :col_size, :ajax_url, :helper_text,
                    :image_preview, :can_create_new_entity

      VALID_INPUT_TYPES = %i[
        integer decimal string single_select multi_select date date_time text switch custom_single_select checkbox_group
        single_file_upload multi_file_upload hidden rich_text check_box radio_button custom_string custom_date
        radio_button_group
      ].freeze

      def initialize(field_name, _input_type, attributes = {})
        @field_name = field_name
        set_default_values
        attributes.each do |key, value|
          send("#{key}=", value)
        end
        set_default_placeholder
        self.display_if = ->(_arg) { true } if display_if.nil?
        raise ArgumentError, "Kindly select a valid input type like #{VALID_INPUT_TYPES.sort.to_sentence(last_word_connector: ', or ')} instead of #{input_type} for form field #{field_name}" unless VALID_INPUT_TYPES.include?(input_type.to_sym)
      end

      def set_default_values
        self.disabled = ->(_arg) { false } if display_if.nil?
        self.label = field_name.to_s.titleize
        self.input_type = :string
        self.html_attrs = {}
        self.target = {}
        self.col_size = nil
        self.image_preview = false
        self.can_create_new_entity = false
      end

      def set_default_placeholder
        return unless placeholder.nil?

        self.placeholder = case input_type&.to_sym
                           when :single_select, :multi_select, :date, :date_time
                             "Select #{humanized_field_value(field_name)}"
                           else
                             "Enter #{humanized_field_value(field_name)}"
                           end
      end
    end
  end
end
