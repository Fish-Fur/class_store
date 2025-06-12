# frozen_string_literal: true

require 'spec_helper'
require 'class_store'

RSpec.describe ClassStore::Registration do
  describe '.class_store' do
    context 'when registering a default store' do
      let(:klass) do
        Class.new do
          include ClassStore::Registration

          class_store :store
        end
      end

      let(:instance) { klass.new }

      it 'creates a class store with an empty hash' do
        expect(klass.store).to be_a(Hash)
        expect(klass.store).to be_empty
      end

      it 'when a value is set it is accessible from the class' do
        klass.store['foo'] = 'bar'
        expect(klass.store['foo']).to eq('bar')
      end

      it 'when a value is set it is accessible from the instance' do
        klass.store['foo'] = 'bar'
        expect(instance.store['foo']).to eq('bar')
      end

      it 'resets the store to an empty hash' do
        klass.store['foo'] = 'bar'
        klass.reset_store
        expect(klass.store).to be_empty
        expect(instance.store).to be_empty
      end
    end

    context 'when registering Array store' do
      let(:klass) do
        Class.new do
          include ClassStore::Registration

          class_store :store, initial_state: []
        end
      end

      let(:instance) { klass.new }

      it 'creates a class store with an empty array' do
        expect(klass.store).to be_a(Array)
        expect(klass.store).to be_empty
      end

      it 'when a value is added it is accessible from the class' do
        klass.store << 'foo'
        expect(klass.store).to eq(['foo'])
      end

      it 'when a value is added it is accessible from the instance' do
        klass.store << 'foo'
        expect(instance.store).to eq(['foo'])
      end

      it 'resets the store to an empty array' do
        klass.store << 'foo'
        klass.reset_store
        expect(klass.store).to be_empty
        expect(instance.store).to be_empty
      end
    end

    context 'when registering a store with initial state' do
      let(:klass) do
        Class.new do
          include ClassStore::Registration

          class_store :store, initial_state: { foo: 'bar' }
        end
      end

      let(:instance) { klass.new }

      it 'creates a class store with the initial state' do
        expect(klass.store).to be_a(Hash)
        expect(klass.store[:foo]).to eq('bar')
      end

      it 'the initial state is accessible from the instance' do
        expect(instance.store[:foo]).to eq('bar')
      end

      it 'resets the store to the initial state' do
        klass.store[:foo] = 'baz'
        klass.reset_store
        expect(klass.store[:foo]).to eq('bar')
        expect(instance.store[:foo]).to eq('bar')
      end
    end
  end

  describe 'manipulating date in the store' do
    context 'when using the default store' do
      let(:klass) do
        Class.new do
          include ClassStore::Registration

          class_store :store
        end
      end

      let(:instance) { klass.new }

      it 'adds data to the store' do
        klass.store['key'] = 'value'
        expect(klass.store['key']).to eq('value')
        expect(instance.store['key']).to eq('value')
      end

      it 'overrides existing data in the store' do
        klass.store['key'] = 'value1'
        klass.store['key'] = 'value2'
        expect(klass.store['key']).to eq('value2')
        expect(instance.store['key']).to eq('value2')
      end

      it 'deletes data from the store' do
        klass.store['key'] = 'value'
        klass.store.delete('key')
        expect(klass.store).not_to have_key('key')
        expect(instance.store).not_to have_key('key')
      end
    end

    context 'when using an Array store' do
      let(:klass) do
        Class.new do
          include ClassStore::Registration

          class_store :store, initial_state: []
        end
      end

      let(:instance) { klass.new }

      it 'adds data to the store' do
        klass.store << 'value'
        expect(klass.store).to eq(['value'])
        expect(instance.store).to eq(['value'])
      end

      it 'deletes data from the store' do
        klass.store << 'value'
        klass.store.delete('value')
        expect(klass.store).to be_empty
        expect(instance.store).to be_empty
      end
    end
  end

  describe 'inheritance behavior' do
    let(:parent_class) do
      Class.new do
        include ClassStore::Registration

        class_store :store, initial_state: { foo: 'bar' }

        def self.add_item(key, value)
          store[key] = value
        end

        add_item :blah, 'stuff'
      end
    end

    let(:first_child_class) do
      Class.new(parent_class) do
        add_item :baz, 'qux'
      end
    end

    let(:second_child_class) do
      Class.new(parent_class) do
        add_item :quux, 'corge'
      end
    end

    it 'child data is not shared with parent class' do
      expect(parent_class.store).to eq({ foo: 'bar', blah: 'stuff' })
    end

    it 'child class inherits parent class store' do
      expect(first_child_class.store).to eq({ foo: 'bar', baz: 'qux', blah: 'stuff' })
    end

    it 'sibling class do not share data' do
      expect(second_child_class.store).to eq({ foo: 'bar', quux: 'corge', blah: 'stuff' })
    end

    context 'when manipulating data in parent classes' do
      before do
        # Ensure the parent and child classes are defined before testing
        parent_class
        first_child_class
        second_child_class
      end

      it 'adding data in parent class does not affect child classes' do
        parent_class.store[:new_item] = 'new_value'
        expect(parent_class.store).to eq({ foo: 'bar', new_item: 'new_value', blah: 'stuff' })
        expect(first_child_class.store).to eq({ foo: 'bar', baz: 'qux', blah: 'stuff' })
      end

      it 'deleting data in parent class does not affect child classes' do
        parent_class.store.delete(:foo)
        expect(parent_class.store).not_to have_key(:foo)
        expect(first_child_class.store[:foo]).to eq('bar')
      end
    end

    context 'when manipulating data in child classes' do
      before do
        # Ensure the parent and child classes are defined before testing
        parent_class
        first_child_class
        second_child_class
      end

      it 'adding data in child class does not affect parent class' do
        first_child_class.store[:new_item] = 'new_value'
        expect(first_child_class.store).to eq({ foo: 'bar', baz: 'qux', blah: 'stuff', new_item: 'new_value' })
        expect(parent_class.store).to eq({ foo: 'bar', blah: 'stuff' })
      end

      it 'deleting data in child class does not affect parent class' do
        first_child_class.store.delete(:foo)
        expect(first_child_class.store).not_to have_key(:foo)
        expect(parent_class.store[:foo]).to eq('bar')
      end
    end
  end

  describe 'error handling' do
    let(:klass) do
      Class.new do
        include ClassStore::Registration
      end
    end

    it 'raises an error when trying to register with a duplicate name' do
      expect do
        klass.class_store :store
        klass.class_store :store # Duplicate registration
      end.to raise_error(ClassStore::DuplicateClassStoreError, /Class store store has already been registered/)  
    end

    it 'raises an error when initial_state is not a hash or array' do
      expect do
        klass.class_store :store, initial_state: 'not_a_hash_or_array'
      end.to raise_error(ClassStore::IllegalStoreTyoeError, /initial_state must be a hash or array/)
    end

    it 'raises an error when name is nil' do
      expect do
        klass.class_store nil, initial_state: {}
      end.to raise_error(ArgumentError, /name is a required argument/)
    end
  end

  describe 'store holding procs' do
    let(:klass) do
      Class.new do
        include ClassStore::Registration

        class_store :store, initial_state: { proc_key: -> { 'proc_value' } }

        def self.add_item(key, value)
          store[key] = value
        end
      end
    end

    let(:child_klass) do
      Class.new(klass) do
        add_item :child_proc, -> { 'child_value' }
      end
    end

    let(:instance) { klass.new }

    it 'stores procs in the parent class store' do
      expect(klass.store[:proc_key]).to be_a(Proc)
    end

    it 'stored procs are runnable' do
      expect(klass.store[:proc_key].call).to eq('proc_value')
      expect(child_klass.store[:child_proc].call).to eq('child_value')
    end

    it 'stores procs in the child class store' do
      expect(child_klass.store[:proc_key]).to be_a(Proc)
      expect(child_klass.store[:child_proc]).to be_a(Proc)
    end

    it 'resetting the store restores init state with procs' do
      klass.store[:proc_key] = 'new_value'
      klass.reset_store
      expect(klass.store[:proc_key]).to be_a(Proc)
      expect(klass.store[:proc_key].call).to eq('proc_value')
    end
  end
end
