module CmAdmin
  class ResourceController < ApplicationController
    include Pundit::Authorization
    include Pagy::Backend

    helper CmAdmin::ViewHelpers

    skip_before_action :verify_authenticity_token, only: :reset_sort_columns

    def cm_index(params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'index')
      # Based on the params the filter and pagination object to be set
      authorize @ar_object, policy_class: "CmAdmin::#{controller_name.classify}Policy".constantize if defined? "CmAdmin::#{controller_name.classify}Policy".constantize
      records = "CmAdmin::#{@model.name}Policy::IndexScope".constantize.new(Current.user, @model.name.constantize).resolve
      records = apply_scopes(records)
      @ar_object = if %w[table card].include?(params[:view_type]) || %i[table card].include?(@current_action.view_type)
                     filter_by(params, records, filter_params: @model.filter_params(params))
                   elsif (request.xhr? && params[:view_type] == 'kanban') || @current_action.view_type == :kanban
                     kanban_filter_by(params, records, @model.filter_params(params))
                   else
                     filter_by(params, records, filter_params: @model.filter_params(params))
                   end
      respond_to do |format|
        if request.xhr? && (params[:view_type] == 'kanban' || @current_action.view_type == :kanban)
          format.json { render json: @ar_object }
        elsif request.xhr?
          format.html { render partial: '/cm_admin/main/table' }
        else
          format.html { render '/cm_admin/main/' + action_name }
        end
      end
    end

    def cm_show(params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'show')
      scoped_model = "CmAdmin::#{@model.name}Policy::ShowScope".constantize.new(Current.user, @model.name.constantize).resolve
      @ar_object = fetch_ar_object(scoped_model, params[:id])
      @alerts = @model.alerts
      resource_identifier
      respond_to do |format|
        if request.xhr?
          format.html { render partial: '/cm_admin/main/show_content', locals: { via_xhr: true } }
        else
          format.html { render '/cm_admin/main/' + action_name }
        end
        format.json { render json: @ar_object.to_builder.target! }
      end
    end

    def cm_new(_params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'new')
      @ar_object = @model.ar_model.new
      resource_identifier
      respond_to do |format|
        format.html { render '/cm_admin/main/' + action_name }
      end
    end

    def cm_edit(params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'edit')
      @ar_object = fetch_ar_object(@model.ar_model.name.classify.constantize, params[:id])
      resource_identifier
      respond_to do |format|
        format.html { render '/cm_admin/main/' + action_name }
      end
    end

    def cm_update(params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'edit')
      @ar_object = fetch_ar_object(@model.ar_model.name.classify.constantize, params[:id])
      @ar_object.assign_attributes(resource_params(params))
      resource_identifier
      resource_responder
    end

    def cm_create(params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'new')
      @ar_object = @model.ar_model.name.classify.constantize.new(resource_params(params))
      resource_identifier
      resource_responder
    end

    def cm_destroy(params)
      @ar_object = fetch_ar_object(@model.ar_model.name.classify.constantize, params[:id])
      redirect_url = request.referrer || cm_admin.send("#{@model.name.underscore}_index_path")
      respond_to do |format|
        if @ar_object.destroy
          format.html { redirect_back fallback_location: redirect_url, notice: "#{@model.formatted_name} was deleted" }
        else
          format.html { redirect_back fallback_location: redirect_url, alert: "#{@model.formatted_name} could not be deleted" }
        end
      end
    end

    def import
      @model = Model.find_by({ name: controller_name.classify })
      allowed_params = params.permit(file_import: %i[associated_model_name import_file]).to_h
      file_import = ::FileImport.new(allowed_params[:file_import])
      file_import.added_by = Current.user
      respond_to do |format|
        format.html { redirect_back fallback_location: cm_admin.send("#{@model.name.underscore}_index_path"), notice: 'Your import is successfully queued.' } if file_import.save!
      end
    end

    def import_form
      @model = Model.find_by({ name: controller_name.classify })
      respond_to do |format|
        format.html { render '/cm_admin/main/import_form' }
      end
    end

    def cm_bulk_action(params)
      @model = Model.find_by({ name: controller_name.classify })
      @bulk_action_processor = CmAdmin::BulkActionProcessor.new(@action, @model, params).perform_bulk_action
      respond_to do |format|
        if @bulk_action_processor.invalid_records.empty?
          flash[:notice] = "#{@action.formatted_name} was successful"
          flash[:bulk_action_success] = "<b>#{@action.formatted_name} was successful</b>"
          format.html { redirect_to request.referrer }
        else
          error_messages = @bulk_action_processor.invalid_records.map do |invalid_record|
            "<li>#{invalid_record.error_message}</li>"
          end.join
          flash[:alert] = "#{@action.formatted_name} was unsuccessful"
          flash[:bulk_action_error] = "<div>
              <div><b>#{@action.formatted_name} encountered the following errors:</b></div>
              <ul>#{error_messages}</ul>
            </div>"
          format.html { redirect_to request.referrer }
        end
      end
    end

    def cm_history(_params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: 'history')
      resource_identifier
      respond_to do |format|
        format.html { render '/cm_admin/main/history' }
      end
    end

    def cm_custom_method(params)
      records = "CmAdmin::#{@model.name}Policy::#{@action.name.classify}Scope".constantize.new(Current.user, @model.name.constantize).resolve
      @current_action = @action
      if @action.parent == 'index'
        records = apply_scopes(records)
        @ar_object = filter_by(params, records, filter_params: @model.filter_params(params))
      else
        resource_identifier
      end
      respond_to do |format|
        if @action.action_type == :custom
          if @action.child_records
            if request.xhr?
              format.html { render partial: '/cm_admin/main/associated_table' }
            else
              format.html { render @action.layout }
            end
          elsif @action.display_type == :page
            @action.parent == 'index' ? @ar_object.data : @ar_object
            # TODO: To set a default value for @action.layout, Since it is used in render above,
            # Need to check and fix it.
            format.html { render @action.partial, layout: @action.layout || 'cm_admin' }
          else
            begin
              response_object = @action.code_block.call(@response_object)
              if response_object.class == Hash
                format.json { render json: response_object }
              elsif response_object.errors.empty?
                redirect_url = @model.current_action.redirection_url || @action.redirection_url || request.referrer || "/cm_admin/#{@model.ar_model.table_name}/#{@response_object.id}"
                format.html { redirect_to redirect_url, notice: "#{@action.formatted_name} was successful" }
              else
                error_messages = response_object.errors.full_messages.map { |error_message| "<li>#{error_message}</li>" }.join
                format.html { redirect_to request.referrer, alert: "#{@action.formatted_name} was unsuccessful<br /><ul>#{error_messages}</ul>" }
              end
            rescue StandardError => e
              format.html { redirect_to request.referrer, alert: "<div>#{@action.formatted_name} was unsuccessful<br /><ul><li>#{e.message}</li></ul></div>" }
            end
          end
        end
      end
    end

    def cm_custom_action_modal(params)
      scoped_model = "CmAdmin::#{@model.name}Policy::#{params[:action_name].classify}Scope".constantize.new(Current.user, @model.name.constantize).resolve
      @ar_object = fetch_ar_object(scoped_model, params[:id])
      if params[:action_name] == 'destroy'
        render partial: '/layouts/destroy_action_modal', locals: { ar_object: @ar_object }
      else
        custom_action = @model.available_actions.select { |x| x.name == params[:action_name].to_s }.first
        render partial: '/layouts/custom_action_modal', locals: { custom_action:, ar_object: @ar_object }
      end
    end

    def reset_sort_columns
      @model = Model.find_by({ name: controller_name.classify })
      @model.default_sort_column = nil
      @model.default_sort_direction = nil
    end

    def fetch_drawer
      @model = Model.find_by({ name: controller_name.classify })
      return if @model.blank?

      action_page_title = CmAdmin::Models::Action.find_by(@model, name: 'new').page_title
      drawer_title = action_page_title.presence || "New #{@model&.formatted_name}"
      @ar_object = @model.ar_model.new
      render partial: 'layouts/drawer', locals: { drawer_title:, from_field_id: params[:from_field_id] }
    end

    def get_nested_table_fields(fields)
      nested_table_fields = []
      fields.each do |field|
        if field.class == CmAdmin::Models::Row
          nested_table_fields += field.sections.map(&:nested_table_fields).flatten
        elsif field.class == CmAdmin::Models::Section
          nested_table_fields += field.nested_table_fields.flatten
        end
      end
      nested_table_fields.flatten
    end

    def resource_identifier
      @ar_object, @associated_model, @associated_ar_object = custom_controller_action(action_name, params.permit!) if !@ar_object.present? && params[:id].present?
      authorize @ar_object, policy_class: "CmAdmin::#{controller_name.classify}Policy".constantize if defined? "CmAdmin::#{controller_name.classify}Policy".constantize
      aar_model = request.url.split('/')[-2].classify.constantize if params[:aar_id]
      @associated_ar_object = fetch_ar_object(aar_model, params[:aar_id]) if params[:aar_id]
      nested_fields = get_nested_table_fields(@model.available_fields[:new])
      nested_fields += get_nested_table_fields(@model.available_fields[:edit])
      @reflections = @model.ar_model.reflect_on_all_associations
      nested_fields.each do |nested_field|
        table_name = nested_field.field_name
        reflection = @reflections.select { |x| x if x.name == table_name }.first
        if reflection.macro == :has_many
          @ar_object.send(table_name).build if action_name == 'new' || action_name == 'edit'
        elsif action_name == 'new'
          @ar_object.send(('build_' + table_name.to_s).to_sym)
        end
      end
    end

    def resource_responder
      respond_to do |format|
        if @ar_object.save
          redirect_url = if params['referrer']
                           params['referrer']
                         elsif @current_action.redirect_to.present?
                           @current_action.redirect_to.call(@ar_object)
                         else
                           cm_admin.send("#{@model.name.underscore}_show_path", @ar_object)
                         end
          ActiveStorage::Attachment.where(id: params['attachment_destroy_ids']).destroy_all if params['attachment_destroy_ids'].present?
          notice = if @current_action&.name == 'new'
                     "#{@model&.formatted_name} was created"
                   elsif @current_action&.name == 'edit'
                     "#{@model&.formatted_name} was updated"
                   else
                     "#{@action&.formatted_name} #{@model&.formatted_name} was successful"
                   end
          format.html { redirect_to redirect_url, allow_other_host: true, notice: }
          name = if @ar_object.respond_to?(:formatted_name)
                   @ar_object.formatted_name
                 elsif @ar_object.respond_to?(:name)
                   @ar_object.name
                 else
                   @ar_object&.id
                 end
          format.json { render json: { message: notice, data: { id: @ar_object&.id, name: } }, status: :ok }
        else
          format.html { render '/cm_admin/main/new', notice: "#{@action&.formatted_name} #{@model&.formatted_name} was unsuccessful" }
          format.json do
            formatted_error_response = @ar_object.errors.full_messages.map { |error_message| "<li>#{error_message}</li>" }.join
            render json: { message: formatted_error_response }, status: :unprocessable_entity
          end
        end
      end
    end

    def custom_controller_action(action_name, params)
      @current_action = CmAdmin::Models::Action.find_by(@model, name: action_name.to_s)
      return unless @current_action

      scoped_model = "CmAdmin::#{@model.name}Policy::#{action_name.classify}Scope".constantize.new(Current.user, @model.ar_model.name.classify.constantize).resolve
      @ar_object = fetch_ar_object(scoped_model, params[:id])
      return @ar_object unless @current_action.child_records

      child_records = @ar_object.send(@current_action.child_records)
      child_records = apply_scopes(child_records)
      @reflection = @model.ar_model.reflect_on_association(@current_action.child_records)
      @associated_model = if @reflection.klass.column_names.include?('type')
                            CmAdmin::Model.find_by(name: @reflection.plural_name.classify)
                          else
                            CmAdmin::Model.find_by(name: @reflection.klass.name)
                          end

      @associated_ar_object = if child_records.is_a? ActiveRecord::Relation

                                filter_by(params, child_records, parent_record: @ar_object, filter_params: @associated_model.filter_params(params))
                              else
                                child_records
                              end
      [@ar_object, @associated_model, @associated_ar_object]
    end

    def apply_scopes(records)
      @current_action.scopes.each do |scope|
        records = records.send(scope)
      end
      records
    end

    def filter_by(params, records, parent_record: nil, filter_params: {}, sort_params: {})
      filtered_result = OpenStruct.new
      cm_model = @associated_model || @model
      db_columns = cm_model.ar_model&.columns&.map { |x| x.name.to_sym }
      sort_column = if db_columns.include?(params[:sort_column]&.to_sym)
                      params[:sort_column]
                    else
                      cm_model.default_sort_column
                    end
      sort_direction = params[:sort_direction] || cm_model.default_sort_direction
      records = "CmAdmin::#{@model.name}Policy::#{@current_action.name.classify}Scope".constantize.new(Current.user, @model.name.constantize).resolve if records.nil?
      records = records.order("#{sort_column} #{sort_direction}") if sort_column.present?
      final_data = CmAdmin::Models::Filter.filtered_data(filter_params, records, cm_model.filters)
      pagy, records = pagy(final_data)
      filtered_result.data = records
      filtered_result.pagy = pagy
      filtered_result.parent_record = parent_record
      filtered_result.associated_model = @associated_model.name if @associated_model
      filtered_result
    end

    def kanban_filter_by(params, records, filter_params = {}, _sort_params = {})
      filtered_result = OpenStruct.new
      cm_model = @associated_model || @model
      db_columns = cm_model.ar_model&.columns&.map { |x| x.name.to_sym }
      if db_columns.include?(@current_action.sort_column)
        @current_action.sort_column
      else
        'created_at'
      end
      records = "CmAdmin::#{@model.name}Policy::Scope".constantize.new(Current.user, @model.name.constantize).resolve if records.nil?
      # records = records.order("#{sort_column} #{@current_action.sort_direction}")
      final_data = CmAdmin::Models::Filter.filtered_data(filter_params, records, cm_model.filters)
      filtered_result.data = {}
      filtered_result.paging = {}
      filtered_result.paging['next_page'] = true
      group_record_count = final_data.group(params[:kanban_column_name] || @current_action.kanban_attr[:column_name]).count
      per_page = params[:per_page] || 20
      page = params[:page] || 1
      max_page = (group_record_count.values.max.to_i / per_page.to_f).ceil
      filtered_result.paging['next_page'] = (page.to_i < max_page)
      filtered_result.column_count = group_record_count.reject { |key, _value| key.blank? }

      column_names = @model.ar_model.send(params[:kanban_column_name]&.pluralize || @current_action.kanban_attr[:column_name].pluralize).keys
      if @current_action.kanban_attr[:only].present?
        column_names &= @current_action.kanban_attr[:only]
      elsif @current_action.kanban_attr[:exclude].present?
        column_names -= @current_action.kanban_attr[:exclude]
      end
      column_names.each do |column|
        total_count = group_record_count[column]
        filtered_result.data[column] = ''
        next if page.to_i > (total_count.to_i / per_page.to_f).ceil

        _, records = pagy(final_data.send(column), items: per_page.to_i)
        filtered_result.data[column] = render_to_string partial: 'cm_admin/main/kanban_card', locals: { ar_collection: records }
      end
      filtered_result
    end

    def generate_nested_params(nested_table_field)
      if nested_table_field.parent_field
        ar_model = nested_table_field.parent_field.to_s.classify.constantize
        table_name = ar_model.reflections.with_indifferent_access[nested_table_field.field_name.to_s].klass.table_name
      else
        table_name = @model.ar_model.reflections.with_indifferent_access[nested_table_field.field_name.to_s].klass.table_name
      end
      column_names = table_name.to_s.classify.constantize.column_names
      column_names = column_names.map { |column_name| column_name.gsub('_cents', '') }
      column_names = column_names.reject { |column_name| CmAdmin::REJECTABLE_FIELDS.include?(column_name) }.map(&:to_sym) + %i[id _destroy]
      if nested_table_field.associated_fields
        nested_table_field.associated_fields.each do |associated_field|
          column_names << generate_nested_params(associated_field)
        end
      end
      column_names += attachment_fields(table_name.to_s.classify.constantize)
      Hash[
        "#{table_name}_attributes",
        column_names
      ]
    end

    def resource_params(params)
      columns = @model.ar_model.columns_hash.map do |_key, ar_adapter|
        ar_adapter.sql_type_metadata.sql_type.ends_with?('[]') ? Hash[ar_adapter.name, []] : ar_adapter.name.to_sym
      end
      columns += @model.ar_model.stored_attributes.values.flatten
      permittable_fields = @model.additional_permitted_fields + columns.reject { |i| CmAdmin::REJECTABLE_FIELDS.include?(i) }
      permittable_fields += attachment_fields(@model.ar_model.name.constantize)
      nested_table_fields = get_nested_table_fields(@model.available_fields[:new])
      nested_table_fields += get_nested_table_fields(@model.available_fields[:edit])
      nested_fields = nested_table_fields.uniq.map do |nested_table_field|
        generate_nested_params(nested_table_field)
      end
      permittable_fields += nested_fields
      @model.ar_model.columns.map { |col| permittable_fields << col.name.split('_cents') if col.name.include?('_cents') }
      params.require(@model.name.underscore.to_sym).permit(*permittable_fields)
    end

    def fetch_ar_object(model_object, id)
      return model_object.friendly.find(id) if model_object.respond_to?(:friendly)

      model_object.find(id)
    end

    private

    def attachment_fields(model_object)
      model_object.reflect_on_all_associations.map do |reflection|
        next if reflection.options[:polymorphic]

        if reflection.class.name.include?('HasOne')
          reflection.name.to_s.gsub('_attachment', '').gsub('rich_text_', '').to_sym
        elsif reflection.class.name.include?('HasMany')
          Hash[reflection.name.to_s.gsub('_attachments', ''), []]
        end
      end.compact
    end
  end
end
