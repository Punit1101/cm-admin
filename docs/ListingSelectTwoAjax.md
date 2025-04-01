# Lisiting of Select Two using Ajax 🅰️

## Method 1: Using Ajax URL for Form Field

This method demonstrates how to create a form field with a single select input that uses an Ajax URL to fetch data.

### Adding Ajax URL Parameter

The below form field creates a single select input for optional languages. It uses an Ajax URL to fetch the language options dynamically.

```ruby
form_field :optional_language_id, input_type: :single_select, label: 'Optional Language', ajax_url: :fetch_optional_language
```


### Custom Action for Fetching Data

This custom action retrieves data from the database and returns it as a JSON response. Example below, is specifically designed to fetch optional language data based on a search parameter.

**Location**: Define this custom action in the index section of your configuration.


```ruby
custom_action name: 'fetch_optional_language', route_type: :collection, verb: 'get', path: '/fetch_optional_languages',
display_type: :route do
  @optional_language = ::Constant.search_constant_by_name(params[:search],"optional_language")
  {
    results: @optional_language.map { |language| { id: language.id, text: language.name.titleize } },
    pagination: { more: false }
  }
end
```

This custom action is used to fetch optional languages based on a search parameter. It returns a JSON response with the language results and pagination information.

## Method 2: Using HTML Attributes and JavaScript for Form Field

This method shows how to create a form field with custom HTML attributes and use JavaScript to implement the select functionality.

### Adding Custom HTML Attributes

```ruby
form_field :optional_language_id, input_type: :single_select, label: 'Optional Language', html_attrs: { 'data-behaviour': 'optional_language-select' }
```

This form field creates a single select input for optional languages with a custom data attribute for JavaScript targeting.



### Custom Action for Fetching Data

This custom action retrieves data from the database and returns it as a JSON response. Example below, is specifically designed to fetch optional language data based on a search parameter.

**Location**: Define this custom action in the index section of your configuration.


```ruby
custom_action name: 'fetch_optional_language', route_type: :collection, verb: 'get', path: '/fetch_optional_languages',
display_type: :route do
  @optional_language = ::Constant.search_constant(params[:search], params[:class],"optional_language")
  {
    results: @optional_language.map { |language| { id: language.id, text: language.name.titleize } },
    pagination: { more: false }
  }
end
```

### JavaScript Function for Select2 Implementation

This JavaScript function initializes a Select2 dropdown for the optional language select field. It configures Ajax loading of options, result processing, and pagination. We can also pass additional parameters to the server using the `data` attribute.

**Location**: Define this JavaScript function in your application's JavaScript file.

```javascript
function selectTwoAjaxCaller(){
  const $event = $('select[data-behaviour="optional_language-select"]');
    $event.select2({
        theme: "bootstrap-5",
        ajax: {
            url: "fetch_optional_languages",
            dataType: 'json',
            delay: 250,
            data: function (params) {
                return {
                    search: params.term,
                    class: 12
                };
            },
            processResults: function (data, params) {
                return {
                    results: data.results
                };
            },
        },
        minimumInputLength: 0,
    });
}
```

This JavaScript function initializes a Select2 dropdown for the optional language select field. It configures Ajax loading of options, result processing, and pagination.