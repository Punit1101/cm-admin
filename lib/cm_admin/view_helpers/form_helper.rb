require_relative 'form_field_helper'
require 'cgi'
require 'uri'

module CmAdmin
  module ViewHelpers
    module FormHelper
      include FormFieldHelper
      REJECTABLE = %w[id created_at updated_at]
      attr_accessor :is_drawer_form

      def generate_form(resource, cm_model, is_drawer_form: false)
        if resource.new_record?
          action = :new
          method = :post
        else
          action = :edit
          method = :patch
        end
        @is_drawer_form = is_drawer_form
        return form_with_all_fields(resource, method) if cm_model.available_fields[action].empty?

        form_with_mentioned_fields(resource, cm_model.available_fields[action], method)
      end

      def form_with_all_fields(resource, method)
        columns = resource.class.columns.dup
        table_name = resource.model_name.collection
        columns.reject! { |i| REJECTABLE.include?(i.name) }
        url = CmAdmin::Engine.mount_path + "/#{table_name}/#{resource.id}"
        set_form_for_fields(resource, columns, url, method)
      end

      def form_with_mentioned_fields(resource, entities, method)
        # columns = resource.class.columns.select { |i| available_fields.map(&:field_name).include?(i.name.to_sym) }
        table_name = resource.model_name.collection
        # columns.reject! { |i| REJECTABLE.include?(i.name) }
        url = CmAdmin::Engine.mount_path + "/#{table_name}/#{resource.id}"
        set_form_with_sections(resource, entities, url, method)
      end

      def split_form_into_section(resource, form_obj, entities)
        content_tag :div do
          entities.each do |entity|
            if entity.class == CmAdmin::Models::Row
              concat create_rows(resource, form_obj, entity)
            elsif entity.class == CmAdmin::Models::Section
              next unless entity.display_if.call(form_obj.object)

              concat(content_tag(:div, class: 'row', **entity.html_attrs) do
                concat create_sections(resource, form_obj, entity)
              end)
            end
          end
        end
      end

      def create_rows(resource, form_obj, row)
        content_tag :div, class: 'row', **row.html_attrs do
          row.sections.each do |section|
            next unless section.display_if.call(form_obj.object)

            concat create_sections(resource, form_obj, section)
          end
        end
      end

      def create_sections(resource, form_obj, section)
        content_tag :div, class: 'col form-container' do
          return render partial: section.partial, locals: { form_obj: } if section.partial

          concat content_tag(:p, section.section_name, class: 'form-title') unless section.parent_section.present?
          concat set_form_for_fields(resource, form_obj, section)
        end
      end

      def create_row_inside_section(resource, form_obj, rows)
        rows.each do |row|
          concat(content_tag(:div, class: 'row') do
            row.row_fields.each do |field|
              if field.is_a?(CmAdmin::Models::Section)
                concat set_nested_section_form_fields(resource, form_obj, Array(field))
              else
                concat set_form_field(resource, form_obj, field)
              end
            end
          end)
        end
        nil
      end

      def set_form_for_fields(resource, form_obj, section)
        content_tag(:div, class: "form-container__inner #{section.parent_section.present? ? 'nested_section' : ''} #{section.html_attrs[:class]}", **section.html_attrs.except(:class)) do
          concat content_tag(:h6, section.section_name, class: 'nested-form-title') if section.parent_section.present?
          concat create_row_inside_section(resource, form_obj, section.rows) if section.rows.present?
          concat set_form_fields(resource, form_obj, section.section_fields)
          concat set_nested_section_form_fields(resource, form_obj, section.nested_sections)
          concat set_nested_form_fields(form_obj, section)
        end
      end

      def set_form_fields(resource, form_obj, fields)
        fields.each do |field|
          concat(content_tag(:div, class: 'row') do
            concat set_form_field(resource, form_obj, field)
          end)
        end
        nil
      end

      def set_form_field(resource, form_obj, field)
        return unless field.display_if.call(form_obj.object)
        return create_alert(field, form_obj.object) if field.is_a?(CmAdmin::Models::Alert)

        is_required = is_field_presence_validated?(form_obj, field)

        content_tag(:div, class: field.col_size ? "col-#{field.col_size}" : 'col') do
          if field.input_type.eql?(:hidden)
            concat input_field_for_column(form_obj, field, is_required:)
          else
            concat(content_tag(:div, class: "form-field #{field.disabled ? 'disabled' : ''}") do
              concat set_form_label(field, form_obj, is_required)
              concat input_field_for_column(form_obj, field, is_required:)
              concat tag.small field.helper_text, class: 'form-text text-muted' if field.helper_text.present?
              concat tag.p resource.errors[field.field_name].first if resource.errors[field.field_name].present?
            end)
          end
        end
      end

      def set_form_label(field, form_obj, is_required)
        return unless field.label && %i[check_box switch].exclude?(field.input_type)

        content_tag(:div, class: 'd-flex') do
          concat form_obj.label field.label, field.label, class: "field-label #{is_required ? 'required-label' : ''}"
          concat set_drawer_form_button(field, form_obj)
        end
      end

      def set_drawer_form_button(field, form_obj)
        model_name = find_model_name(form_obj, field)
        ar_object = model_name.constantize.new if model_name.present?
        return unless field.input_type.to_s == 'single_select' && model_name.present? && has_valid_policy(ar_object, 'new')

        field_id = form_obj.field_id(field.field_name.to_sym)
        drawer_fetch_url = "#{CmAdmin::Engine.mount_path}/#{model_name.tableize}/fetch_drawer?from_field_id=#{field_id}"
        tag.div 'New Entity', class: 'drawer-btn', data: { behaviour: 'offcanvas', drawer_fetch_url: }
      end

      def set_nested_section_form_fields(resource, form_obj, nested_sections)
        return if nested_sections.blank?

        nested_sections.each do |nested_section|
          next unless nested_section.display_if.call(form_obj.object)

          concat create_sections(resource, form_obj, nested_section)
        end
        nil
      end

      def set_nested_form_fields(form_obj, section)
        content_tag(:div) do
          section.nested_table_fields.each do |nested_table_field|
            concat(render(partial: '/cm_admin/main/nested_table_form', locals: { f: form_obj, nested_table_field: }))
          end
        end
      end

      def set_form_with_sections(resource, entities, url, method)
        url_with_query_params = extract_query_params(url)

        form_for(resource, url: url_with_query_params || url, method:, html: { class: "cm_#{resource.class.name.downcase}_form" }, data: { is_drawer_form: @is_drawer_form }) do |form_obj|
          concat form_obj.text_field 'referrer', class: 'normal-input', hidden: true, value: params[:referrer], name: 'referrer' if params[:referrer]
          if params[:polymorphic_name].present?
            concat form_obj.text_field params[:polymorphic_name] + '_type', class: 'normal-input', hidden: true, value: params[:associated_class].classify
            concat form_obj.text_field params[:polymorphic_name] + '_id', class: 'normal-input', hidden: true, value: params[:associated_id]
          elsif params[:associated_class] && params[:associated_id]
            concat form_obj.text_field params[:associated_class] + '_id', class: 'normal-input', hidden: true, value: params[:associated_id]
          end

          concat split_form_into_section(resource, form_obj, entities)
          concat tag.br
          concat form_obj.submit 'Save', class: 'btn-cta', data: { behaviour: 'form_submit', form_class: "cm_#{form_obj.object.class.name.downcase}_form" }
          concat button_tag 'Discard', class: 'btn-secondary discard-form', data: { behaviour: 'discard_form' } unless @is_drawer_form
        end
      end

      def extract_query_params(url)
        query_params = {}
        return unless params[:polymorphic_name].present? || params[:associated_id].present? && params[:associated_class].present?

        query_params[:polymorphic_name] = params[:polymorphic_name]
        query_params[:associated_id] = params[:associated_id]
        query_params[:associated_class] = params[:associated_class]
        query_params[:referrer] = params[:referrer] if params[:referrer].present?

        url + '?' + query_params.to_query unless query_params.empty?
      end

      def is_field_presence_validated?(form_obj, field)
        associated_field = form_obj.object.class.reflect_on_all_associations(:belongs_to).reject do |association|
          association.options[:optional] || "#{association.name}_id" != field.field_name.to_s
        end
        form_obj.object._validators[field.field_name].map(&:kind).include?(:presence) || associated_field.present?
      end

      def find_model_name(form_obj, field)
        return unless field.can_create_new_entity.presence
        return field.can_create_new_entity[:model] if field.can_create_new_entity.is_a?(Hash) && field.can_create_new_entity[:model].present?

        associated_field = form_obj.object.class.reflect_on_all_associations(:belongs_to).select do |association|
          "#{association.name}_id" == field.field_name.to_s
        end
        associated_field&.first&.klass&.name
      end
    end
  end
end
