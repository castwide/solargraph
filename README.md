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

## Updating Core Documentation

The Solargraph gem ships with documentation for Ruby 2.2.2. As of gem version 0.15.0, there's an option to download additional documentation for other Ruby versions from the command line.

    $ solargraph list-cores      # List the installed documentation versions
    $ solargraph available-cores # List the versions available for download
    $ solargraph download-core   # Install the best match for your Ruby version
    $ solargraph clear-cores     # Clear the documentation cache

## Solargraph and Bundler

If you're using the Solargraph language server with a project that uses Bundler, the most comprehensive way to use your bundled gems is to bundle Solargraph.

In the Gemfile:

    gem 'solargraph', group: :development

Run `bundle install` and use `bundle exec yard gems` to generate the documentation. This process documents cached or vendored gems, or even gems that are installed from a local path.

In order to access the gems in your project, you'll need to start the language server with Bundler. In VS Code, there's a `solargraph.useBundler` option. Other clients will vary, but the command you probably want to run is `bundle exec solargraph socket` or `bundle exec solargraph stdio`.

## Contributing to Solargraph

### Bug Reports and Feature Requests

GitHub Issues are the best place to ask questions, report problems, and suggest improvements.

### Development

Code contributions are always appreciated. Feel free to fork the repo and submit pull requests. Check for open issues that could use help. Start new issues to discuss changes that have a major impact on the code or require large time commitments.

### Sponsorship and Donation

Use Patreon to support ongoing development of Solargraph at [https://www.patreon.com/castwide](https://www.patreon.com/castwide).

You can also make one-time donations via PayPal at [https://www.paypal.me/castwide](https://www.paypal.me/castwide).
