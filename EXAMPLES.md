# Code Examples

This document provides simple examples of how to use the Solargraph library. The examples are intended as a starting point for developers who want to modify or extend the library, or integrate its tools into other software.

Language client implementors who want to connect to Solargraph language servers should refer to [LANGUAGE_SERVER.md](LANGUAGE_SERVER.md).

## Querying Ruby Core Methods

```Ruby
api_map = Solargraph::ApiMap.new
pins = api_map.get_methods('String') # Get public instance methods of the String class
```

## Adding a File to an ApiMap

```Ruby
api_map = Solargraph::ApiMap.new
source = Solargraph::Source.load_string('class MyClass; end', 'my_class.rb')
api_map.map source # Add the source to the map
pins = api_map.get_constants('') # The constants in the global namespace will include `MyClass`
```

## Adding a Workspace to an ApiMap

```Ruby
api_map = Solargraph::ApiMap.load('/path/to/workspace')
pins = api_map.get_constants('') # Results will include constants defined in the project's code
```

## Querying Definitions from a Location in Source Code

```Ruby
api_map = Solargraph::ApiMap.new
source = Solargraph::Source.load_string("var = 'a string'; puts var", 'example.rb')
api_map.virtualize source
clip = api_map.clip_at('example.rb', Solargraph::Position.new(0, 23))
pins = clip.define # `var` is recognized as a local variable containing a String
```

## Querying Completion Suggestions
```Ruby
api_map = Solargraph::ApiMap.new
source = Solargraph::Source.load_string("String.", 'example.rb')
api_map.map source
clip = api_map.clip_at('example.rb', Solargraph::Position.new(0, 7))
completion = clip.complete # Suggestions will include String class methods
```

## Adding a Message to the Language Server Protocol

```Ruby
class MyMessage < Solargraph::LanguageServer::Message::Base
  def process
    STDERR.puts "Server received MyMessage with the following parameters: #{params}"
  end
end

Solargraph::LanguageServer::Message.register '$/myMessage', MyMessage
```

## Adding a Diagnostics Reporter to the Language Server

```Ruby
class MyReporter < Solargraph::Diagnostics::Base
  def diagnose source, api_map
    # Return an array of hash objects that conform to the LSP's Diagnostic specification
    []
  end
end

Solargraph::Diagnostics.register 'my_reporter', MyReporter
```

## More Examples

Developers are encouraged to refer to the specs for more examples of how to use Solargraph.
