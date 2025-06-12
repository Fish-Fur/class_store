# frozen_string_literal: true

require_relative 'class_store/version'
require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/deep_dup'

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

module ClassStore
  class DuplicateClassStoreError < StandardError; end
  class IllegalStoreTyoeError < StandardError; end

  # Class methods for registering, accessing and resetting class stores
  module Registration
    extend ActiveSupport::Concern

    included do
      class_attribute :_registered_class_stores, instance_writer: false
      self._registered_class_stores = {}
    end

    class_methods do
      # Register a class store on the class with the given name and options.
      def class_store(name, **options)
        raise ArgumentError, 'name is a required argument' if name.nil?
        if _registered_class_stores.key?(name)
          raise DuplicateClassStoreError, "Class store #{name} has already been registered"
        end

        initial_state = options.delete(:initial_state) || {}
        unless initial_state.is_a?(Hash) || initial_state.is_a?(Array)
          raise IllegalStoreTyoeError, 'initial_state must be a hash or array'
        end

        _registered_class_stores[name] = { initial_state: initial_state, options: options }
        _create_class_store(name, initial_state, options)
      end

      def inherited(subclass)
        super

        # Clone the registered class stores on the subclass
        subclass._registered_class_stores = _registered_class_stores.deep_dup

        # Ensure each subclass starts with a copy of its parent's stores
        subclass._registered_class_stores.each do |name, store_options|
          subclass._create_class_store(name, store_options[:initial_state], store_options[:options])
          subclass.send("_#{name}=", send("_#{name}").deep_dup)
        end
      end

      def _create_class_store(name, initial_state, _options)
        class_attribute :"_#{name}", instance_writer: false
        send("_#{name}=", initial_state.deep_dup)
        _generate_class_store_accessor(name)
        _generate_class_store_resetter(name)
      end

      private

      def _generate_class_store_accessor(name)
        define_singleton_method(name) do
          send("_#{name}")
        end

        define_singleton_method("#{name}=") do |value|
          send("_#{name}")[value] = value
        end

        delegate name.to_sym, to: :class
      end

      def _generate_class_store_resetter(name)
        resetter_name = "reset_#{name}"
        define_singleton_method(resetter_name) do
          send("_#{name}=", _registered_class_stores[name][:initial_state].dup)
        end

        delegate resetter_name.to_sym, to: :class
      end
    end
  end
end
