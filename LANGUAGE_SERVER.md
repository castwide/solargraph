# Language Server Protocol

Solargraph supports the language server protocol as of gem version 0.18.0. The VSCode extension uses LSP as of extension version 0.14.0.

## Using the Language Server

Run `solargraph socket` to use the language server over a TCP socket. The default port is 7658.

## Supported Capabilities

* Hover
* Completion
* Signature help
* Definition
* Document symbols
* Workspace symbols
* Formatting
* Diagnostics (linting)

## Custom Features

Solargraph's language server extends the protocol with additional methods for inline document pages.

## Linting and Formatting

Solargraph uses RuboCop for linting and formatting.

## Work in Progress

* On type formatting
* References
* Rename symbols
