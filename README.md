# Rails load-hook guard reproducer

This application demonstrates a blind spot in the load-hook guard added by
[rails/rails#56201](https://github.com/rails/rails/pull/56201). A gem that is
automatically required from the Gemfile can load a guarded Rails component
before the application exists. The current guard discards that event, so the
application boots even when `config.action_on_early_load_hook` is set to
`:raise`.

The application was generated from the Rails `main` branch. `Gemfile.lock`
pins the exact Rails revision used by this reproducer.

## Run the reproduction

Install Ruby 4.0.6, then run:

```console
bundle install
bin/rails runner 'puts "Rails: #{Rails.version}"; puts "action_on_early_load_hook: #{Rails.configuration.action_on_early_load_hook}"; puts "Rails.application was nil when gem loaded: #{EarlyActiveModelLoader::RAILS_APPLICATION_WAS_NIL_WHEN_LOADED}"; puts "ActiveModel::Model loaded by gem: #{EarlyActiveModelLoader::Model.ancestors.include?(ActiveModel::Model)}"; puts "Boot completed without LoadError."'
```

Expected output (the Rails version may change if the lockfile is updated):

```text
Rails: 8.2.0.alpha
action_on_early_load_hook: raise
Rails.application was nil when gem loaded: true
ActiveModel::Model loaded by gem: true
Boot completed without LoadError.
```

The final line and a successful exit status are the reproduction: the guarded
`:active_model` hook ran before application initialization, but `:raise` did
not produce a `LoadError`.

## Why the event is missed

The generated `config/application.rb` keeps the standard boot order:

```ruby
require "rails/all"

Bundler.require(*Rails.groups)

module RailsSampleFor56201
  class Application < Rails::Application
    config.action_on_early_load_hook = :raise
  end
end
```

`early_active_model_loader` is a local path gem listed normally in the
Gemfile, without `require: false`. Bundler therefore requires it before the
`Rails::Application` subclass is defined. The gem includes
`ActiveModel::Model`, which runs the guarded `:active_model` load hook, and
records that `Rails.application` was `nil` at that moment.

The current guard only acts when `Rails.application` is truthy. Because no
application exists during `Bundler.require`, the hook event is neither raised
nor retained for later reporting. The application class then enables `:raise`,
but the relevant event has already been lost.

The local gem uses Active Model rather than Active Record so database adapter
initialization does not introduce a separate guarded hook and obscure the
behavior being demonstrated.

## Verify the application

The generated test suite should also boot successfully:

```console
bin/rails test
```

The first commit contains the untouched `rails new` output. To inspect only
the reproducer-specific changes, compare it with the current branch:

```console
git diff 932a9ab..HEAD
```
