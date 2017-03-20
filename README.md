# Solargraph

IDE tools for the Ruby language.

_This library is still in early development._

Solargraph is a set of tools to integrate Ruby code completion and inline documentation into IDEs. The first supported IDE is Visual Studio Code.

## Installation

Solargraph is available as a Ruby gem:

    gem install solargraph

To use it with Visual Studio Code, install the [Solargraph extension](https://marketplace.visualstudio.com/items?itemName=castwide.solargraph).

## How It Works

Solargraph uses [parser](https://github.com/whitequark/parser) for code analysis and [YARD](https://github.com/lsegal/yard) for API documentation.

## Using the Solargraph Executable

The gem includes an executable that provides access to the library's features. For code completion, IDEs will typically integrate using solargraph serve or solargraph suggest.

### The Server

The server subcommand runs a local web server that listens for suggestion requests.

### Standalone Suggest

The suggest subcommand provides an interface to request suggestions without the need for a server. When executed, it accepts the parameters for a suggestion request, returns the suggestions in JSON format, and exits.

## Integrating Solargraph into Other IDEs

Documentation for Solargraph integration is forthcoming. In the meantime, refer to the [VS Code extension](https://github.com/castwide/vscode-solargraph) source for an example.
