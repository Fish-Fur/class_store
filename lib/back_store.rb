# frozen_string_literal: true

require_relative 'back_store/version'
require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute'

# module ClassStorage
#   extend ActiveSupport::Concern
#
#   included do
#     class_attribute :_storage, instance_accessor: false, instance_predicate: false
#     self._storage = {}
#   end
#
#   class_methods do
#     def inherited(subclass)
#       super
#       # Ensure each subclass starts with a copy of its parent's storage
#       subclass._storage = _storage.deep_dup
#     end
#
#     def set(key, value)
#       _storage[key] = value
#     end
#
#     def get(key)
#       _storage[key]
#     end
#   end
# end

# def deep_dup_with_procs(obj)
#   case obj
#   when Hash
#     obj.each_with_object({}) do |(k, v), new_hash|
#       new_hash[deep_dup_with_procs(k)] = deep_dup_with_procs(v)
#     end
#   when Array
#     obj.map { |e| deep_dup_with_procs(e) }
#   else
#     obj.duplicable? ? obj.dup : obj
#   end
# end

module BackStore
  class DuplicateBackStoreError < StandardError; end
  class IllegalStoreTyoeError < StandardError; end

  # Class methods for registering, accessing and resetting back stores
  module Registration
    extend ActiveSupport::Concern

    included do
      class_attribute :_registered_back_stores, instance_writer: false, default: {}
    end

    class_methods do
      # Register a back store on the class with the given name and options.
      def back_store(name, **options)
        raise ArgumentError, 'name is a required argument' if name.nil?
        if _registered_back_stores.key?(name)
          raise DuplicateBackStoreError, "Back store #{name} has already been registered"
        end

        unless inital_state.is_a?(Hash) || inital_state.is_a?(Array)
          raise IllegalStoreTyoeError, 'initial_state must be a hash or array'
        end

        _registered_back_stores[name] = { initial_state: inital_state, options: options }
        _create_back_store(name, inital_state, options)
      end

      def inherited(subclass)
        super

        # Clone the registered back stores on the subclass
        subclass._registered_back_stores = _registered_back_stores.deep_dup

        # Ensure each subclass starts with a copy of its parent's stores
        subclass._registered_back_stores.each do |name, store_options|
          subclass._create_back_store(name, store_options[:initial_state], store_options[:options])
          subclass.send("_#{name}=", send("_#{name}").deep_dup)
        end
      end

      private

      def _create_back_store(name, initial_state, _options)
        class_attribute :"_#{name}", instance_writer: false, default: initial_state.dup
        _generate_back_store_accessor(name)
        _generate_back_store_resetter(name)
      end

      def _generate_back_store_accessor(name)
        define_singleton_method(name) do
          send("_#{name}")
        end

        define_singleton_method("#{name}=") do |value|
          send("_#{name}")[value] = value
        end

        delegate name.to_sym, to: :class
      end

      def _generate_back_store_resetter(name)
        resetter_name = "reset_#{name}"
        define_singleton_method(resetter_name) do
          send("_#{name}=", _registered_back_stores[name][:initial_state].dup)
        end

        delegate resetter_name.to_sym, to: :class
      end
    end
  end
end
