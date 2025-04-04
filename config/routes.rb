CmAdmin::Engine.routes.draw do
  controller 'static' do
    get '/', action: 'dashboard'
    get '/access-denied', action: 'error_403'
  end

  controller 'exports' do
    post '/export_to_file', action: 'export'
  end

  # Defining action routes for each model
  CmAdmin.config.cm_admin_models.each do |model|
    if model.importer
      scope model.name.tableize do
        send(:get, 'import', to: "#{model.name.underscore}#import_form", as: "#{model.name.underscore}_import_form")
        send(:post, 'import', to: "#{model.name.underscore}#import", as: "#{model.name.underscore}_import")
      end
    end

    if model.sort_columns.present?
      scope model.name.tableize do
        send(:post, 'reset_sort_columns', to: "#{model.name.underscore}#reset_sort_columns", as: "#{model.name.underscore}_reset_sort_columns")
      end
    end

    scope model.name.tableize do
      send(:get, 'fetch_drawer', to: "#{model.name.underscore}#fetch_drawer", as: "cm_fetch_drawer_#{model.name.underscore}")
    end

    model.available_actions.sort_by { |act| act.name }.each do |act|
      scope model.name.tableize do
        # Define route only when action trail related field is present
        if act.name == 'history'
          send(:get, ':id/history', to: "#{model.name.underscore}#history", as: "#{model.name.underscore}_history")
        else
          send(act.verb, act.path.present? ? act.path : act.name, to: "#{model.name.underscore}##{act.name}", as: "#{model.name.underscore}_#{act.name}")
        end
      end
    end
  end
end
