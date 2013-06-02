kopipe
======

Kopipe (コピペ), pronounced as in (CopyPa)ste.

Dead simple ActiveRecord object copying for ActiveRecord >= 3.2 and Ruby 2.0.

Setup
-----

Add it to your Gemfile,

```ruby
gem 'kopipe', github: 'markprzepiora/kopipe'
```

and ```bundle install```.


Shallow copies (grasshopper mode)
---------------------------------

"Sensei, I can use [```ActiveRecord::Base#dup```](http://apidock.com/rails/ActiveRecord/Base/dup)!"

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


Deep copies
-----------

"My customer wants to clone one of her projects, together with its todos!"

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
  copies_belongs_to :project, :deep => 'TodoCopier'
end
```

Copy it with one fell swoop.

```ruby
project      = Project.find(1)
project_copy = ProjectCopier.new(project).copy!
```

"Whoa."
