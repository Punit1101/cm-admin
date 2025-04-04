# CmAdmin

An admin gem for Ruby on Rails application. Get your admin panel setup running quickly.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cm-admin'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cm-admin

## Usage

Install the gem

    $ rails g cm_admin:install

## Documentation

You can find more detailed documentation [here](https://docs.cm-admin.commutatus.com/)

## Demo

For demo check [here](http://cm-admin.labs.commutatus.com)
For demo repo check [here](https://github.com/commutatus/cm-admin-panel-demo)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Any markdown and ruby file added in `docs/` folder will be auto added in yard docs.

## Deployment

To release a new version of the Gem you can use Github Actions.

Go to Actions tab in your repository and click on `Bump Gem` workflow.
You will see `Run workflow` button click on it and choose `Bump Type`, then click `Run Workflow` and it will bump the version of the gem and push the changes to the repository.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/commutatus/cm-admin).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
