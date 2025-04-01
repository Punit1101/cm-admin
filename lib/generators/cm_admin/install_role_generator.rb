require 'rails/generators'

module CmAdmin
  module Generators
    class InstallRoleGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def create_migration
        generate 'migration', 'CreateCmRole name:string'
        generate 'migration', 'CreateCmPermission action_name:string action_display_name:string ar_model_name:string scope_name:string cm_role:references'
        rake 'db:migrate'
        puts "Created migration"
      end

      def create_default_role
        ::CmRole.create(name: 'Admin')
        CmAdmin.config.cm_admin_models.each do |model|
          model.available_actions.each do |action|
            next if ['custom_action_modal', 'custom_action', 'create', 'update'].include?(action.name)

            ::CmRole.find_by(name: 'Admin').cm_permissions.where(ar_model_name: model.name, action_name: action.name).first_or_create!
          end
        end
        puts "Created default role"
      end
    end
  end
end
