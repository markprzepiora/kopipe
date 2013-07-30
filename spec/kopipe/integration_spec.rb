require 'spec_helper'

describe Kopipe::Copier do
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
      t.integer  "suggested_by_id"
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

  it "performs a shallow copy of a todo" do
    stub_const "TodoCopier", (Class.new(Kopipe::Copier) do
      copies { target.name = "#{source.name} copy" }
      copies_attributes :completed 
      copies_belongs_to :author, :deep => false
      and_saves
    end)

    user      = User.create! email: 'mark@example.com'
    todo      = Todo.create! name: "Get groceries", completed: true, author: user
    todo_copy = TodoCopier.new(todo).copy!

    todo_copy.name.should == "Get groceries copy"
    todo_copy.completed.should == true
    todo_copy.author.should == user
  end

  it "performs a deep copy of a project, testing various copying options" do
    stub_const "ProjectCopier", (Class.new(Kopipe::Copier) do
      copies_attributes :name
      copies_belongs_to :owner,                   :deep => 'UserCopier'
      copies_has_many :todos,                     :deep => 'TodoCopier'
      copies_has_and_belongs_to_many :developers, :deep => false
      and_saves
    end)
    stub_const "TodoCopier", (Class.new(Kopipe::Copier) do
      copies_attributes :name, :completed
      copies_belongs_to :author,  :deep => false
      copies_belongs_to :project, :deep => false
      and_saves_without_validations
    end)
    stub_const "UserCopier", (Class.new(Kopipe::Copier) do
      copies { target.email = "example-user@example.com" }
    end)

    owner     = User.create! email: 'alice@example.com'
    developer = User.create! email: 'bob@example.com'
    project   = Project.create! name: "June 2013 Sprint", owner: owner, developers: [owner, developer]
    todo_1    = Todo.create! project: project, name: "Rails work", :author => owner
    todo_2    = Todo.create! project: project, name: "Ember work", :author => developer

    # Copy the project and fetch references to its relations.
    project_copy = ProjectCopier.new(project).copy!
    owner_copy   = project_copy.owner
    todo_1_copy  = project_copy.todos.find_by_name 'Rails work'
    todo_2_copy  = project_copy.todos.find_by_name 'Ember work'

    # The copy should have been saved successfully.
    project_copy.should be_persisted

    # The new owner of the project should be different from the original one.
    owner_copy.should be
    owner_copy.id.should_not == owner.id
    owner_copy.email.should == 'example-user@example.com'

    # On the other hand, the developer should not have been copied, and should
    # be included in the developers list along with the owner copy.
    project_copy.developers.to_a.should =~ [owner_copy, developer]

    # The todos of the project's copy should be different than those of the original.
    project_copy.todos.should_not =~ project.todos

    # And they should both exist
    todo_1_copy.should be
    todo_2_copy.should be

    # The author of the first todo should be the owner's copy.
    todo_1_copy.author.should == owner_copy

    # The author of the second todo should be unchanged.
    todo_2_copy.author.should == developer
  end

  it "appends but not overwrites existing has_many relations when copying into an explicit project" do
    stub_const "ProjectCopier", (Class.new(Kopipe::Copier) do
      copies_has_many :todos, :deep => 'TodoCopier'
      and_saves
    end)
    stub_const "TodoCopier", (Class.new(Kopipe::Copier) do
      copies_attributes :name, :completed
    end)

    # Create the source project.
    project      = Project.create! name: "June 2013 Sprint"
    project_todo = Todo.create! project: project, name: "Rails work"

    # Create an explicit target project into which the copy will be performed,
    # an existing todo.
    another_project = Project.create! name: "Another project"
    another_project_todo = Todo.create! project: another_project, name: "Ember work"

    project_copy = ProjectCopier.new(project, target: another_project).copy!
    project_copy.todos.map(&:name).should =~ ["Rails work", "Ember work"]
  end

  it "performs a deep copy of a has-many relation with single-table inheritance" do
    # Create two subclasses of Todo to test copying of relations that involve
    # the user of Single-Table Inheritance.
    stub_const "Bug", Class.new(Todo)
    stub_const "NewFeature", (Class.new(Todo) do
      belongs_to :suggested_by, :class_name => 'User'
    end)

    stub_const "ProjectCopier", (Class.new(Kopipe::Copier) do
      copies_has_many :todos, :polymorphic => true
      and_saves
    end)

    # The base TodoCopier copies the name and project of the todo
    stub_const "TodoCopier", (Class.new(Kopipe::Copier) do
      copies_attributes :name, :completed
      copies_belongs_to :project, :deep => false
    end)
    stub_const "BugCopier", Class.new(TodoCopier)

    # The NewFeatureCopier also copies the suggested_by relation.
    stub_const "NewFeatureCopier", (Class.new(TodoCopier) do
      copies_belongs_to :suggested_by, :deep => false
    end)

    owner       = User.create! email: 'alice@example.com'
    project     = Project.create! name: "June 2013 Sprint"
    bug         = Bug.create! project: project, name: "Terrible bug"
    new_feature = NewFeature.create! project: project, name: "A wonderful new feature", :suggested_by => owner

    project_copy = ProjectCopier.new(project).copy!

    bug_copy         = project_copy.todos.find_by_name 'Terrible bug'
    new_feature_copy = project_copy.todos.find_by_name 'A wonderful new feature'

    bug_copy.class.should == Bug
    new_feature_copy.class.should == NewFeature
    new_feature_copy.suggested_by.should == owner
  end
end
