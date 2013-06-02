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


Shallow copies (easy mode)
--------------------------

You could just use [```ActiveRecord::Base#dup```](http://apidock.com/rails/ActiveRecord/Base/dup). Instead, define a copier.

```ruby
# lib/todo_copier.rb
class TodoCopier < Kopipe::Copier
  copies_attributes :name, :completed
  copies_belongs_to :author,  :deep => false
  copies_belongs_to :project, :deep => false
end
```

In your code,

```ruby
todo_copy = TodoCopier.new(Todo.find(123)).copy!
```

EZ.


Deep copies
-----------

Patience, grasshopper.
