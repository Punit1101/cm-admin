require_relative 'constants'
require_relative 'models/action'
require_relative 'models/importer'
require_relative 'models/custom_action'
require_relative 'models/bulk_action'
require_relative 'models/nested_field'
require_relative 'models/field'
require_relative 'models/form_field'
require_relative 'models/blocks'
require_relative 'models/column'
require_relative 'models/filter'
require_relative 'models/export'
require_relative 'models/section'
require_relative 'models/row'
require_relative 'models/tab'
require_relative 'models/dsl_method'
require_relative 'models/alert'
require 'pagy'
require 'axlsx'
require 'cocoon'
require 'pundit'
require 'local_time'
require 'csv_importer'

module CmAdmin
  class Model
    include Pagy::Backend
    include Models::Blocks
    include Models::DslMethod
    include CmAdmin::Engine.routes.url_helpers

    attr_accessor :available_actions, :actions_set, :available_fields, :additional_permitted_fields,
                  :current_action, :params, :filters, :available_tabs, :icon_name, :bulk_actions, :display_name,
                  :policy_scopes, :override_policy, :alerts, :sort_columns, :default_sort_column, :default_sort_direction
    attr_reader :name, :ar_model, :is_visible_on_sidebar, :importer

    def initialize(entity, &block)
      @name = entity.name
      @display_name = entity.name
      @ar_model = entity
      @is_visible_on_sidebar = true
      @icon_name = 'fa fa-th-large'
      @available_actions ||= []
      @bulk_actions ||= []
      @additional_permitted_fields ||= []
      @current_action = nil
      @available_tabs ||= []
      @available_fields ||= { index: [], show: [], edit: [], new: [] }
      @params = nil
      @override_policy = false
      @filters ||= []
      @policy_scopes ||= [{ display_name: 'Full Access', scope_name: 'all' }]
      @sort_columns ||= []
      @default_sort_direction ||= 'asc'
      @alerts = []
      instance_eval(&block) if block_given?
      actions unless @actions_set
      $available_actions = @available_actions.dup
      define_controller
      define_pundit_policy(@ar_model) unless @override_policy
    end

    class << self
      def find_by(search_hash)
        CmAdmin.config.cm_admin_models.find { |x| x.name == search_hash[:name] }
      end
    end

    def custom_controller_action(action_name, params)
      current_action = CmAdmin::Models::Action.find_by(self, name: action_name.to_s)
      return unless current_action

      @current_action = current_action
      @ar_object = @ar_model.name.classify.constantize.find(params[:id])
      if @current_action.child_records
        child_records = @ar_object.send(@current_action.child_records)
        @associated_model = CmAdmin::Model.find_by(name: @ar_model.reflect_on_association(@current_action.child_records).klass.name)
        @associated_ar_object = if child_records.is_a? ActiveRecord::Relation
                                  filter_by(params, child_records)
                                else
                                  child_records
                                end
        return @ar_object, @associated_model, @associated_ar_object
      end
      @ar_object
    end

    # Insert into actions according to config block
    def actions(only: [], except: [])
      acts = CmAdmin::DEFAULT_ACTIONS.keys
      acts &= ([] << only).flatten if only.present?
      acts -= ([] << except).flatten if except.present?
      acts.each do |act|
        action_defaults = CmAdmin::DEFAULT_ACTIONS[act]
        @available_actions << CmAdmin::Models::Action.new(name: act.to_s, verb: action_defaults[:verb], path: action_defaults[:path])
      end
      @actions_set = true
    end

    def importable(class_name:, importer_type:, sample_file_path: nil)
      @importer = CmAdmin::Models::Importer.new(class_name, importer_type, sample_file_path)
    end

    def visible_on_sidebar(visible_option)
      @is_visible_on_sidebar = visible_option
    end

    def set_icon(name)
      @icon_name = name
    end

    def override_pundit_policy(override_status = false)
      @override_policy = override_status
    end

    def set_display_name(name)
      @display_name = name
    end

    def permit_additional_fields(fields = [])
      @additional_permitted_fields = fields
    end

    def formatted_name
      @display_name != @name ? @display_name : @name.titleize
    end

    def alert_box(options = {})
      @alerts << CmAdmin::Models::Alert.new(options)
    end

    def model_name
      @display_name.present? ? @display_name : @name
    end

    def set_policy_scopes(scopes = [])
      @policy_scopes = ([{ display_name: 'Full Access', scope_name: 'all' }] + scopes).uniq
    end

    # Shared between export controller and resource controller
    def filter_params(params)
      # OPTIMIZE: Need to check if we can permit the filter_params in a better way
      date_columns = filters.select { |x| x.filter_type.eql?(:date) }.map(&:db_column_name)
      range_columns = filters.select { |x| x.filter_type.eql?(:range) }.map(&:db_column_name)
      single_select_columns = filters.select { |x| x.filter_type.eql?(:single_select) }.map(&:db_column_name)
      multi_select_columns = filters.select { |x| x.filter_type.eql?(:multi_select) }.map { |x| Hash["#{x.db_column_name}", []] }

      params.require(:filters).permit(:search, date: date_columns, range: range_columns, single_select: single_select_columns, multi_select: multi_select_columns) if params[:filters]
    end

    private

    # Controller defined for each model
    # If model is User, controller will be UsersController
    def define_controller
      if $available_actions.present?
        klass = Class.new(CmAdmin::ResourceController) do
          include Pundit::Authorization
          rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

          $available_actions.each do |action|
            define_method action.name.to_sym do
              # controller_name & action_name from ActionController
              @model = CmAdmin::Model.find_by(name: controller_name.classify)
              @model.params = params
              @action = CmAdmin::Models::Action.find_by(@model, name: action_name)
              @model.current_action = @action
              send(@action.controller_action_name, params)
              # @ar_object = @model.try(@action.parent || action_name, params)
            end
          end

          def pundit_user
            Current.user
          end

          private

          def user_not_authorized
            flash[:alert] = 'You are not authorized to perform this action.'
            redirect_to CmAdmin::Engine.mount_path + '/access-denied'
          end
        end
      end
      CmAdmin.const_set "#{@name}Controller", klass
    end

    def define_pundit_policy(ar_model)
      if $available_actions.present?
        klass = Class.new(ApplicationPolicy) do
          $available_actions.each do |action|
            define_method "#{action.name}?".to_sym do
              return false unless Current.user.respond_to?(:cm_role_id)
              return false if Current.user.cm_role.nil?

              Current.user.cm_role.cm_permissions.where(action_name: action.name, ar_model_name: ar_model.name).present?
            end
          end
        end
      end
      policy = CmAdmin.const_set "#{ar_model.name}Policy", klass

      $available_actions.each do |action|
        next if %w[custom_action_modal custom_action create update].include?(action.name)

        klass = Class.new(policy) do
          def initialize(user, scope)
            @user = user
            @scope = scope
          end

          define_method :resolve do
            # action_name = Current.request_params.dig("action")
            permission = Current.user.cm_role.cm_permissions.find_by(action_name: action.name, ar_model_name: ar_model.name)
            if permission.present? && permission.scope_name.present?
              scope.send(permission.scope_name)
            else
              scope.all
            end
          end

          private

          attr_reader :user, :scope
        end

        policy.const_set "#{action.name.classify}Scope", klass
      end
    end
  end
end
