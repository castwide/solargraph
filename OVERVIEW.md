# An Overview of Solargraph

The Solargraph library consists of two major groups of components: the data providers and the language servers. The data providers manage the maps of information about a program. The language servers are the concrete implementations of transports and messages that enable the language server protocol.

## Data Providers

**ApiMap** (`Solargraph::ApiMap`): The component that provides information about a program based on its Workspace, external gems, and the Ruby core.

**Workspace** (`Solargraph::Workspace`): A collection of Sources that comprise a project. Workspaces have configurations that define which files to include in maps and other project-related options. Users can configure the Workspace through a .solargraph.yml file in a project's root directory.

**Source** (`Solargraph::Source`): Data about a single Ruby file. Sources parse Ruby code into an AST and handle incremental updates.

**SourceMap** (`Solargraph::SourceMap`): A Source with generated pins for use in ApiMaps.

**Pins** (`Solargraph::Pin`): Information about classes, modules, methods, variables, etc. Pins for different types of components extend `Pin::Base`. Most ApiMap queries return results as an array of Pins.

**Cursor** (`Solargraph::Source::Cursor`): Information about a specific location in a Source.

**Clip** (`Solargraph::SourceMap::Clip`): A Cursor bundled with an ApiMap to provide definitions, completions, and other information.

**YardMap** (`Solargraph::YardMap`): A collection of YARD documents. ApiMaps use YardMaps to gather data from external gems and the Ruby core.

**Library** (`Solargraph::Library`): The component that synchronizes a Workspace with an ApiMap. Libraries help ensure that the ApiMap gets updated when a file in the Workspace changes.

## Language Servers

**Host** (`Solargraph::LanguageServer::Host`): The component responsible for processing messages between the server and the client. Hosts maintain a project's Library and provide thread-safe methods for asynchronous operations.

**Messages** (`Solargraph::LanguageServer::Message`): Implementations of LSP methods and notifications. Each message implementation extends `Message::Base`.

**Transports** (`Solargraph::LanguageServer::Transport`): Server implementations for various protocols. The two transports that are currently supported are socket and stdio. The `Transport::DataReader` class provides a common interface for processing incoming JSON-RPC messages.

## More Information

The [EXAMPLES.md](EXAMPLES.md) document provides simple examples of how to use, extend, and modify the Solargraph library.

Refer to [LANGUAGE_SERVER.md](LANGUAGE_SERVER.md) for information about connecting language clients to Solargraph language servers.
