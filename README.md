# Solargraph

IDE tools for the Ruby language.

Solargraph is a set of tools to integrate Ruby code completion and inline documentation into IDEs.

## Online Demo

A web-based demonstration of Solargraph is available at http://solargraph.org/demo.

## Installation

Solargraph is available as a Ruby gem:

    gem install solargraph

## Using Solargraph

Plug-ins and extensions are available for the following editors:

* **Visual Studio Code**
    * Extension: https://marketplace.visualstudio.com/items?itemName=castwide.solargraph
    * GitHub: https://github.com/castwide/vscode-solargraph

* **Atom**
    * Package: https://atom.io/packages/ruby-solargraph
    * GitHub: https://github.com/castwide/atom-solargraph

* **Vim**
    * GitHub: https://github.com/hackhowtofaq/vim-solargraph

* **Emacs**
    * GitHub: https://github.com/guskovd/emacs-solargraph

### Gem Support

Solargraph is capable of providing code completion and documentation for gems that have YARD documentation. You can make sure your gems are documented by running `yard gems` from the command line. (The first time you run it might take a while if you have a lot of gems installed).

When editing code, a `require` call that references a gem will pull the documentation into the code maps and include the gem's API in code completion and intellisense.

### More Information

See [http://solargraph.org/tips](http://solargraph.org/tips) for more tips on using Solargraph with an editor.

## How It Works

Solargraph uses [parser](https://github.com/whitequark/parser) for code analysis and [YARD](https://github.com/lsegal/yard) for API documentation.

## Using the `solargraph` Executable

The gem includes an executable that provides access to the library's features. For code completion, IDEs will typically integrate using `solargraph stdio` or `solargraph socket`.

### Language Server Protocol

The language server protocol is the recommended way for integrating Solargraph into editors and IDEs. Clients can connect using either stdio or TCP.
See [LANGUAGE_SERVER.md](LANGUAGE_SERVER.md) for more information.

### Standalone Suggest

The suggest subcommand provides an interface to request suggestions without the need for a server. When executed, it accepts the parameters for a suggestion request, returns the suggestions in JSON format, and exits.

**Warning:** The suggest subcommand is a candidate for deprecation. It will either change drastically or not exist in a future version.

## Updating the Core Documentation

The Solargraph gem ships with documentation for Ruby 2.2.2. As of gem version 0.15.0, there's an option to download additional documentation for other Ruby versions from the command line.

    $ solargraph list-cores      # List the installed documentation versions
    $ solargraph available-cores # List the versions available for download
    $ solargraph download-core   # Install the best match for your Ruby version
    $ solargraph clear-cores     # Clear the documentation cache

## Runtime Suggestions (EXPERIMENTAL)

As of gem version 0.15.0, Solargraph includes experimental support for plugins.

The Runtime plugin enhances code completion by querying namespaces for method names in a subprocess. If it finds any undocumented or "magic" methods, they get added to the suggestions.

This feature is currently disabled by default. If you'd like to try it, you can enable it by setting the `plugins` section in your project's .solargraph.yml file:

    plugins:
    - runtime

## Known Issues

### EventMachine error with Ruby 2.4+ on Windows

There's a known issue with EventMachine that causes Solargraph to fail with the following message:

```
Unable to load the EventMachine C extension; To use the pure-ruby reactor, require 'em/pure_ruby'
```

This is due to a problem compiling the native EventMachine extension on Windows. The workaround is to install the pure Ruby version:

```
$ gem uninstall eventmachine
$ gem install eventmachine --platform ruby -- --use-system-libraries
```

More information: https://github.com/eventmachine/eventmachine/issues/820#issuecomment-368267506
