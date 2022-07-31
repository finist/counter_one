# CounterOne

Improved counter cache for Rails app with support various relationships and conditions.

## Features
- Updates the counter cache for create, destroy, and update actions, as well as any single action
- Counter caches for multi levels and has_one/has_many through relations
- Conditions for counter caches
- Recalculating counter caches with conditions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'counter_one'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install counter_one

## Usage

### Counter cache for simple relation

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
  counter_one :user
end
```

It will be keep up to date products_count for users when product is created or destroyed.

### Counter cache for multi levels relation

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
end

class Comment < ActiveRecord::Base
  belongs_to :product
  counter_one [:product, :user]
end
```

It will be keep up to date comments_count for users when comment is created or destroyed.

### Counter cache for has_one through relation

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
end

class Comment < ActiveRecord::Base
  belongs_to :product
  has_one :user, through: :product

  counter_one :user
end
```

### Counter cache with custom counter field

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
  counter_one :user, column: :custom_counter
end
```

### Counter cache with conditions

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
  counter_one :user, column: :active_products, only: ->(product) { product.active? }
end
```

### Counter cache only for deleted records

```ruby
class User < ActiveRecord::Base
  has_many :products
end

class Product < ActiveRecord::Base
  belongs_to :user
  counter_one :user, column: :deleted_products, on: [:destroy]
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CounterOne project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/counter_one/blob/master/CODE_OF_CONDUCT.md).
