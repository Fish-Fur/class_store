# ClassStore

ClassStore provides a simple way to store data in arrays and hashes at a class level. Unlike class variables, changes made on a subclass are not replicated in their base class, and unlike class instance variables the contents of a base class are replicated in it's subclasses.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add class_store

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install class_store

## Usage

By default the data is stored in a Hash:

```ruby
class MyClass
  include ClassStore

  class_store :data
end

MyClass.data[:foo] = 'bar'
MyClass.data[:foo] # => 'bar'
```

Alternatively, the data can be stored in an Array:

```ruby
class MyArrayStore
  include ClassStore

  class_store :data, inital_state: []
end

MyArrayStore.data << 'foo'
MyArrayStore.data # => ['foo']
```

Derived classes inherit the data from their base class and can add there own. The data added in the derived class is not replicated in the base class:

```ruby
class MyClass
  include ClassStore

  class_store :data

    def self.add_data(key, value)
      data[key] = value
    end

    add_data(:foo, 'bar')
end

class MySubClass < MyClass
  add_data(:baz, 'qux')
end

MyClass.data # => {:foo => 'bar'}
MySubClass.data # => {:foo => 'bar', :baz => 'qux'}
```

Calls to a stores reset method will reset the data in that class alone. It will not alter the base class of a derived class, and, if called on a base class will not propagate to it's subclasses:

```ruby
MyClass.reset_data
MyClass.data # => {}
MySubClass.data # => {:baz => 'qux'}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/class_store. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/class_store/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ClassStore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/class_store/blob/main/CODE_OF_CONDUCT.md).
