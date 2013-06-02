require_relative '../../lib/kopipe/copier_database'

module Kopipe
  describe CopierDatabase do
    let(:db) { CopierDatabase.new }

    before {
      stub_const "Foo", Struct.new(:id, :name)
      stub_const "FooCopier", Struct.new(:source, :target)
    }

    it "stores source objects" do
      source_foo = Foo.new(1, "Source")
      target_foo = Foo.new(nil, "Target")
      foo_copier = FooCopier.new(source_foo, target_foo)

      db.add(foo_copier)
      db.should have_source(source_foo)
      db.should_not have_source(target_foo)
    end

    it "can be instantiated with a default hash of source => target objects" do
      source_foo = Foo.new(1, "Source")
      target_foo = Foo.new(nil, "Target")
      foo_copier = FooCopier.new(source_foo, target_foo)

      db = CopierDatabase.new({ source_foo => target_foo })
      db.should have_source(source_foo)
    end

    it "fetches targets by delegating to Hash#fetch" do
      source_foo = Foo.new(1, "Source")
      target_foo = Foo.new(nil, "Target")
      foo_copier = FooCopier.new(source_foo, target_foo)

      hash = { source_foo => target_foo }
      hash.should_receive(:fetch).with(source_foo).and_call_original

      CopierDatabase.new(hash).fetch_target_by_source(source_foo).should == target_foo
    end

    it "also passes along the block to #fetch" do
      db.fetch_target_by_source(123){ 234 }.should == 234
    end

    it "can be fetched with a block" do
      source_foo = Foo.new(1, "Source")
      target_foo = Foo.new(nil, "Target")
      foo_copier = FooCopier.new(source_foo, target_foo)

      db.add(foo_copier)
      db.fetch_target_by_source(source_foo).should == target_foo
    end
  end
end
