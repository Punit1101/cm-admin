# Role and Permission Management 🎭

## Overview

Role and permission management is facilitated through CmAdmin, which dynamically creates Pundit policies. This tool allows us to manage permissions via an intuitive interface.

## Features

- **Create Role:** Easily create any role needed for the application.
- **Manage Permissions:** View and modify all possible actions for each role, enabling or disabling permissions as necessary.

## Usage

### Adding Role and Permission Table

Run the following command to add the role and permission table:

```bash
rails g cm_admin:install_role
```

This Rake task generates a default migration.

**Note:** Ensure that you have the `paper_trail` gem installed before running the command.

### Creating Role Column on User Table

To create a role column in the user table, execute:

```bash
rails g migration AddCmRoleToUser cm_role:references
```

**Note:** The column name must be `cm_role_id`, or the policy will fail.

### Assigning Roles to Users

Currently, each user can be assigned only one role. To set the current request parameters:

1. In `app/models/current.rb`, add `request_params` as an attribute.
2. In `app/controllers/concerns/authentication.rb`, set the request parameters to help CmAdmin identify the action in the Pundit policy.

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :check_current_user
    before_action :set_params
  end
  
  def set_params
    Current.request_params = params if params
  end

  # Add other methods here 

end
```

3. Add `belongs_to :cm_role, optional: true` in the `User` model.  
4. Include `CmRole` in the `config.included_models` section of `config/initializers/zcm_admin.rb`.  
5. Assign `cm_role_id` to `1` for any user in the `User` Model, and use that user to log in.

## Setting up scopes

By default, `Full Access` scopes is added to each permission item. To add additional scopes, use the following syntax:

```ruby
...
cm_admin do
  actions only: []
  set_icon "fa fa-user"
  set_policy_scopes [{scope_name: 'test_supplier_filter', display_name: 'By Test Supplier'}]
  cm_index do
    page_title 'User'
  end
end

## Overriding Policies

By default, roles and policies are enabled for all models in the application. To override a policy, use the following syntax:

```ruby
...
cm_admin do
  actions only: []
  set_icon "fa fa-user"
  override_pundit_policy true
  cm_index do
    page_title 'User'
  end
end
```

Then, create a policy file for the respective model, e.g., `app/policies/cm_admin/user_policy.rb`:

```ruby
class CmAdmin::UserPolicy < ApplicationPolicy
  def index?
    true
  end
  # Add other actions here
end
```

This structure helps ensure that your application's role and permission management is both flexible and secure.


## Permission based fields

We can apply permission logic to display a field on the interface. You can do this with the following syntax.

```ruby
...
tab :details, '' do
  row do
    cm_show_section 'Details' do
      field :status, field_type: :tag, tag_class: Item::STATUS_TAG_COLOR, display_if: -> (record) {
        scoped_model = CmAdmin::ItemPolicy::ArchiveScope.new(Current.user, ::Item).resolve
        return scoped_model.find_by(id: record.id).present?
      }
    end
  end
end

```

