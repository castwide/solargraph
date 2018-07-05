# Language Server Protocol

Solargraph supports the language server protocol as of gem version 0.18.0. The VSCode extension uses LSP as of extension version 0.14.0.

## Using the Language Server

Run `solargraph stdio` to use the language server via stdio.

Run `solargraph socket` to use the language server via TCP socket. The default port is 7658.

## Supported Capabilities

* Hover
* Completion
* Signature help
* Definition
* Document symbols
* Workspace symbols
* Rename symbols
* References
* Formatting
* Diagnostics (linting)

## Work in Progress

* On type formatting

## Custom Features

Solargraph's language server extends the protocol with additional methods for inline document pages.

## Linting and Formatting

Solargraph uses RuboCop for linting and formatting.

## Diagnostics Reporters

A .solargraph.yml file can be used to select which diagnostics reporters Solargraph should use. The currently supported reporters are
`rubocop` and `require_not_found`. Example:

```
reporters:
- rubocop
- require_not_found
```

`rubocop` enables RuboCop linting. Its rules can be configured in a .rubocop.yml file.

`require_not_found` highlights `require` calls where Solargraph could not resolve a required path. Note that this error does not
necessarily mean that the path is incorrect; only that Solargraph was unable to recognize it.
