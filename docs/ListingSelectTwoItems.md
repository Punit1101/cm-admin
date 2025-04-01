# Population of items in drop-downs 🔽

This document provides details on various methods used in our project. Each method is explained with its purpose and usage examples.

## Method 1: Using Collection / Helper Method for Transport Type

The example below demonstrates how to create a section with a single-select field using collection.

```ruby
cm_section 'Mode Of Transport' do
  form_field :transport_type_id, input_type: :single_select, 
  collection: :mode_of_transport
end
```

💡Note: You need to set mode_transport array like this:

```ruby
mode_of_transport = [['Vehicle','vehicle'],['Bike', 'bike']]
```

Or you can use a helper method to fetch the data:

```ruby
cm_section 'Mode Of Transport' do
  form_field :transport_type_id, input_type: :single_select, 
  helper_method: :mode_of_transport_method
end
```

💡Note: This should be defined in the helper module:

```ruby
def mode_of_transport_method
  Constant.where(type:"transport_type").all.map { |item| [item.full_name, item.id] }
end
```

## Method 2: Custom Action for Transport Type

The example below demonstrates how to create a section with a single-select field using a custom action.

This custom action is designed to fetch transport type data from the database and automatically populate the dropdown with the appropriate values when triggered.

💡 Note: The retrieved data is used to populate the target_value field.

**Location**: This custom action should be defined in the index section of your configuration.

```ruby
custom_action name: 'transport_type',  route_type: :collection, verb: 'get', path: '/transport_type', display_type: :route do
transport_type = Constant.where(type: :transport_type).all.map { |item| [item.full_name, item.id] }
  {
    fields: [
      {
        target_type: :select,
        target_value: {
          table: 'student',
          field_name: 'transport_type_id',
          field_value: transport_type
        }
      }
    ]
  }
end
```

💡Note: This needs to be added as a trigger variable for populating the fields:

```ruby
form_field :route_id, input_type: :single_select, target: { action_name: :fetch_transport_type }
```
