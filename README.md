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

## How It Works

Solargraph uses [parser](https://github.com/whitequark/parser) for code analysis and [YARD](https://github.com/lsegal/yard) for API documentation.

## Using the `solargraph` Executable

The gem includes an executable that provides access to the library's features. For code completion, IDEs will typically integrate using `solargraph server` or `solargraph suggest`.

### The Server

The server subcommand runs a local web server that listens for suggestion requests.

### Standalone Suggest

The suggest subcommand provides an interface to request suggestions without the need for a server. When executed, it accepts the parameters for a suggestion request, returns the suggestions in JSON format, and exits.

**Warning:** The suggest subcommand is a candidate for deprecation. It will either change drastically or not exist in a future version.

## Integrating Solargraph into Other IDEs

Documentation for Solargraph integration is forthcoming. In the meantime, refer to the [VS Code extension](https://github.com/castwide/vscode-solargraph) source for an example.

## Updating the Core Documentation (EXPERIMENTAL)

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
