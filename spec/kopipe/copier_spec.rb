require_relative '../../lib/kopipe'
require 'kopipe/copier'

# Creates an array that responds to build and find_each, in a way similar to
# how an an ActiveRecord has-many array does.
#
# Example:
#
#   class Person < Struct.new(:name); end
#   class Brother < Person; end
#
#   people    = mock_has_many(Person).new
#
#   a_person  = people.build
#   a_brother = people.build type: 'Brother'
#   people == [a_person, a_brother]
#
def mock_has_many(type)
  Class.new(Array) do
    alias_method :find_each, :each
    define_method :build do |options = {}|
      if options[:type]
        options[:type].constantize.new.tap{ |object| push object }
      else
        type.new.tap{ |object| push object }
      end
    end
    define_method :initialize do |array|
      push(*array)
    end
  end
end

module Kopipe
  describe Copier do
    describe "#initialize" do
      before do
        stub_const "Person", Struct.new(:name)
        stub_const "PersonCopier", Class.new(Copier)
      end

      it "instantites a new source.class as the target by default" do
        source = Person.new("Mark")
        target = PersonCopier.new(source).target
        target.class.should == Person
        target.should_not equal source
      end

      it "accepts an optional target parameter which is set as the copy target" do
        target = stub

        PersonCopier.new(stub, target: target).target.should equal target
      end

      it "alternatively accepts a block which yields the target" do
        target = stub('target')

        PersonCopier.new(stub('source')){ target }.target.should == target
      end
    end

    describe ".copies" do
      it "defines a custom copier which runs a block" do
        stub_const "Person", Struct.new(:name, :age)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies { target.name = "Richard" }
          copies { target.age  = 28 }
        end)

        mark_clone = PersonCopier.new(Person.new("Mark", 27)).copy!
        mark_clone.to_a.should == ["Richard", 28]
      end
    end

    describe ".and_saves" do
      it "saves the target object at a specific time" do
        stub_const "Person", Struct.new(:name, :age)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies { target.name = "Richard" }
          and_saves
          copies { target.age  = 28 }
        end)

        mark_clone = Person.new
        mark_clone.should_receive(:save!) {
          mark_clone.to_a.should == ["Richard", nil]
        }
        PersonCopier.new(Person.new("Mark", 27), target: mark_clone).copy!
      end
    end

    describe ".copies_attributes" do
      it "copies scalar attributes" do
        stub_const "Person", Struct.new(:name, :age)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_attributes :name, :age
        end)

        mark_clone = PersonCopier.new(Person.new("Mark", 27)).copy!
        mark_clone.to_a.should == ["Mark", 27]
      end
    end

    describe ".copies_has_and_belongs_to_many" do
      before do
        stub_const "Project", Struct.new(:name, :sexiness) 
        stub_const "SexyProject", Class.new(Project) 
        stub_const "BoringProject", Class.new(Project)
        stub_const "Person", Struct.new(:projects) {
          define_method :initialize do |projects = []|
            super(projects)
            self.projects = mock_has_many(Project).new(projects)
          end
        }
      end

      it "shallowly copies a habtm relationship when :deep => false, or is unspecified" do
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_and_belongs_to_many :projects, :deep => false
        end)

        person      = Person.new([Project.new("RP 2.0")])
        person_copy = PersonCopier.new(person).copy!
        person_copy.projects.should == person.projects
        person_copy.projects.first.should equal person.projects.first
      end

      it "deeply copies a has_and_belongs_to_many relationship" do
        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_and_belongs_to_many :projects, :deep => ProjectCopier
        end)

        person      = Person.new([Project.new("RP 2.0")])
        person_copy = PersonCopier.new(person).copy!
        person_copy.projects.should == person.projects
        person_copy.projects.first.should_not equal person.projects.first
      end

      it "deeply copies a polymorphic has_and_belongs_to_many relationship" do
        stub_const "BoringProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = -1 }
        end)
        stub_const "SexyProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = 9999 }
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_and_belongs_to_many :projects, :polymorphic => true
        end)

        person = Person.new([ SexyProject.new("RP 2.0"), BoringProject.new("RP 1.6") ])
        person_copy = PersonCopier.new(person).copy!

        person_copy.projects.first.tap do |first_copy|
          first_copy.class.should == SexyProject
          first_copy.sexiness.should == 9999
        end

        person_copy.projects.last.tap do |second_copy|
          second_copy.class.should == BoringProject
          second_copy.sexiness.should == -1
        end
      end

      it "deeply copies a polymorphic has_and_belongs_to_many relationship under a namespace" do
        stub_const "PersonCopiers", Module.new
        stub_const "PersonCopiers::SexyProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = 9999 }
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_and_belongs_to_many :projects, :polymorphic => true, :namespace => PersonCopiers
        end)

        person = Person.new([ SexyProject.new("RP 2.0") ])
        person_copy = PersonCopier.new(person).copy!

        person_copy.projects.first.tap do |first_copy|
          first_copy.class.should == SexyProject
          first_copy.sexiness.should == 9999
        end
      end
    end

    describe ".copies_has_many" do
      let(:project_class) { Struct.new(:name, :sexiness) }
      let(:sexy_project_class) { Class.new(project_class) }
      let(:boring_project_class) { Class.new(project_class) }
      let(:person_class_with_has_many_projects) {
        Struct.new(:projects) {
          define_method :initialize do |projects|
            super(projects)
            self.projects = mock_has_many(Project).new(projects)
          end
        }
      }

      it "deeply copies a has-many relationship" do
        stub_const "Project", project_class
        stub_const "Person", person_class_with_has_many_projects

        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_many :projects, :deep => 'ProjectCopier'
        end)
        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)

        person = Person.new([Project.new("RP 1.6"), Project.new("RP 2.0")])
        person_copy = PersonCopier.new(person, target: Person.new([])).copy!

        person_copy.projects.map(&:name).should =~ ["RP 1.6", "RP 2.0"]
        person_copy.projects.map(&:object_id).should_not =~ person.projects.map(&:object_id)
      end

      it "copies polymorphic has-many relationships" do
        stub_const "Project", project_class
        stub_const "SexyProject", sexy_project_class
        stub_const "BoringProject", boring_project_class
        stub_const "Person", person_class_with_has_many_projects

        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_many :projects, :polymorphic => true
        end)
        stub_const "BoringProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = -1 }
        end)
        stub_const "SexyProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = 9999 }
        end)

        person = Person.new([ SexyProject.new("RP 2.0"), BoringProject.new("RP 1.6") ])
        person_copy = PersonCopier.new(person, target: Person.new([])).copy!

        person_copy.projects.first.tap do |first_copy|
          first_copy.class.should == SexyProject
          first_copy.sexiness.should == 9999
        end

        person_copy.projects.last.tap do |second_copy|
          second_copy.class.should == BoringProject
          second_copy.sexiness.should == -1
        end
      end

      it "copies polymorphic has-many relationships using copiers under a namespace" do
        stub_const "Project", project_class
        stub_const "SexyProject", sexy_project_class
        stub_const "Person", person_class_with_has_many_projects

        stub_const "PersonCopiers", Module.new
        stub_const "PersonCopiers::SexyProjectCopier", (Class.new(Copier) do
          copies { target.sexiness = 9999 }
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_has_many :projects,
            :polymorphic => true,
            :namespace => 'PersonCopiers'
        end)

        person      = Person.new([ SexyProject.new("RP 2.0") ])
        person_copy = PersonCopier.new(person, target: Person.new([])).copy!

        person_copy.projects.first.tap do |first_copy|
          first_copy.class.should == SexyProject
          first_copy.sexiness.should == 9999
        end
      end
    end

    describe ".copies_belongs_to" do
      let(:project_class) { Struct.new(:name) }
      let(:person_class_with_belongs_to_project) {
        Struct.new(:project) {
          def build_project; Project.new('a'); end
        }
      }
      let(:person_class_with_two_belongs_to_project) {
        Struct.new(:project_a, :project_b) {
          def build_project_a; Project.new('a'); end
          def build_project_b; Project.new('b'); end
        }
      }

      it "shallowly copies belongs-to relationships" do
        stub_const "Person", person_class_with_belongs_to_project
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project, :deep => false
        end)

        project       = stub('project')
        source_person = Person.new(project)

        PersonCopier.new(source_person).copy!.project.should equal project
      end

      it "deeply copies belongs-to relationships when :deep specifies a copier" do
        stub_const "Person", person_class_with_belongs_to_project
        stub_const "Project", project_class

        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project, :deep => ProjectCopier
        end)

        source_project = stub(:name => "Mark's project")
        source_person  = Person.new(source_project)
        source_person.stub(:build_project => Project.new)

        ProjectCopier.should_receive(:new).once.and_call_original

        target_person = PersonCopier.new(source_person).copy!
        target_person.project.name.should == "Mark's project"
        target_person.project.should_not equal source_project
      end

      it "allows the :deep parameter to be specified as a string" do
        stub_const "Project", project_class
        stub_const "Person", person_class_with_belongs_to_project

        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project, :deep => 'ProjectCopier'
        end)

        source_project = stub(:name => "Mark's project")
        source_person  = Person.new(source_project)

        ProjectCopier.should_receive(:new).once.and_call_original

        target_person = PersonCopier.new(source_person).copy!
        target_person.project.name.should == "Mark's project"
        target_person.project.should_not equal source_project
      end

      it "does not copy the same object twice" do
        stub_const "Project", project_class
        stub_const "Person", person_class_with_two_belongs_to_project

        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project_a, :deep => ProjectCopier
          copies_belongs_to :project_b, :deep => ProjectCopier
        end)

        source_project = Project.new
        source_person  = Person.new(source_project, source_project)

        ProjectCopier.should_receive(:new).once.and_call_original

        target_person = PersonCopier.new(source_person).copy!
        target_person.project_a.should equal target_person.project_b
      end

      it "does not copy the same object twice" do
        stub_const "Person", person_class_with_two_belongs_to_project
        stub_const "Project", project_class

        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project_a, :deep => ProjectCopier
          copies_belongs_to :project_b, :deep => ProjectCopier
        end)

        source_project = Project.new
        source_person  = Person.new(source_project, source_project)

        ProjectCopier.should_receive(:new).once.and_call_original

        target_person = PersonCopier.new(source_person).copy!
        target_person.project_a.should equal target_person.project_b
      end

      it "does not copy the same object twice, even if contradictory :deep options are specified" do
        stub_const "Person", person_class_with_two_belongs_to_project
        stub_const "Project", project_class

        stub_const "ProjectCopier", (Class.new(Copier) do
          copies_attributes :name
        end)
        stub_const "PersonCopier", (Class.new(Copier) do
          copies_belongs_to :project_a, :deep => ProjectCopier
          copies_belongs_to :project_b, :deep => false
        end)

        source_project = Project.new
        source_person  = Person.new(source_project, source_project)

        target_person = PersonCopier.new(source_person).copy!
        target_person.project_a.should equal target_person.project_b
      end
    end
  end
end
