# frozen_string_literal: true

require 'test_helper'

class TestClassStore < Minitest::Test
  class DefaultStoreClass
    include ClassStore::Registration

    class_store :store
  end

  def test_default_store
    instance = DefaultStoreClass.new

    assert DefaultStoreClass.store.is_a?(Hash)
    assert DefaultStoreClass.store.empty?

    assert instance.store.is_a?(Hash)
    assert instance.store.empty?

    DefaultStoreClass.store['foo'] = 'bar'
    assert_equal 'bar', instance.store['foo']
    assert_equal 'bar', DefaultStoreClass.store['foo']

    DefaultStoreClass.reset_store
    assert DefaultStoreClass.store.empty?
    assert instance.store.empty?
  end

  class ArrayStoreClass
    include ClassStore::Registration

    class_store :store, initial_state: []
  end

  def test_array_store
    instance = ArrayStoreClass.new

    assert ArrayStoreClass.store.is_a?(Array)
    assert ArrayStoreClass.store.empty?

    assert instance.store.is_a?(Array)
    assert instance.store.empty?

    ArrayStoreClass.store << 'foo'
    assert_equal ['foo'], instance.store
    assert_equal ['foo'], ArrayStoreClass.store

    ArrayStoreClass.reset_store
    assert ArrayStoreClass.store.empty?
    assert instance.store.empty?
  end

  class PrefilledStoreClass
    include ClassStore::Registration

    class_store :store, initial_state: { foo: 'bar' }
  end

  def test_prefilled_store
    instance = PrefilledStoreClass.new

    assert PrefilledStoreClass.store.is_a?(Hash)
    assert_equal 'bar', PrefilledStoreClass.store[:foo]
    assert_equal 'bar', instance.store[:foo]
    assert_nil instance.store[:baz]

    instance.store[:baz] = 'qux'
    assert_equal 'qux', instance.store[:baz]
    assert_equal 'qux', PrefilledStoreClass.store[:baz]

    PrefilledStoreClass.reset_store
    assert_equal 'bar', PrefilledStoreClass.store[:foo]
    assert_equal 'bar', instance.store[:foo]
    assert_nil instance.store[:baz]
  end

  class BaseStoreClass
    include ClassStore::Registration

    class_store :store, initial_state: { foo: 'bar' }

    def self.add_item(key, value)
      store[key] = value
    end
  end

  class DerivedStoreClass1 < BaseStoreClass
    add_item :baz, 'qux'
  end

  class DerivedStoreClass2 < BaseStoreClass
    add_item :quux, 'quux'
  end

  def test_inherited_class_store
    assert_equal 'bar', BaseStoreClass.store[:foo]
    assert_nil BaseStoreClass.store[:baz]
    assert_nil BaseStoreClass.store[:quux]

    assert_equal 'bar', DerivedStoreClass1.store[:foo]
    assert_equal 'qux', DerivedStoreClass1.store[:baz]
    assert_nil DerivedStoreClass1.store[:quux]

    assert_equal 'bar', DerivedStoreClass2.store[:foo]
    assert_nil DerivedStoreClass2.store[:baz]
    assert_equal 'quux', DerivedStoreClass2.store[:quux]
  end

  class ProcBaseStoreClass
    include ClassStore::Registration

    class_store :store, initial_state: { foo: -> { 'bar' } }

    def self.add_item(key, value)
      store[key] = value
    end
  end

  class ProcDerivedStoreClass < ProcBaseStoreClass
    add_item :baz, -> { 'qux' }
  end

  def test_proc_class_store
    assert ProcBaseStoreClass.store[:foo].is_a?(Proc)
    assert ProcDerivedStoreClass.store[:foo].is_a?(Proc)
    assert ProcDerivedStoreClass.store[:baz].is_a?(Proc)
  end

  class ResetingBaseStoreClass
    include ClassStore::Registration

    class_store :store, initial_state: { foo: 'bar' }

    def self.add_item(key, value)
      store[key] = value
    end
  end

  class ResetingDerivedStoreClass1 < ResetingBaseStoreClass
    add_item :baz, 'qux'
  end

  class ResetingDerivedStoreClass2 < ResetingDerivedStoreClass1
    add_item :quux, 'quux'
  end

  def test_reset_class_store
    assert_equal 'bar', ResetingBaseStoreClass.store[:foo]
    assert_nil ResetingBaseStoreClass.store[:baz]
    assert_nil ResetingBaseStoreClass.store[:quux]

    assert_equal 'bar', ResetingDerivedStoreClass1.store[:foo]
    assert_equal 'qux', ResetingDerivedStoreClass1.store[:baz]
    assert_nil ResetingDerivedStoreClass1.store[:quux]

    assert_equal 'bar', ResetingDerivedStoreClass2.store[:foo]
    assert_equal 'qux', ResetingDerivedStoreClass2.store[:baz]
    assert_equal 'quux', ResetingDerivedStoreClass2.store[:quux]

    ResetingDerivedStoreClass1.reset_store

    assert_equal 'bar', ResetingBaseStoreClass.store[:foo]
    assert_nil ResetingBaseStoreClass.store[:baz]
    assert_nil ResetingBaseStoreClass.store[:quux]

    assert_equal 'bar', ResetingDerivedStoreClass1.store[:foo]
    assert_nil ResetingDerivedStoreClass1.store[:baz]
    assert_nil ResetingDerivedStoreClass1.store[:quux]

    assert_equal 'bar', ResetingDerivedStoreClass2.store[:foo]
    assert_equal 'qux', ResetingDerivedStoreClass2.store[:baz]
    assert_equal 'quux', ResetingDerivedStoreClass2.store[:quux]
  end
end
