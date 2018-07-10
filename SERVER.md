# Solargraph Server Documentation

**NOTE: The legacy web server is deprecated and no longer available as of gem version 0.21.0. This document is archived for the benefit of extensions and plugins that still use it. Client implementors should use the [language server protocol](LANGUAGE_SERVER.md) instead.**

## Running the Server

Use the following command to start the server:

```
solargraph server
```

The command accepts an optional `--port` setting. The default port is 7657. If you set the port to 0, the server will select the first available port.

## API Endpoints

### POST /suggest

Get an array of suggestions to complete the code at the specified line and column of a file.

**Parameters:**
- `text` - the contents of the file
- `filename` - the absolute path to the file
- `line` - the zero-based line position of the cursor
- `column` - the zero-based column position of the cursor
- `workspace` - (optional) the root directory of the project
- `with_all` - (optional) request verbose suggestions

If `with_all` is set to 1, the suggestions will include documentation. The default is 0.

### POST /define

Get an array of suggestions that point to definitions for the symbol at the
specified location in the file. This method supports classes, modules, method
definitions, and variable assignments. The suggestions have a `location`
property that identifies the definition's file, line, and column.

**Parameters:**
- `text` - the contents of the file
- `filename` - the absolute path to the file
- `line` - the zero-based line position of the cursor
- `column` - the zero-based column position of the cursor
- `workspace` - (optional) the root directory of the project

### POST /resolve

**Parameters:**
- `filename` - the absolute path to the file
- `path` - the code path to find (e.g., `String#upcase`)
- `workspace` - (optional) the root directory of the project

### POST /signify

**Parameters:**
- `text` - the contents of the file
- `filename` - the absolute path to the file
- `line` - the zero-based line position of the cursor
- `column` - the zero-based column position of the cursor
- `workspace` - (optional) the root directory of the project

### GET /search

Request an HTML page containing search results for the specified text.
A search for "str" will include the String class in the results.

**Parameters:**
- `query` - the text to find
- `workspace` - (optional) the root directory of the project

### GET /document

Request an HTML page containing documentation for the specified path. A path
can be a class or module name, a class method (e.g., `Object.superclass`), or
an instance method (e.g., `String#upcase`). Documentation will also be
generated for the current workspace.

**Parameters:**
- `path` - the code path to find
- `workspace` - (optional) the root directory of the project

### POST /prepare

Initialize an ApiMap for the specified workspace. This method can make
subsequent requests for suggestions significantly faster.

**Parameters:**
- `workspace` - the root directory of the project

### POST /update

Update a file in the ApiMap for the specified workspace.

**Parameters:**
- `filename` - the absolute path to the file
- `workspace` - the root directory of the project
