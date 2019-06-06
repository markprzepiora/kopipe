kopipe [![Build Status](https://travis-ci.org/markprzepiora/kopipe.png?branch=master)](https://travis-ci.org/markprzepiora/kopipe)
======

Kopipe (コピペ), pronounced as in (CopyPa)ste.

Dead simple ActiveRecord object copying for ActiveRecord 4.0+ and Ruby 2.0+.

Kopipe is in version 0.0.1.alpha, so neither expect this README to be accurate nor for the interface not to change.


Setup
-----

Add it to your Gemfile with,

```ruby
gem 'kopipe', github: 'markprzepiora/kopipe'
```

and run `bundle install`.


Shallow copies (grasshopper mode)
---------------------------------

"Sensei, I can use [`ActiveRecord::Base#dup`](http://apidock.com/rails/ActiveRecord/Base/dup)!"

Instead, define a copier.

```ruby
# lib/todo_copier.rb
class TodoCopier < Kopipe::Copier
  # Copy simple attributes.
  copies_attributes :name, :completed

  # ":deep => false" instructs Kopipe to copy only the original references.
  copies_belongs_to :author,  :deep => false
  copies_belongs_to :project, :deep => false

  # Save when we're done.
  and_saves
end
```

In your code,

```ruby
todo      = Todo.find(1)
todo_copy = TodoCopier.new(todo).copy!
```

The student shrugged, unimpressed.


Deep copies
-----------

Later that day the student panicked. "My customer wants to clone one of her projects, together with its todos!"

I got you covered, grasshopper.

```ruby
# lib/project_copier.rb
class ProjectCopier < Kopipe::Copier
  # You know how to do this already.
  copies_attributes :name
  copies_belongs_to :owner,                   :deep => false
  copies_has_and_belongs_to_many :developers, :deep => false

  # Perform a deep copy of the todos, using TodoCopier to copy each one.
  copies_has_many :todos,                     :deep => 'TodoCopier'

  # If you want to end up with a built but not-yet persisted record, you
  # can omit this.
  and_saves
end

# lib/todo_copier.rb
class TodoCopier < Kopipe::Copier
  copies_attributes :name, :completed
  copies_belongs_to :author,  :deep => false

  # Kopipe is smart enough not to endlessly copy projects and todos.
  copies_belongs_to :project, :deep => 'ProjectCopier'
end
```

Copy it with one fell swoop.

```ruby
project      = Project.find(1)
project_copy = ProjectCopier.new(project).copy!
```

"Whoa."


But that's not all
------------------

### Single-table inheritance #########

"Sensei, I have many todos, but while some are a `Todo`, others are a `Bug < Todo`, or a `Feature < Todo`."

Worry not, I will not judge you.

```ruby
class ProjectCopier < Kopipe::Copier
  copies_has_many :todos, :polymorphic => true, :namespace => 'TodoCopiers'
end

module TodoCopiers
  class TodoCopier < Kopipe::Copier
    copies_attributes :name, :completed
  end
  
  class BugCopier < TodoCopier
    copies_belongs_to :reported_by,  :deep => false
  end
  
  class FeatureCopier < TodoCopier
    copies_belongs_to :suggested_by, :deep => false
  end
end
```


To-Dos
------

### Faster copying ###################

Depending on the number of validations/etc, Kopipe can be quite slow at copying
large numbers of records, since it goes through ActiveRecord (which itself is
slow at creating lots of records).

How slow?

```ruby
require 'benchmark'

project = Project.create
500.times { project.todos.create }

puts Benchmark.measure {
  project_copier = ProjectCopier.new(project)
  project_copy   = project_copier.copy!
}
# >>   4.540000   0.140000   4.680000 (  6.417537)
```

The technical term for this is "Ouch".

We might try using
[activerecord-import](https://github.com/zdennis/activerecord-import) to insert
records instead, which promises to be much faster. This has a few challenges
associated with it. (The leaves of the relationship chain would have to be
copied first, and copying self-referential models would be tricky.)

But, it has to be done!
