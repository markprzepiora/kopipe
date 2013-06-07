require 'spec_helper'

module SomeModule
end

describe "A blog post" do
  with_model :User do
    table do |t|
      t.string "email"
    end

    model do
      has_many :projects_as_owner,
               :class_name => 'Project',
               :foreign_key => :owner_id,
               :inverse_of => :owner

      has_many :authored_todos,
               :foreign_key => :author_id,
               :inverse_of => :author,
               :class_name => 'Todo'

      has_and_belongs_to_many :projects_as_developer,
                              :class_name => 'Project',
                              :join_table => 'project_developers'
      
    end
  end

  with_model :Project do
    table do |t|
      t.string   "name"
      t.integer  "owner_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    model do
      belongs_to :owner,
                 :class_name => 'User',
                 :inverse_of => :projects_as_owner

      has_many :todos,
               :inverse_of => :project

      has_and_belongs_to_many :developers,
                              :class_name => 'User',
                              :join_table => 'project_developers'
    end
  end

  with_table "project_developers", :id => false do |t|
    t.integer "user_id",    :null => false
    t.integer "project_id", :null => false
  end

  with_model :Todo do
    table do |t|
      t.string   "name"
      t.string   "type"
      t.boolean  "completed"
      t.integer  "author_id"
      t.integer  "project_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    model do
      belongs_to :project,
                 :inverse_of => :todos

      belongs_to :author,
                 :inverse_of => :authored_todos,
                 :class_name => 'User'
    end
  end

  it "performs a shallow copy of todos" do
    stub_const "TodoCopier", (Class.new(Kopipe::Copier) do
      copies_attributes :name, :completed 
      and_saves
    end)

    todo      = Todo.create! name: "Get groceries", completed: true
    todo_copy = TodoCopier.new(todo).copy!

    todo_copy.name.should == "Get groceries"
    todo_copy.completed.should == true
  end
end
