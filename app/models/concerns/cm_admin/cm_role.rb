module CmAdmin::CmRole
  extend ActiveSupport::Concern
  included do
    cm_admin do
      actions only: []
      set_icon 'fa fa-database'
      cm_index do
        page_title 'Roles & Permissions'
        set_display_name 'Role'

        filter [:name], :search, placeholder: 'Search'

        column :name
        column :created_at, field_type: :date, format: '%d %b, %Y'
        column :updated_at, field_type: :date, format: '%d %b, %Y'
      end

      cm_show page_title: :name do
        custom_action name: 'create_role_permission', route_type: 'member', verb: 'post', path: ':id/create_role_permission',
                      display_type: :route do
          # allowed_params = params.permit(role_permission: []).to_h
          @role = CmRole.find(params[:id])
          params[:role_permission].except(:submit).each do |model_name, action_arr|
            action_names = action_arr.select { |k, v| k if v.key?('is_checked') }.keys
            action_names << 'create' if action_names.include?('new')
            action_names << 'update' if action_names.include?('edit')
            @role.cm_permissions.where(ar_model_name: model_name).where.not(action_name: action_names).destroy_all
            action_arr.each do |action_name, selected_option|
              if selected_option.has_key?('is_checked')
                permission = @role.cm_permissions.where(action_name:, ar_model_name: model_name).first_or_create
                permission.update(scope_name: selected_option['scope_name'])
              end
            end
          end
          @role
        end
        tab :profile, '' do
          cm_show_section 'Role details' do
            field :name
            field :created_at, field_type: :date, format: '%d %b, %Y'
            field :updated_at, field_type: :date, format: '%d %b, %Y'
          end
        end
        tab :permissions, 'permissions', layout_type: 'cm_association_show', partial: '/cm_admin/roles/permissions'
      end

      cm_new page_title: 'Add Role', page_description: 'Enter all details to add role' do
        cm_section 'Details' do
          form_field :name, input_type: :string
        end
      end

      cm_edit page_title: 'Edit Role', page_description: 'Enter all details to edit role' do
        cm_section 'Details' do
          form_field :name, input_type: :string
        end
      end
    end
  end
end
