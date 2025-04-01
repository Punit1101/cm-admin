# Adding Alert Feature ⚠️

## Overview

The Alert feature has been added to CmAdmin to provide a standardized method for displaying alerts and notifications to users. This documentation outlines how to use the Alert, including its configuration, types, and examples.

## Features

- **Customizable Alerts:** Display alerts with headers, bodies, and specific types.
- **Conditional Display:** Control when alerts should be shown based on dynamic conditions.
- **Type Support:** Supports four predefined types of alerts: `info`, `success`, `danger`, and `warning`.

## Usage

The Alert Banner is implemented using the `alert_box` helper. Below are the key elements and their usage:

### Syntax

**1. Using Parameters:**

```ruby
alert_box header:"Title", body:"Body1", type: :info, display_if:->(arg){arg.present?}, html_attrs:{}
```

**2. Using a Partial:**

```ruby
alert_box partial:"/users/sessions/alert", display_if:->(arg){arg.present?}, html_attrs:{}
```

### Parameters

- **`header:`** (optional) - The title text for the alert.
- **`body:`** (optional) - A string to display as the body of the alert.
- **`type:`** (optional) - The type of alert. Accepts one of the following symbols: `:info`, `:success`, `:danger`, `:warning`.
- **`partial:`** (optional) - The path to a custom partial or HTML for the alert.
- **`display_if:`** (optional) - A lambda function that determines whether the alert should be shown. Should return a boolean.
- **`html_attrs:`** (optional) - Additional HTML attributes to apply to the alert. Note: This has no effect on partials.

## Types of Alerts

The following types are supported:

- **`info`** - Blue alert for informational messages.
- **`success`** - Green alert for successful actions or positive feedback.
- **`danger`** - Red alert for errors or critical warnings.
- **`warning`** - Yellow alert for cautionary messages.

### Examples

#### Example 1: Basic Info Alert

```ruby
alert_box header:"Information", body:"This is an informational message.", type: :info, display_if:->(arg){arg.present?}
```

- **Screenshot:** ![image](https://github.com/user-attachments/assets/cb0c9a09-5084-4204-ae83-64ac06065cf9)
- **Screenshot:** ![image](https://github.com/user-attachments/assets/8bc1c066-03c0-4e34-8e38-217062db4579)
- **Description:** Displays an alert with a title and body text.

#### Example 2: Using Custom Body

```ruby
alert_box header:"Information", body:"This is an informational message. <br>This is a break text.", type: :info, display_if:->(arg){arg.present?}
```
- **Screenshot:** ![image](https://github.com/user-attachments/assets/5614e104-4675-49e8-a2db-034a890fd581)
- **Screenshot:** ![image](https://github.com/user-attachments/assets/41c22856-4647-4c47-ba48-d144833c2074)
- **Description:** Displays a custom body for the alert, allowing for more customized content.


#### Example 3: Using Partial

```ruby
alert_box partial:"/check/alert", display_if:->(arg){arg.present?}
```
- **Screenshot:** ![image](https://github.com/user-attachments/assets/5614e104-4675-49e8-a2db-034a890fd581)
- **Screenshot:** ![image](https://github.com/user-attachments/assets/41c22856-4647-4c47-ba48-d144833c2074)
- **Description:** Displays a custom partial for the alert, allowing for more customized HTML or content.


### Important Notes

- **Nested Sections:** Alerts cannot be placed inside nested sections. If added within a nested section, the alert will appear on the wrapped `cm_show_section`.
- **Unsupported Types:** Only the specified types (`info`, `success`, `danger`, `warning`) are supported. Any other type will default to a standard div.
