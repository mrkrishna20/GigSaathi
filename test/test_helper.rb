ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 2)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      ActionController::Base.cache_store.clear
    end

    def with_method_stub(object, method_name, replacement)
      method_owner = object.singleton_class
      original_name = :"__test_original_#{method_name}_#{object.object_id}"
      method_owner.alias_method(original_name, method_name)
      method_owner.define_method(method_name) do |*arguments, **keywords, &block|
        replacement.call(*arguments, **keywords, &block)
      end

      yield
    ensure
      if method_owner&.method_defined?(original_name)
        method_owner.alias_method(method_name, original_name)
        method_owner.remove_method(original_name)
      end
    end
  end
end
