module CmAdmin
  module ViewHelpers
    module FilterHelper
      def generate_filters(filters)
        search_filter = filters.select { |x| x.filter_type.eql?(:search) }.last
        other_filters = filters.reject { |x| x.filter_type.eql?(:search) }
        concat(content_tag(:div, class: 'cm-filters-v2') do
          concat(content_tag(:div, class: 'cm-filters-v2__inner') do
            concat add_search_filter(search_filter) if search_filter
            if other_filters.any?
              concat filter_ui(other_filters)
              concat add_filters_dropdown(other_filters)
            end
            concat clear_filters
          end)
        end)
        nil
      end

      def add_filters_dropdown(filters)
        concat(content_tag(:button, class: 'dropdown btn-ghost', data: { bs_toggle: 'dropdown' }) do
          concat tag.i(class: 'fas fa-filter')
          concat tag.span 'Filters'
        end)

        concat(content_tag(:div, class: 'dropdown-menu dropdown-popup') do
          concat(content_tag(:div, class: 'popup-base') do
            concat(content_tag(:div, class: 'popup-inner') do
              concat(content_tag(:div, class: 'search-area') do
                concat tag.input placeholder: 'Search for filter', data: { behaviour: 'dropdown-filter-search' }
              end)
              concat(content_tag(:div, class: 'list-area') do
                filters.each do |filter|
                  concat(content_tag(:div, class: 'pointer list-item', data: { behaviour: 'filter-option', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}" }) do
                    tag.span filter.display_name.to_s
                  end)
                end
              end)
            end)
          end)
        end)
        nil
      end

      def clear_filters
        concat(content_tag(:div, class: "clear-btn #{params.dig(:filters) ? '' : 'hidden'}") do
          tag.span 'Clear all'
        end)
        nil
      end

      def filter_ui(filters)
        filters.each do |filter|
          case filter.filter_type
          when :date
            concat add_date_filter(filter)
          when :range
            concat add_range_filter(filter)
          when :single_select
            concat add_single_select_filter(filter)
          when :multi_select
            concat add_multi_select_filter(filter)
          end
        end
        nil
      end

      def filter_chip(value, filter)
        data_hash = { behaviour: 'filter-input', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}" }
        data_hash.merge!(bs_toggle: 'dropdown') if filter.filter_type.to_s.eql?('single_select')

        if value && filter.filter_type.to_s.eql?('multi_select')
          truncated_value = value[0]
          truncated_value += " + #{value.size - 1} more" if value.size > 1
        end
        concat(content_tag(:div, class: "filter-chip #{filter.filter_type.to_s.eql?('single_select') ? 'dropdown' : ''}", data: data_hash) do
          concat tag.span "#{filter.display_name} is "
          concat tag.span "#{filter.filter_type.to_s.eql?('multi_select') ? truncated_value : value}"
          concat(content_tag(:div, class: "filter-chip-remove #{value ? '' : 'hidden'}") do
            tag.i class: 'fa fa-times bolder'
          end)
        end)
        nil
      end

      def add_search_filter(filter)
        tag.div class: 'filter-search me-3' do
          concat(content_tag(:div, class: 'input-group input-group-sm') do
            concat(content_tag(:span, class: 'input-group-text') do
              tag.i class: 'fa fa-search'
            end)
            concat tag.input type: 'string', class: 'form-control', value: "#{params.dig(:filters, :search)}", placeholder: "#{filter.placeholder}", data: { behaviour: 'input-search' }
          end)
        end
      end

      def add_range_filter(filter)
        value = params.dig(:filters, :range, :"#{filter.db_column_name}")
        is_active = value || filter.active_by_default
        concat(content_tag(:div, class: "position-relative me-3 #{is_active ? '' : 'hidden'}") do
          concat filter_chip(value, filter)

          concat(content_tag(:div, class: 'position-absolute mt-2 range-container hidden') do
            concat tag.input type: 'number', min: '0', step: '1', class: 'range-item', value: "#{value ? value.split(' to ')[0] : ''}", placeholder: 'From', data: { behaviour: 'filter', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}" }
            concat tag.input type: 'number', min: '0', step: '1', class: 'range-item', value: "#{value ? value.split(' to ')[1] : ''}", placeholder: 'To', data: { behaviour: 'filter', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}" }
          end)
        end)
        nil
      end

      def add_date_filter(filter)
        value = params.dig(:filters, :date, :"#{filter.db_column_name}")
        is_active = value || filter.active_by_default
        concat(content_tag(:div, class: "position-relative me-3 #{is_active ? '' : 'hidden'}") do
          concat filter_chip(value, filter)

          concat(content_tag(:div, class: 'date-filter-wrapper w-100') do
            concat tag.input class: 'w-100 pb-1', value: "#{value || ''}", data: { behaviour: 'filter', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}" }
          end)
        end)
        nil
      end

      def add_single_select_filter(filter)
        value = params.dig(:filters, :"#{filter.filter_type}", :"#{filter.db_column_name}")
        is_active = value || filter.active_by_default
        select_options = if filter.helper_method
                           send(filter.helper_method)
                         elsif filter.collection
                           filter.collection
                         else
                           []
                         end
        concat(content_tag(:div, class: "position-relative me-3 #{is_active ? '' : 'hidden'}") do
          selected_value_text = if value && select_options[0].class == Array
                                  select_options.map { |collection| collection[0] if collection[1].to_s.eql?(value) }.compact.join(', ')
                                else
                                  value
                                end
          concat filter_chip(selected_value_text, filter)

          concat(content_tag(:div, class: 'dropdown-menu dropdown-popup') do
            concat(content_tag(:div, class: 'popup-base') do
              concat(content_tag(:div, class: 'popup-inner') do
                concat(content_tag(:div, class: 'search-area') do
                  concat tag.input placeholder: "#{filter.placeholder}", data: { behaviour: 'dropdown-filter-search' }
                end)
                concat(content_tag(:div, class: 'list-area') do
                  select_options.each do |val|
                    if val.class.eql?(Array)
                      filter_value = val[1]
                      filter_text = val[0]
                    elsif val.class.eql?(String)
                      filter_value = filter_text = val
                    end
                    concat(content_tag(:div, class: "pointer list-item #{value.present? && value.eql?(filter_value.to_s) ? 'selected' : ''}", data: { behaviour: 'select-option', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}", value: filter_value }) do
                      concat tag.span filter_text.to_s
                    end)
                  end
                end)
              end)
            end)
          end)
        end)
        nil
      end

      def add_multi_select_filter(filter)
        value = params.dig(:filters, :"#{filter.filter_type}", :"#{filter.db_column_name}")
        is_active = value || filter.active_by_default
        select_options = if filter.helper_method
                           send(filter.helper_method)
                         elsif filter.collection
                           filter.collection
                         else
                           []
                         end
        if value && select_options[0].class == Array
          value_mapped_text = []
          select_options.each do |array|
            value_mapped_text << array[0].titleize if value.include?(array[1].to_s)
          end
        else
          value_mapped_text = value
        end

        concat(content_tag(:div, class: "position-relative me-3 #{is_active ? '' : 'hidden'}") do
          concat filter_chip(value_mapped_text, filter)

          concat(content_tag(:div, class: 'position-absolute mt-2 dropdown-popup hidden') do
            concat(content_tag(:div, class: 'popup-base') do
              concat(content_tag(:div, class: 'popup-inner') do
                concat(content_tag(:div, class: "#{value ? 'search-with-chips' : 'search-area'}") do
                  if value_mapped_text
                    value_mapped_text.each do |val|
                      concat(content_tag(:div, class: 'chip') do
                        concat tag.span val
                        concat(content_tag(:span, data: { behaviour: 'selected-chip' }) do
                          tag.i class: 'fa fa-times'
                        end)
                      end)
                    end
                  end
                  concat tag.input placeholder: "#{filter.placeholder}", data: { behaviour: 'dropdown-filter-search' }
                end)
                concat(content_tag(:div, class: 'list-area') do
                  select_options.each do |val|
                    if val.class.eql?(Array)
                      filter_value = val[1]
                      filter_text = val[0]
                    elsif val.class.eql?(String)
                      filter_value = filter_text = val
                    end
                    concat(content_tag(:div, class: "pointer list-item #{value && (value.eql?(val) || value.include?(filter_value.to_s)) ? 'selected' : ''}", data: { behaviour: 'select-option', filter_type: "#{filter.filter_type}", db_column: "#{filter.db_column_name}", value: filter_value }) do
                      concat tag.input class: 'cm-checkbox', type: 'checkbox', checked: value ? value.include?(filter_value.to_s) : false
                      concat tag.label filter_text.to_s.titleize, class: 'pointer'
                    end)
                  end
                end)
                concat tag.div 'Apply', class: "apply-area #{value ? 'active' : ''}"
              end)
            end)
          end)
        end)
        nil
      end
    end
  end
end
