# frozen_string_literal: true
require 'active_support/concern'
require 'active_support/lazy_load_hooks'

require_relative "counter_one/version"
require 'counter_one/extensions'
require 'counter_one/counter'

module CounterOne
  class Error < StandardError; end
  
  # def self.config
  #   yield(self) if block_given?
  #   self
  # end
end

# extend ActiveRecord with our own code here
ActiveSupport.on_load(:active_record) do
  include CounterOne::Extensions
end
