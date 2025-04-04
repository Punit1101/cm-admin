module CmAdmin
  module ViewHelpers
    module FormFieldHelper
      def input_field_for_column(form_obj, cm_field, is_required: nil)
        return unless cm_field.display_if.call(form_obj.object)

        value = if cm_field.helper_method
                  send(cm_field.helper_method, form_obj.object, cm_field.field_name)
                elsif cm_field.input_type.to_s.include?('custom')
                  nil
                else
                  form_obj.object.send(cm_field.field_name)
                end
        is_required = is_field_presence_validated?(form_obj, cm_field) if is_required.nil?
        required_class = is_required ? 'required' : ''
        target_action = @model.available_actions.select { |x| x.name == cm_field.target[:action_name].to_s }.first if cm_field.target.present?
        send("cm_#{cm_field.input_type}_field", form_obj, cm_field, value, required_class, target_action, cm_field.ajax_url)
      end

      def cm_integer_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        form_obj.text_field cm_field.field_name,
                            merge_wrapper_options(
                              {
                                class: "field-control #{required_class}",
                                disabled: cm_field.disabled.call(form_obj.object),
                                value:,
                                placeholder: cm_field.placeholder,
                                data: { behaviour: 'integer-only' }
                              }, cm_field.html_attrs
                            )
      end

      def cm_decimal_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        form_obj.text_field cm_field.field_name,
                            merge_wrapper_options({
                                                    class: "field-control #{required_class}",
                                                    disabled: cm_field.disabled.call(form_obj.object),
                                                    value:,
                                                    placeholder: cm_field.placeholder,
                                                    data: { behaviour: 'decimal-only' }
                                                  }, cm_field.html_attrs)
      end

      def cm_string_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        form_obj.text_field cm_field.field_name,
                            merge_wrapper_options(
                              {
                                class: "field-control #{required_class}",
                                disabled: cm_field.disabled.call(form_obj.object),
                                value:,
                                placeholder: cm_field.placeholder
                              }, cm_field.html_attrs
                            )
      end

      def cm_switch_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)\
        content_tag :div, class: 'form-check form-switch' do
          concat form_obj.check_box cm_field.field_name,
                                    merge_wrapper_options(
                                      {
                                        class: "field-control form-check-input #{required_class}",
                                        disabled: cm_field.disabled.call(form_obj.object),
                                        value:,
                                        role: 'switch'
                                      }, cm_field.html_attrs
                                    )
          concat content_tag(:div, cm_field.label, class: 'cm-switch-label')
        end
      end

      def cm_custom_string_field(form_obj, cm_field, value, required_class, _target_action_ajax_url)
        text_field_tag cm_field.html_attrs[:name] || cm_field.field_name,
                       merge_wrapper_options(
                         {
                           value:,
                           class: "field-control #{required_class}",
                           disabled: cm_field.disabled.call(form_obj.object),
                           placeholder: cm_field.placeholder
                         }, cm_field.html_attrs
                       )
      end

      def cm_single_select_field(form_obj, cm_field, _value, required_class, target_action, ajax_url)
        class_name = ajax_url.present? ? 'select-2-ajax' : 'select-2'
        form_obj.select cm_field.field_name, options_for_select(select_collection_value(form_obj.object, cm_field), form_obj.object.send(cm_field.field_name)),
                        { include_blank: cm_field.placeholder },
                        merge_wrapper_options(
                          {
                            class: "field-control #{required_class} #{class_name}",
                            disabled: cm_field.disabled.call(form_obj.object),
                            data: {
                              field_name: cm_field.field_name,
                              field_type: 'linked-field',
                              target_action: target_action&.name,
                              target_url: target_action&.name ? cm_admin.send("#{@model.name.underscore}_#{target_action&.name}_path") : '',
                              ajax_url:
                            }
                          }, cm_field.html_attrs
                        )
      end

      def cm_custom_single_select_field(form_obj, cm_field, _value, required_class, target_action, _ajax_url)
        select_tag cm_field.html_attrs[:name] || cm_field.field_name,
                   options_for_select(select_collection_value(form_obj.object, cm_field)),
                   { include_blank: cm_field.placeholder },
                   merge_wrapper_options(
                     {
                       class: "field-control #{required_class} select-2",
                       disabled: cm_field.disabled.call(form_obj.object),
                       data: {
                         field_name: cm_field.field_name,
                         field_type: 'linked-field',
                         target_action: target_action&.name,
                         target_url: target_action&.name ? cm_admin.send("#{@model.name.underscore}_#{target_action&.name}_path") : ''
                       }
                     }, cm_field.html_attrs
                   )
      end

      def cm_multi_select_field(form_obj, cm_field, _value, required_class, _target_action, _ajax_url)
        form_obj.select cm_field.field_name,
                        options_for_select(select_collection_value(form_obj.object, cm_field), form_obj.object.send(cm_field.field_name)),
                        { include_blank: cm_field.placeholder },
                        merge_wrapper_options(
                          {
                            class: "field-control #{required_class} select-2",
                            disabled: cm_field.disabled.call(form_obj.object), multiple: true
                          }, cm_field.html_attrs
                        )
      end

      def cm_date_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        form_obj.text_field cm_field.field_name,
                            merge_wrapper_options(
                              {
                                class: "field-control #{required_class}",
                                disabled: cm_field.disabled.call(form_obj.object),
                                value: value&.strftime('%d-%m-%Y'),
                                placeholder: cm_field.placeholder,
                                data: { behaviour: 'date-only' }
                              }, cm_field.html_attrs
                            )
      end

      def cm_custom_date_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        text_field_tag cm_field.html_attrs[:name] || cm_field.field_name, value&.strftime('%d-%m-%Y'),
                       merge_wrapper_options(
                         {
                           class: "field-control #{required_class}",
                           disabled: cm_field.disabled.call(form_obj.object),
                           value: value&.strftime('%d-%m-%Y'),
                           placeholder: cm_field.placeholder,
                           data: { behaviour: 'date-only' }
                         }, cm_field.html_attrs
                       )
      end

      def cm_date_time_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        form_obj.text_field cm_field.field_name,
                            merge_wrapper_options(
                              {
                                class: "field-control #{required_class}",
                                disabled: cm_field.disabled.call(form_obj.object),
                                value:,
                                placeholder: cm_field.placeholder,
                                data: { behaviour: 'date-time' }
                              }, cm_field.html_attrs
                            )
      end

      def cm_text_field(form_obj, cm_field, _value, required_class, _target_action, _ajax_url)
        form_obj.text_area cm_field.field_name,
                           merge_wrapper_options(
                             {
                               class: "field-control #{required_class}",
                               placeholder: cm_field.placeholder
                             }, cm_field.html_attrs
                           )
      end

      def cm_rich_text_field(form_obj, cm_field, _value, required_class, _target_action, _ajax_url)
        form_obj.rich_text_area cm_field.field_name,
                                merge_wrapper_options(
                                  {
                                    class: "field-control #{required_class}",
                                    placeholder: cm_field.placeholder
                                  }, cm_field.html_attrs
                                )
      end

      def cm_single_file_upload_field(form_obj, cm_field, _value, required_class, _target_action, _ajax_url)
        content_tag(:div) do
          concat form_obj.file_field cm_field.field_name,
                                     merge_wrapper_options(
                                       {
                                         class: "field-control #{required_class}",
                                         disabled: cm_field.disabled.call(form_obj.object)
                                       }, cm_field.html_attrs
                                     )
          concat attachment_list(form_obj, cm_field, _value, required_class, _target_action)
        end
      end

      def cm_multi_file_upload_field(form_obj, cm_field, _value, required_class, _target_action, _ajax_url)
        content_tag(:div) do
          concat form_obj.file_field cm_field.field_name,
                                     merge_wrapper_options(
                                       {
                                         multiple: true, class: "field-control #{required_class}",
                                         disabled: cm_field.disabled.call(form_obj.object)
                                       }, cm_field.html_attrs
                                     )
          concat attachment_list(form_obj, cm_field, _value, required_class, _target_action)
        end
      end

      def attachment_list(form_obj, cm_field, _value, _required_class, _target_action)
        attached = form_obj.object.send(cm_field.field_name)
        attachment_name = "#{form_obj.object_name}_#{cm_field.field_name}_attachments"
        return if defined?(::Paperclip) && attached.instance_of?(::Paperclip::Attachment)

        content_tag(:div) do
          if attached.class == ActiveStorage::Attached::Many
            attached.each do |attachment|
              concat attachment_with_icon(cm_field, attachment, attachment_name:)
            end
          elsif attached.attached?
            concat attachment_with_icon(cm_field, attached, attachment_name:)
          end
        end
      end

      def attachment_with_icon(cm_field, attachment, attachment_name:)
        content_tag(:div, class: 'destroy-attachment', data: { ar_id: attachment.id, attachment_name: }) do
          concat(content_tag(:button, '', class: 'btn-ghost') do
            concat tag.i(class: 'fa-regular fa-trash-can')
          end)
          concat content_tag(:span, attachment.filename.to_s, class: 'btn-link')
          concat(content_tag(:a, href: attachment.url, target: '_blank') do
            if attachment.content_type.include?('image')
              image_tag(attachment.url, height: 50, width: 50, class: "rounded")
            end
          end) if cm_field.image_preview
        end
      end

      def cm_check_box_field(form_obj, cm_field, _value, required_class, target_action, _ajax_url)
        content_tag :div, class: 'form-check' do
          concat form_obj.check_box cm_field.field_name,
                                    merge_wrapper_options(
                                      {
                                        class: "form-check-input #{required_class} #{target_action.present? ? 'linked-field-request' : ''}",
                                        disabled: cm_field.disabled.call(form_obj.object),
                                        data: {
                                          field_name: cm_field.field_name,
                                          target_action: target_action&.name,
                                          target_url: target_action&.name ? cm_admin.send("#{@model.name.underscore}_#{target_action&.name}_path") : ''
                                        }
                                      }, cm_field.html_attrs
                                    )
          concat content_tag(:div, cm_field.label, class: 'cm-checkbox-label')
        end
      end

      def cm_checkbox_group_field(form_obj, cm_field, value, required_class, _target_action, _ajax_url)
        original_value = form_obj.object.send(cm_field.field_name)
        content_tag :div do
          concat form_obj.text_field cm_field.field_name, name: "#{@model.name.underscore}[#{cm_field.field_name}][]",
                                                          value: nil, hidden: true
          value.each do |key, val|
            is_checked = original_value.include?(val)
            concat format_check_box(val || key, key, form_obj, cm_field, required_class, is_checked)
          end
        end
      end

      def cm_radio_button_field(form_obj, cm_field, value, _required_class, _target_action, _ajax_url)
        content_tag :div do
          value.each do |key, val|
            concat format_radio_option(val || key, key, cm_field, form_obj)
          end
        end
      end

      def cm_radio_button_group_field(form_obj, cm_field, value, _required_class, _target_action, _ajax_url)
        content_tag :div, class: 'btn-group', role: 'group' do
          value.each do |key, val|
            format_radio_button_group_option(val || key, key, cm_field, form_obj)
          end
        end
      end

      def cm_hidden_field(form_obj, cm_field, value, _required_class, _target_action, _ajax_url)
        form_obj.hidden_field cm_field.field_name,
                              merge_wrapper_options(
                                {
                                  value:,
                                  name: cm_field.html_attrs[:name] || "#{form_obj.object_name}[#{cm_field.field_name}]"
                                }, cm_field.html_attrs
                              )
      end

      # Refactor: Collection argument can be removed.
      # helper_method argument will accept a method where value can be passed.
      def select_collection_value(object, cm_field)
        if cm_field.helper_method
          send(cm_field.helper_method, object, cm_field.field_name)
        elsif cm_field.collection
          cm_field.collection
        else
          []
        end
      end

      def format_check_box(val, key, form_obj, cm_field, required_class, is_checked)
        content_tag :div, class: 'form-check' do
          concat check_box_tag "#{@model.name.underscore}[#{cm_field.field_name}][]", val, is_checked,
                               merge_wrapper_options(
                                 {
                                   class: "form-check-input #{required_class}",
                                   disabled: cm_field.disabled.call(form_obj.object)
                                 }, cm_field.html_attrs
                               )
          concat content_tag(:div, key, class: 'cm-checkbox-label')
        end
      end

      def format_radio_option(val, key, cm_field, form_obj)
        content_tag :div, class: 'form-check' do
          concat form_obj.radio_button cm_field.field_name, val, merge_wrapper_options({ class: 'form-check-input' }, cm_field.html_attrs)
          concat content_tag(:div, key, class: 'form-check-label')
        end
      end

      def format_radio_button_group_option(val, key, cm_field, form_obj)
        id = "#{cm_field.field_name}_#{val}"
        concat form_obj.radio_button cm_field.field_name, val, merge_wrapper_options({ id:, class: 'btn-check' },
                                                                                     cm_field.html_attrs)
        concat content_tag(:label, key, class: 'btn btn-outline-dark btn-sm', for: id)
      end

      def merge_wrapper_options(options, html_attrs)
        if html_attrs
          options.merge(html_attrs) do |key, oldval, newval|
            case key.to_s
            when 'class'
              oldval + ' ' + newval
            when 'data', 'aria'
              oldval.merge(newval)
            else
              newval
            end
          end
        else
          options
        end
      end
    end
  end
end
