module CmAdmin
  class Configuration
    attr_accessor :layout, :included_models, :cm_admin_models, :enable_tracking, :project_name

    def initialize
      @layout = 'admin'
      @included_models = []
      @cm_admin_models = []
      @enable_tracking = false
      @project_name = ''
    end
  end
end
