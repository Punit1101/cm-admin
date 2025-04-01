# Hide or Show Section and Fields 🦹

This module provides methods for hiding form sections and fields with HTML attributes.

## Method 1: Using HTML Attributes and JavaScript for Form Section

### Adding Custom HTML Attributes

Define the html_attrs attribute in a section / field to add custom HTML attributes.

```ruby
cm_section 'Private Van', html_attrs: { "data-behaviour": "private_van-section"} do
  form_field :transport_vehicle_number, input_type: :string, label: 'Vehicle Number'
  form_field :transport_vehicle_in_charge, input_type: :string, label: 'Vehicle In Charge'
  form_field :transport_vehicle_in_charge_phone, input_type: :integer, label: 'Vehicle In Charge Phone'
end
```

The below JavaScript code manages the visibility of the "Private Van" section based on a condition.

**Location**: Define this JavaScript function in your application's JavaScript file.

```javascript
$(document).on("turbo:load", function() {
  $(document).on('change', 'select[data-behaviour="transport_type-select"]', handleTransportTypeChange);
});

function handleTransportTypeChange(event) {
  // Get the section element by its data attribute
  var section = $('div[data-behaviour="private_van-section"]');
  
  // Get the selected value
  var selectedValue = $(event.target).val();
  
  // Toggle the visibility based on the condition
  if (selectedValue !== "private_van") {
    section.addClass('hidden');
  } else {
    section.removeClass('hidden');
  }
}
```

## Method 2: Using `display_if` Attribute for Form Section

### Adding `display_if` Attribute for Form Section

Define the `display_if` attribute in a section to conditionally display the section based on a condition.

```ruby
cm_section 'Private Van', display_if:->(trip){trip.transport_type== "private_van" } do
  form_field :transport_vehicle_number, input_type: :string, label: 'Vehicle Number'
  form_field :transport_vehicle_in_charge, input_type: :string, label: 'Vehicle In Charge'
  form_field :transport_vehicle_in_charge_phone, input_type: :integer, label: 'Vehicle In Charge Phone'
end
```

### Adding `display_if` Attribute for Form Field

Define the `display_if` attribute in a field to conditionally display the field based on a condition.

```ruby
form_field :transport_vehicle_number, input_type: :single_select,collection: :mode_of_transport, display_if:->(trip){
  trip.transport_type=="private_van" }
```

You can also use the `display_if` attribute in any field to conditionally display the field based on a condition.


💡Note: The `display_if` attribute is used to conditionally display the section based on the value of `trip.transport_type`. It doesn't updated in real time like the JavaScript method.