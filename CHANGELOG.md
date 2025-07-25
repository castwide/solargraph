## 0.56.1 - July 13, 2025
- Library avoids blocking on pending yardoc caches (#990)
- DocMap checks for default Gemfile (#989)
- [Bug fix] Fixed an error in rbs/fills/tuple.rbs (#993)

## 0.56.0 - July 1, 2025
-  [regression] Gem caching perf and logging fixes #983

## 0.55.5 - July 1, 2025
- Flatten results of DocMap external bundle query (#981)
- [breaking] Reimplement global conventions (#877)
- GemPins pin merging improvements (#946)
- Support class-scoped aliases and attributes from RBS (#952)
- Restructure ComplexType specs towards YARD doc compliance (#969)
- Use Prism (#974)
- Document pages (#977)
- Enable disabled-but-working specs (#978)
- Map RBS 'untyped' type (RBS::Types::Bases::Any) to 'undefined' (#979)
- Re-enable support for .gem_rbs_collection directories (#942)
- [breaking] Comply with YARD documentation on Hash tag format (#968)
- Ignore directory paths in Workspace#would_require? (#988)

## 0.55.4 - June 27, 2025
-  Flatten results of DocMap external bundle query (#981)

## 0.55.3 - June 25, 2025
-  Nil guards in flow-sensitive typing (patch release) (#980)

## 0.55.2 - June 21, 2025
- Require external bundle (#972)

## 0.55.1 - June 8, 2025
- Fix inline Struct definition (#962)
- Ensure DocMap requires bundler when loading gemspecs (#963)
- DelegatedMethod improvements (#953)

## 0.55.0 - June 3, 2025
- Flow-sensitive typing - automatically downcast from is_a? calls (#856)
- Tuple enabler: infer literal types and use them for signature selection (#836)
- Signature selection improvements (#907)
- Add support for Ruby Structs (#939)
- [regression] Fix interface change breaking solargraph-rails (#940)
- [regression] Add back bundler/require support for solargraph-rails (#941)
- Add specs for initialize capabilities (#955)
- Create MethodAlias pins from YARD (#945)
- MessageWorker prioritizes synchronization (#956)
- initialize/new method pin cleanups (#949)
- Clip rebinds blocks when cursor is not part of receiver (#958)

## 0.54.5 - May 17, 2025
- Repair unknown encoding errors (#936, #935)
- Index arbitrary pinsets (#937)
- Separate YARD cache from doc map cache (#938)

## 0.54.4 - May 14, 2025
- Delete files from Library hash (#932)
- Clip#define returns variable pins (#934, #933)

## 0.54.3 - May 13, 2025
- Improve inspect()/desc()/to_s() methods for better debugging output (#913)
- Fix generic resolution in Hash types (#906)
- Stop parsing RBS type parameter constraints as the type name (#918)
- Fix pin inference stack (#922)
- Refactor pin equality for performance (#925)
- Improve ApiMap catalog speed by preserving static pin indexes (#930)
- Update jaro_winkler dependency (#931)

## 0.54.2 - April 28, 2025
- Resolve generics correctly on mixin inclusion (#898)
- Pick correct String#split overload (#905)
- Fix type sent into YARD method (#912)
- Early CancelRequest handling (#914)
- Destructure partial yield types (#915)
- Dependency versions (#916)

## 0.54.1 - April 26, 2025
- Retire more RubyVM-specific code (#797)
- Add additional docs for key classes, modules and methods (#802)
- Populate location information from RBS files (#768)
- Consolidate parameter handling into Pin::Callable (#844)
- Adjust local variable presence to start after assignment, not before (#864)
- Resolve params from ref tags (#872)
- Reduce use of ComplexType.parse() to preserve rooted? information (#870)
- Ensure yield return types are qualified (#886)
- Understand type of 'def foo; @foo ||= bar; end' reader methods (#888)
- Improvements to #inspect output on pins and chains (#895)
- Block method resolution improvements (#885)
- Understand mass assignment into instance variables (#893)
- Library sync and cache invalidation (#903)
- Handle super and yield scenarios from blocks (#891)
- Allow core and stdlib documentation to be uncached (#899)
- Surface variable names in LSP, e.g., textDocument/hover (#910)
- Keep idle progress notifications alive (#911)

## 0.54.0 - April 14, 2025
- Add support for simple block argument destructuring (#821)
- Benchmark the typecheck command (#852)
- Send Gem Caching Progress Notifications to LSP Clients (#855)
- [breaking] Fix more complex_type_spec.rb cases (#813)
- Mass assignment support - e.g., a, b = ['1', '2'] (#843)
- Memoize result of Chain#infer (#857)
- Ignore malformed mixins and overloads (#862)
- Drop Parser::ParserGem::ClassMethods#returns_from_node (#866)
- Refactor TypeChecker#argument_problems_for for type safety (#867)
- Specify more type behavior for variable reassignment (#863)
- One-step source synchronization (#871)
- Show cache progress in shell commands (#874)
- Fix miscellaneous scan errors (#875)
- Synchronous libraries (#876)
- Fix parsing of Set#classify method signature from RBS (#878)
- Sync Library#diagnose (#882)
- Doesn't false-alarm over splatted non-final args in typechecking (#883)
- Remove accidental inclusion of Module's methods in objects (#884)
- Remove another splat-related false alarm in strict typechecking (#889)
- Change require path `warn` to `debug` (#897)

## 0.53.4 - March 30, 2025
- [regression] Restore 'Unresolved call' typecheck for stdlib objects (#849)
- Lazy dynamic rebinding (#851)
- Restore fill for Class#allocate (#848)
- [regression] Ensure YardMap gems have return type for Class<T>.new (#850)
- Create implicit .new pins in namespace method queries (#853)

## 0.53.3 - March 29, 2025
- Remove redundant core fills (#824, #841)
- Resolve self type in variable assignments (#839)
- Eliminate splat-related false-alarms in strict typechecking (#840)
- Dynamic block binding with yieldreceiver (#842)
- Resolve generics by descending through context type (#847)

## 0.53.2 - March 27, 2025
- Fix a self-type-related false-positive in strict typechecking (#834)
- DocMap fetches gem dependencies (#835)
- Use configured command path to spawn solargraph processes (#837)

## 0.53.1 - March 26, 2025
- Reject nil requires in live code (#831)
- RbsMap adds mixins to current namespace (#832)

## 0.53.0 - March 25, 2025
- Fix crash on generic methods (#762)
- Add more type annotations to the codebase (#763 et al.)
- Address remaining typecheck issues at 'typed' level and add CI task (#764)
- Fix crash during strict typechecking (#766)
- DeepInference: Fix some bugs, add docs, refactor (#767)
- Include "self type" methods like Enumerable#each from RBS files (#769)
- Handle RBS global, module alias, class variable and class instance variable declarations (#770)
- Add support for generic includes via RBS (#773)
- Handle parsing tuples of tuples in tags (#775)
- Retire the RubyVM parser (#776)
- Improve block handling in signature selection (#780)
- Require Ruby >= 3 (#791)
- Cache YARD and RBS (#781)
  - Language server generates gem documentation in the background
- Fix bug handling Array(A, B) syntax while resolving generics (#784)
- Fix typeDefinitions for neovim (#792)
- Infer block-pass symbols (#793)
- Add #to_rbs methods to pins, use for better .inspect() output (#789)
- Remove deprecated commands (#790)
- Add :if support to NodeChainer for if statements as lvalues (#805)
- Fix ApiMap::Cache (#806)
- Map mixins from RBS (#808)
- Fix issue with wrong signature selection by call with block node (#815)
- Keep gem pins in memory (#811)
- Refactor gems command (#816)
- Use return type of literal blocks in inference (#818)
- Insert Module methods (#820)
- Revise documentation formatting (#823)

## 0.52.0 - February 28, 2025
- Chains resolve identical names with different contexts (#679)
- Handle symbol tags in method tag values (#744)
- Infer more specific Array types when possible (#745)
- Handle interpolated symbol literals (#747)
- Handle combined conditions, else clauses in case statements (#746)
- fix: support find require xxx.rb in local workspace. (#722)
- Don't require redundant attribute @return and @param tags (#748)
- Use @yieldreturn tags for type inference (#749)
- Fix type annotations identified at 'typed' level (#750)
- Support RBS class aliases (#751)
- Better support for generics via Class @param tags (#743)
- Generic module support through RBS (#757)
- Fix inference of begin expression types (#754)
- Add argument to satisfy typechecker on which signature to use (#755)
- Fix RBS ingestion implicit initializer issues, missing param types (#756)
- Validate zsuper arity
- Use yard-solargraph plugin (#759)
- Add missing RBS types

## 0.51.2 - February 1, 2025
- Fix exception from parser when anonymous block forwarding is used (#740)
- Parameterized Object types
- Remove extraneous comment from method examples

## 0.51.1 - January 23, 2025
- Format example code
- Block infers yieldreceiver from chain

## 0.51.0 - January 19, 2025
- Resolve self in yieldreceiver tags
- Include absolute paths in config (#674)
- Enable diagnostics by default
- Fix cache resolution (#704)
- Modify rubocop option for rubocop < 1.30 (#665)
- Include absolute paths in config (#674)
- Enable diagnostics by default
- Remove RSpec convention (#716)
- Include convention pins in document_symbols (#724)
- Implement Go To Type Definition (#717)
- Remove e2mmap dependency (#699)
- Update rbs to 3.0
- Relax reverse_markdown dependency (#729)
- Fix Ruby 3.4 and move all parsing to whitequark (#739)
- Add Pin::DelegatedMethod (#602)
- Complete global methods from a file inside namespaces (#714)
- gemspec dashes and required path slashes (#697)

## 0.50.0 - December 5, 2023
- Remove .travis.yml as its not longer used (#627)
- Fix empty string case when processing requires (#644)
- Fix scope() method call on wrong object (#670)
- Parse comments that start with multiple hashes (#667)
- Use XDG_CACHE_HOME if it exists (#664)
- Add rbs mention to readme (#693)
- Remove Atom from the readme (#692)
- Add more metadata to the gemspec (#691)
- Do not deprecate clear command
- Library#locate_ref returns nil for unresolved requires (#675)
- Hide deprecated commands
- List command
- Fixes (or ignores) ffi crash (#676)
- increase sleep time on cataloger (#677)
- YardMap ignores absolute paths (#678)
- Clarify macros vs. directives
- Infer complex types from method calls
- Default cache uses XDG_CACHE_HOME default (#664)

## 0.49.0 - April 9, 2023
- Better union type handling
- First version of RBS support
- Dependency updates
- Update RuboCop config options
- RBS core and stdlib mapping
- Anonymous splats and multisig arity
- Infinite loop when checking if a class is a superclass (#641)

## 0.48.0 - December 19, 2022
- Add Sublime Text to README (#604)
- Map nested constant assignments
- Handle rest/kwrest modifiers on overload arguments (#601)
- Make rubocop info severity Severity::HINT (#576)
- Process non-self singleton classes (#581)
- Fix nest gemspec dependency (#599)
- Strip 'file ' prefix from all filenames in RdocToYard (#585)
- Show why rubocop fails (#605)
- Link solargraph-rails (#611)

## 0.47.2 - September 30, 2022
- Fix complex type inference (#578)
- Off-by-one diagnostic (#595)

## 0.47.1 - September 27, 2022
- Remove debug code from release (#600)

## 0.47.0 - September 25, 2022
- Completion candidates for union types (#507)
- Nullify Hover object instead of contents value (#583)
- Mapping workspace stuck in 0 (#587)
- Fix parsing of nested subtypes (#589)
- Update YARD tags on Pin::Block methods (#588)
- @!visibility directive support (#566)

## 0.46.0 - August 22, 2022
- Ignore typecheck errors with @sg-ignore tag (#419)
- Strict checks report undefined method calls on variables (#553)
- Infer type from method arguments (#554)
- Return nil value for empty hover contents (#543)

## 0.45.0 - May 23, 2022
- Basic support for RSpec #describe and #it
- fix: domain can complete private method (#490)
- Update README.md (#533)
- Doc: update readme.md for add solargraph support (#536)
- Process DASGN node in Ruby 3
- File.open core fill
- replace with_unbundled_env with with_original_env (#489)
- Require specific version of gem (#509)
- Support URIs prefixed with single slashed file scheme (#529)
- Fix typo in README.md (#549)
- details on config behavior (#556)
- Consider overloads in arity checks
- ENV core fill for Hash-like methods (#537)
- Fix string ranges with substitutions (#463)

## 0.44.3 - January 22, 2022
- TypeChecker validates aliased namespaces (#497)
- Always use reference YARD tags when resolving param types (#515) (#516)
- Skip method aliases in strict type checking

## 0.44.2 - November 23, 2021
- Scope local variables in class_eval blocks (#503)
- Fix invalid UTF-8 in node comments (#504)

## 0.44.1 - November 18, 2021
- Chain nil safety navigation operator (#420)
- Update closure and context for class_eval receiver (#487)
- SourceMap::Mapper handles invalid byte sequences (#474)
- Special handle var= references, which may use as var = (have space) (#498)
- Rebind define_method to self (#494)

## 0.44.0 - September 27, 2021
- Allow opening parenthesis, space, and comma when using Diff::LCS (#465)
- Support textDocument/documentHighlight
- Library#references_from performs shallow matches

## 0.43.3 - September 25, 2021
- Avoid Dir.chdir in Bundler processes (#481)
- Check stdlib for gems with empty yardocs
- Library#maybe_map checks for source in workspace

## 0.43.2 - September 23, 2021
- Synchronize server requests (#461)

## 0.43.1 - September 20, 2021
- Complete nested namespaces in open gates
- SourceMap::Mapper reports filename for encoding errors (#474)
- Handle request on a specific thread, and cancel completion when there has newer completion request (#459)
- Fix namespace links generated by views/_method.erb (#472)
- Source handles long squiggly heredocs (#460)

## 0.43.0 - July 25, 2021
- Correct arity checks when restarg precedes arg (#418)
- Improve the performance of catalog by 4 times (#457)
- Type checker validates duck type variables and params (#453)
- Kernel#raise exception type checker
- Pin::Base#inspect includes path
- Fix arity with combined restargs and kwrestargs (#396)

## 0.42.4 - July 11, 2021
- Yardoc cache handling
- Fix required_paths when gemspec is used (#451)
- fix: yard stdout may break language client (#454)

## 0.42.3 - June 14, 2021
- Require 'pathname' for Library

## 0.42.2 - June 14, 2021
- Improve download-core command output
- Ignore missing requests to client responses
- Add automatically required gems to YardMap
- Use closures to identify local variables

## 0.42.1 - June 11, 2021
- YardMap#change sets new directory (#445)

## 0.42.0 - June 11, 2021
- Improve YardMap efficiency
- Bench includes Workspace for cataloging
- Initialize confirms static features from options (#436)
- Enable simple repairs without incremental sync (#416)
- Discard unrecognized client responses
- Notify on use of closest match for core (#390)

## 0.41.2 - June 9, 2021
- Rescue InvalidOffset in async diagnosis
- Remove erroneous escaping from Hover

## 0.41.1 - May 31, 2021
- ApiMap handles required bundles (#443)

## 0.41.0 - May 30, 2021
- Chain constant at last double colon with more than two nested namespaces
- Fill Integer#times return type (#440)
- Validate included modules in type checks (#424)
- Faster language server initialization
  - Server response to initialize is near immediate
  - Workspace is mapped in a background thread
  - Supported clients report mapping progress
- Log RuboCop corrections at info level (#426)
- Allow configuring the version of RuboCop to require (#430)
- Fix source of diagnostic (#434)
- Fix file argument in RuboCop (#435)
- Config ignores directories with .rb extension (#423)

## 0.40.4 - March 3, 2021
- Fix optarg and blockarg ordering
- Override specialization for #initialize
- Find definitions with cursor after double colon

## 0.40.3 - February 7, 2021
- Simplify and allow to configure rubocop formatter (#403)
- Type checker shows tag in param type errors (#398)
- Handle bare private_constant (#408)
- Type checker handles splatted variables (#396)

## 0.40.2 - January 18, 2021
- Type checker ignores splatted calls in arity (#396)
- Allow Parser 3.0 (#400)

## 0.40.1 - December 28, 2020
- Use temp directory for RuboCop formatting (#397)
- NodeMethods reads splatted hashes (#396)

## 0.40.0 - December 14, 2020
- Fix alias behavior
- Consolidate method pin classes
- Consolidate YARD pins
- CheckGemVersion can use Bundler for updates
- Tempfile fills
- Support rubocop 1.0 (#381)
- Require Ruby >= 2.4.0 (#394)
- Map visibility calls with method arguments (#395)
- Switch maruku to kramdown
- Remove nokogiri dependency
- Detect internal_or_core? for strict type checking
- ApiMap#catalog merges environs for all sources in bench

## 0.39.17 - September 28, 2020
- Handle YARD pins in alias resolution

## 0.39.16 - September 27, 2020
- Include acts like extend inside sclass
- Improved alias resolution
- Parse args from YARD method objects
- Resolve included namespaces with conflicts
- Chains infer from multiple variable assignments
- Array and Hash core fills
- String.new core fill

## 0.39.15 - August 18, 2020
- Backwards compatibility for typecheck subcommand
- Handle dangling colons on tag hovers
- NodeChainer handles chains with multiple blocks

## 0.39.14 - August 13, 2020
- Fix return nodes from case statements (#350)
- Treat for loops as closures (#349)
- Array#zip core fill (#353)
- Exit with 1 if type check finds problems (#354)

## 0.39.13 - August 3, 2020
- YardPin::Method skips invalid parameters (#345)
- Complete and define complex type tags

## 0.39.12 - July 18, 2020
- Completion and hover on tags in comments (#247)
- Formatting change in RuboCop 0.87.0
- Use `ensure` block for File.unlink tempfile (#342)
- Fix super handling in call_nodes_from

## 0.39.11 - July 3, 2020
- Fix line numbering in bare parse directives
- Bracket handling

## 0.39.10 - July 1, 2020
- RDoc comments can be strings

## 0.39.9 - June 20, 2020
- Fixed directive parsing
- Relocate pins from @!parse macros
- Return all symbols for empty queries (#328)
- Log number of files
- RdocToYard includes method line numbers

## 0.39.8 - May 26, 2020
- File < IO reference
- Updated yardoc archive
- Chain integers with trailing periods
- Map autoload paths
- Set Encoding.default_external
- Faster store index
- ApiMap#catalog rebinds blocks
- Fixed binder inheritance
- Remove ApiMap mutex
- Set overrides

## 0.39.7 - May 4, 2020
- RubyVM convert_hash node check
- File URI space encoding bug

## 0.39.6 - May 3, 2020
- Workspace evaluates gem spec in toplevel binding (#316)
- Rescue StandardError instead of Exception
- Correct method parameter order
- Gracefully handle misunderstood macros (#323)

## 0.39.5 - May 2, 2020
- Nil check in name_type_tag template
- Update obsolete method calls for Ruby 2.7
- YardMap rejects external pins
- RubyVM mapper handles Bundler.require calls
- RDocToYard clears serialized cache
- Workspace evaluates gem specs without binding
- Documentor clears gem caches

## 0.39.4 - April 30, 2020
- RDocToYard update and spec (#315)
- Map function calls to visibility methods
- Cache source code line arrays
- Fix RuboCop errors

## 0.39.3 - April 28, 2020
- Mapper handles private_class_method without arguments (#312)
- Fix pin positions from YARD directives (#313)
- Rescue errors from pin caches

## 0.39.2 - April 26, 2020
- Fix legacy super/zsuper node processing
- Map parameters to updated module functions
- Include mass assignment in call nodes

## 0.39.1 - April 26, 2020
- Additional return node checks from case statements in legacy
- Check super call arity

## 0.39.0 - April 26, 2020
- RubyVM parser for Ruby 2.6+
- Lambda node processor
- Faster CommentRipper
- Implement TypeChecker levels
- Type inference improvements
- Prefer @return to @type in constant tags
- Support @abstract tags
- Improved recipient node detection
- Host#diagnose rescues FileNotFoundError
- Fuzzier inheritance checks
- Refactored uri queue synchronization (#289)
- Constant resolution finds nearest names (#287)
- Arity checks
- Additional CoreFills for numeric types and operators
- Chains track splat arguments
- Support case statements in type inference
- Support prepended modules (#302)
- TypeChecker validates constants
- Rescue ENOENT errors when loading sources (#308)
- Formatting message handles empty files
- Avoid lazy initialization of Mutex
- ApiMap inner queries use Set instead of Array

## 0.38.6 - March 22, 2020
- Ignore Bundler warnings when parsing JSON (#273)
- Chain inference stack uses pin identities (#293)
- Fix super_and_sub? name collisions (#288, #290)
- Fix various Bundler and Travis bugs

## 0.38.5 - January 26, 2020
- Namespace conflict resolution
- Pin context uses closure context in class scope
- Format file without extension (#266)

## 0.38.4 - January 21, 2020
- Literal link generates ComplexType
- Remove pin cache from chain inference
- Avoid duplicates in combined LSP documentation
- YardMap skips workspace gems

## 0.38.3 - January 19, 2020
- Refactored YardMap require processing
- Object/BasicObject inheritance handling in method detection
- StdlibFills and YardMap integration (#226)
- Include scope gates in local variable detection
- Reduce namespace pins in YARD pin generation
- Support multiple return tags in method return types
- File core fills
- Benchmark stdlib fill
- Redorder methods to include core after other classes
- Method type inference uses chains and includes block nodes (#264)
- Infer from overloaded methods with local variable arguments
- Add Array#map! to core fills

## 0.38.2 - January 9, 2020
- Include visibility in method documentation
- Bundler >= 2.1 uses with_unbundled_env (#252)
- Remove irb from dependencies (#258)
- Update embedded docs (#259)
- Object#inspect core fill
- ApiMap finds constants in superclasses
- STDIO constant variables
- Filter duplicate pins in completionItem/resolve
- Travis updates

## 0.38.1 - January 2, 2020
- Hash#[]= type checking
- Experimental @param_typle tag
- TypeChecker argument checks inherit param tags from superclasses
- Miscellaneous core overrides
- Boolean literals and type checking
- Update Thor (#254)
- CI against Ruby 2.7 (#253)

## 0.38.0 - November 22, 2019
- Drop htmlentities dependency (#224)
- Blank lines do not affect indentation in documentation
- Use backticks for code blocks in generated markdown
- Register additional HTML tags in ReverseMarkdown
- Guard against nil pin comments (#231)
- Speedup Solargraph::ApiMap::Store#fqns_pin (#232)
- RuboCop formatting integration through API (#239)
- Qualify literal value types (#240)
- Switch back to Maruku for documentation generation
- Refactored dependencies to improve startup time
- Test if ns is nil to avoid exception (#245)
- Nil check when parsing comments (#243)

## 0.37.2 - August 25, 2019
- Generate documentation without conversions

## 0.37.1 - August 19, 2019
- No escape in completion item detail

## 0.37.0 - August 19, 2019
- Replace Maruku with YARD RDocMarkup
- Refactored Cursor#recipient
- Remove HTML entity escaping
- Messages check enablePages for links
- Escape method for templates
- Escape type tags with backslashes
- Updated gem dependencies

## 0.36.0 - August 12, 2019
- Replace redcarpet with maruku
- Check for nil nodes in variable probes (#221)

## 0.35.2 - August 6, 2019
- Chains resolve block variable types.

## 0.35.1 - July 29, 2019
- Infer variable types from assignments with unparenthesized arguments
- (#212)

## 0.35.0 - July 19, 2019
- Track blocks in chain links
- Array overloads
- Fix NoMethodError for empty overload tags
- TypeChecker validates block args
- Object#to_s override
- Pin::BaseVariable uses clips for probles
- Add ability to read from a global config file (#210)
- SourceChainer falls back to fixed phrases in repaired sources
- Find return nodes in blocks

## 0.34.3 - July 14, 2019
- Refactor to reduce frequent allocations
- Only send renameOptions to clients with prepareSupport (#207)
- Add pin locations to scans
- TypeChecker finds params for hash args by name
- Drop empty register/unregister events (#209)
- Pin::Parameter type inference
- Detect yielded blocks in calls
- SourceMap::Mapper maps overrides

## 0.34.2 - July 3, 2019
- Documentor uses an external process to collect specs
- Bundle subcommand passes rebuild option to Documentor
- Refactored bundle dependency reads
- Fixed Travis issues

## 0.34.1 - June 26, 2019
- Refactored bundler/require handling
- Fix clip completion from repaired sources
- Bundler issues in Travis

## 0.34.0 - June 25, 2019
- Keyword argument names in autocomplete
- `solargraph bundle` and related cache commands
- RDoc to YARD conversion
- More TypeChecker validation
- Environs and Conventions
- Core overrides
- `@overload` tag support
- Handle splats in overloads
- Scope gates
- Type Class/Module reduction hack
- Duck type checking
- frozen_string_literal
- Faster YardMap loading

## 0.33.2 - June 20, 2019
- Fixed resolution of `self` keyword
- Chain inference depth limits
- Source#references skips nodes without the requested symbol
- Refactored Library without `checkout` method
- Parameter merges require same closures
- Completion item descriptions contain unique links

## 0.33.1 - June 18, 2019
- Ignore attribute directives without names (castwide/vscode-solargraph#124)
- Chain and/or/begin/kwbegin nodes
- TypeCheck diagnostics run on workspace files only by default
- Mapper updates directive positions (#176)
- Track pins in TypeChecker problems.

## 0.33.0 - June 18, 2019
- Deprecated plugin architecture
- Closure pins for enhanced context and scope detection
- Block resolution
- Major Pin refactoring
- Single parameter pin for blocks and methods
- Major NodeProcessor refactoring
- Block rebinding
- Resolve method aliases
- Namespace scope gates (WIP)
- Improved ApiMap::Store indexing
- ApiMap block recipient cache
- Refactored pin and local mapping
- Host synchronization fixes
- Rebind instance_eval, class_eval, and module_eval blocks
- Improved string detection
- Use @param tags for parameter pin documentation
- Go To Definition works on require paths (castwide/vscode-solagraph#104)
- Mapper processes singleton method directives
- Resolve self return types based on current context
- Exclude inner node comments from documentation
- Infer hash element types from value parameters
- Pin::BaseMethod typifies from super methods
- Ignore FileNotFoundError in textDocument/signatureHelp
- Class#new and Class.new return types
- Chain::Call resolves `self` return types
- Deprecated Pin::Method#infer method
- Pin::Method#probe returns unique tags
- Errant dstr detection
- Source does not detect string? at end of interpolation
- String detection in unsynchronized sources
- Reduced node comparisons in Source#string_at?
- Superclass qualification for instance variables
- Pin::Attribute#probe infers types from instance variables
- First version of TypeChecker and its reporter
- Strict type checking
- Source::Chain::Call does not typify/probe/proxy pins
- Probe for detail in hover and resolve
- JIT pin probes
- Command-line typecheck
- Clip#complete skips unparsed sources
- Check parameter types for super_and_sub?
- Object#! CoreFill.
- `scan` subcommand
- Detect class variables by scope gates
- Move METHODS_RETURNING_SELF to CUSTOM_RETURN_TYPES
- Host::Dispatch catalogs attachments to implicit and generic libraries (#139)
- Preliminary support for `@overload` tags
- `self` resolution in ComplexTypes

## 0.32.4 - May 27, 2019
- Backport update

## 0.32.3 - May 14, 2019
- -  ApiMap#get_namespace_type selects namespace pins (#183)
- - Fixed type inference for Class.new and Class#new exceptions

## 0.32.2 - May 6, 2019
- - Gemspec changes
- - Recommend LanguageClient-neovim instead of vim-solargraph (#180)
- - Added Eclipse plugin information (#181)
- - Refactored cataloging
- - workspace/didChangeWatchedFiles catalogs libraries (#139)

## 0.32.1 - April 7, 2019
- completionItem/resolve returns nil for empty documentation

## 0.32.0 - April 4, 2019
- Add implementation of textDocument/prepareRename (#158)
- Update to Backport 1.0
- Source handles comments that start with multiple hashes
- Add Ruby 2.6.1 to CI
- Updated JRuby version support
- Infer return types from top-level references
- SourceChainer handles ! and ? outside of method suffixes (#166)
- CompletionItem uses MarkupContent for documentation (#173)
- Add Object#tap to core documentation. (#172)
- Source and Mapper handle invalid UTF-8 byte sequences (#33)
- Exceptions while mapping emit warning messages
- Process private_class_method for attributes (#171)
- Qualify namespaces from includes in the root namespace (#170)
- Faster YARD object location

## 0.31.3 - February 7, 2019
- Location of directive context depends on tag name
- Regenerated core docs
- Don't escape colon in URI (#150)
- Reduce file_to_uri conversions to avoid discrepancies
- SourceMap::Clip#locals corrects cursor positions outside of the root context
- Host::Sources notifies observers with URIs
- Finish synchronizing sources with unbalanced lines
- Use ComplexType.try_parse to avoid exceptions for syntax errors

## 0.31.2 - January 27, 2019
- Use YARD documentation rules to associate directives with namespaces
- Handle non-unique pin locations in completionItem/resolve
- Clip#complete handles @yieldreceiver and @yieldpublic contexts
- Host::Dispatch filters library updates (castwide/vscode-solargraph#99)
- Qualify included namespaces (#148)

## 0.31.1 - January 20, 2019
- Unsynchronized sources can still try to use existing nodes for chains
- Host filters document symbols for unique locations
- Server response logging in debug
- Host keeps deleted files open in sources
- CoreGen tweaks
- Fix negative argument error in Source#stringify_comment_array (#141)
- Library#references_from includes parameter pins (#135)
- Block nodes are foldable
- Source detects comment positions past the range on the ending line
- workspace/didChangeConfiguration ignores null settings (#144)

## 0.31.0 - January 13, 2019
- Removed deprecated Library methods
- Tweaked foldable comment ranges
- Host::Dispatch module for managing open sources and libraries
- YardMap::CoreGen module for generating documentation from Ruby source
- Improved communication between hosts and adapters
- Refactored Host methods
- `@!domain` directive uses [type] syntax
- Make SourceMap#query_symbols use fuzzy matching. (#132)
- Threaded ApiMap cataloging
- Fixed fencepost error in Position.from_offset
- Lazy method alias resolution
- Library#references_from returns unique locations
- Additional info logs
- Asynchronous source parsing
- Unsychronized source support for faster completion requests (castwide/vscode-solargraph#95)
- Faster source comment parsing
- Host only diagnoses synchronized sources

## 0.30.2 - December 31, 2018
- Workspace/library mapping errors (castwide/solargraph#124)
- RuboCop diagnostics handle validation errors
- Map visibility methods with parameters
- Allow overriding core doc cache directory (castwide/solargraph#125)

## 0.30.1 - December 27, 2018
- Library#catalog avoids rebuilding ApiMaps that are already synchronized
- Host#locate_pin finds YARD pins
- completionItem/resolve merges documentation from multiple pins

## 0.30.0 - December 22, 2018
- Multi-root workspaces
- Folding ranges
- Logging with levels
- Environment info
- Replace EventMachine with Backport
- Gems without yardocs fall back to stdlib
- Formatting requires shellwords
- Use Pathname to normalize require paths

## 0.29.5 - December 18, 2018
- Source::Change repairs preceding periods and colons.
- Pins use typify and probe methods for type inference.
- NodeChainer supports or_asgn nodes.
- NodeMethods.returns_from supports and/or nodes.
- Library uses single source checkout.
- ApiMap includes BasicObject and operators in method queries.
- Refactored CheckGemVersion.

## 0.29.4 - December 7, 2018
- Parameter type checks in implicit type inference.
- Additional implicit method type detection cases.
- Chains match constants on complete symbols.

## 0.29.3 - December 5, 2018
- Missing parameter in send_notification call.
- Typo in checkGemVersion message.

## 0.29.2 - December 5, 2018
- Pin type checks for module_function, private_class_method, and private_constant.
- ApiMap#catalog checks for added and removed sources.

## 0.29.1 - November 30, 2018
- Alias method reference error.

## 0.29.0 - November 26, 2018
- Map method aliases.
- Removed coderay dependency.
- Initial support for named macros.
- First implementation of deep method inference.
- See references in @return tags.
- Literal regexp support.
- Additional CoreFills.
- Mapper uses NodeProcessor.
- Pin::BlockParameter checks param tags by index.
- Clip#complete handles unfinished constants with trailing nodes.
- Library performs case-insensitive strips of symbol references.
- Unparsed sources have nil nodes.
- NodeProcessor recurses into nodes by default.
- Namespace conflicts in method queries.
- SourceMap::Clip#complete method visibility.
- Enable gem dependency mapping.

## 0.28.4 - October 26, 2018
- Pin::Documenting#documentation converts without RDoc (castwide/solargraph#97)
- Rescue errors in gemspec evaluation (castwide/solargraph#100)

## 0.28.3 - October 21, 2018
- Deprecated overwrite features.
- Pin::MethodParameter finds unnamed param tags by index.
- Workspace does not cache loaded gems.
- Explicit range in textDocument/formatting result (castwide/vscode-solargraph#83).
- SourceMap::Mapper maps alias and alias_method.
- Source::Chain avoids recursive variable assignments (castwide/solargraph#96).
- Pin scope reference in Chain::Head.
- Clip does not define arbitrary comments.

## 0.28.2 - October 2, 2018
- Map aliases.
- Refactored diagnostics.
- SourceChainer checks for nil source error ranges.
- Clips handle partially completed constants.
- ApiMap method queries return one pin for root methods.
- Clip#complete detects unstarted inner constants.

## 0.28.1 - September 18, 2018
- YardMap adds superclass, include, and extend references.

## 0.28.0 - September 16, 2018
- ApiMap sorts constants by name within namespaces.
- Simplified source parsing.
- SourceChainer requires parsed and unrepaired source for node chaining.
- Source#synchronize does not flag repaired sources unparsed.
- References extend pins.
- Source::Change#repair handles multiple periods and colons.
- Chain::Constant uses chained context.
- Chain rebased constants.
- Deprecated Chain::Definition.
- SourceMap::Mapper includes symbol pins in standard pin array.
- YardMap ignores duplicate requires of the same gem.
- textDocument/rename hack for variables.
- Completing duck types searches for all duck-typed methods and includes Object.

## 0.27.1 - September 10, 2018
- Default Host#library instance.

## 0.27.0 - September 9, 2018
- New Cursor and Clip components replace Fragments.
- Split Sources into Sources (text and nodes) and SourceMaps (pins and other map-related data).
- Improved Source synchronization.
- Standardized chain generation on NodeChainer.
- Redesigned server threading.
- Host::Cataloger is responsible for updating ApiMaps.
- Host::Diagnoser is responsible for running diagnostics.
- Server checks gem versions inline instead of running an external process.
- New Library synchronization.
- ApiMap#catalog uses Bundles for updates.
- SourceMap::Mapper processes directives.
- Improved SourceMap and Pin merging.
- Chains support `super` and `self` keywords.

## 0.26.1 - August 31, 2018
- Update variable pins when synchronizing sources.

## 0.26.0 - August 30, 2018
- Major refactoring.
- More ComplexType integration.
- Use Chains for pin resolution and type inference.
- Deprecated ApiMap::Probe for Chains.
- Force UTF-8 encoding without normalizing.
- CallChainer parses simple call chains.
- Fragments are responsible for define, complete, and signify.
- Method visibility in ApiMap#get_complex_type_methods.

## 0.25.1 - August 20, 2018
- Revised hack in Host change thread for mismatches in version numbers and content changes
- Mapper#code_for corrects for EOL conversions in parser
- Fix TypeError on hover (castwide/solargraph#82)
- All fragment components return strings
- ComplexType supports fixed parameters
- ComplexType supports hash parameters with key => value syntax

## 0.25.0 - August 17, 2018
- RuboCop reporter uses an inline operation instead of an external process
- Resolve class and instance variable types from signatures
- Source attempts fast pin merges
- Refactored docstring parsing
- Pins can merge comments
- Variable pins use complex return types
- MethodParameter pin merges return types
- Handle self in ApiMap#qualify
- First implementation of new YardMap
- ApiMap::Store does not delete yard pins on source updates
- ApiMap changes to use new YardMap and store
- RequireNotFound uses ApiMap#unresolved_requires
- YardMap stdlib support
- Synchronize required path changes
- ComplexType ignores curly brackets
- Synchronize YardMap with source updates
- YardMap cache and ApiMap::Store synchronization
- Method completion filter
- ApiMap#define ignores keywords
- Removed manual garbage collection
- Docstring comparisons for pin merges
- Removed extra whitespace from method pin documentation
- textDocument/completion returns empty result marked incomplete while document is changing
- YardMap generates stdlib pins in one pass and caches results
- Disabled version order hack in Host change thread
- textDocument/formatting uses nil ranges for overwriting

## 0.24.1 - August 9, 2018
- No completion items for void return types
- ApiMap#complete qualifies pin return types
- Add space to = in attribute writer methods
- Redirect YARD logger to stderr

## 0.24.0 - August 5, 2018
- Complex types
- Include duck-typed methods in completion items
- Fragments correct EOL discrepancies in comment ranges
- TypeNotDefined diagnostics
- Mapper suppresses stdout while parsing docstrings

## 0.23.6 - August 2, 2018
- Fragment signatures skip array brackets inside arguments and blocks
- Disabled Host#save in DidSave
- Source documentation and method visibility
- YARD method object visibility
- Probe#infer_signature_type qualifies return types
- SourceToYard rakes method and attribute pins together
- LSP Initialize method prefers rootUri to rootPath

## 0.23.5 - July 16, 2018
- Source identifies files that raise exceptions
- ApiMap recognizes self keyword
- Refactored diagnostics reporters
- Source#all_symbols ignores pins with empty names
- Allow ? and ! in fragment signatures
- Runtime process checks scope for methods
- LiveMap returns constant pins
- Probe includes locals when resolving block parameters
- Probe resolves word types

## 0.23.4 - July 9, 2018
- Pin::Attribute#parameters is an empty array.
- Include attributes in Source method pins.
- Removed alphanumeric condition for mapping def pins.
- Refactored Source symbol query and pin location.

## 0.23.3 - July 4, 2018
- Fixed workspace/symbol method references
- Library#overwrite ignores out-of-sync requests
- Dynamic registration fixed

## 0.23.2 - July 4, 2018
- Fixed dynamic registration checks.

## 0.23.1 - July 4, 2018
- Fixed initialize result for clients without dynamic registration.

## 0.23.0 - July 1, 2018
- Dynamic registration for definitions, symbols, rename, and references
- Fixed capability registration issues
- First version of stdio transport
- YardMap object cache
- Pin::Attribute supports class method paths
- File.realdirpath conversion bug (castwide/solargraph#64)

## 0.22.0 - May 28, 2018
- Ruby 2.5 issues on Travis CI
- Fixed in-memory cache issue
- Fixed type inference from signatures for literal values
- Infer local variable types derived from other local variables
- textDocument/references support
- textDocument/rename support
- Probe infers word pins for nested namespaces
- Attribute scopes
- RuboCop command specifies config file

## 0.21.1 - May 13, 2018
- Initial support for module_function method visibility.
- Map `extend self` calls.
- ApiMap#complete filters completion results on the current word.
- Refactored YardMap stdlib handling.
- Minor Message#send bug in socket transport that raised exceptions in Ruby 2.5.1.
- Probe#infer_method_pins fully qualifies context_pin namespace.

## 0.21.0 - May 7, 2018
- ApiMap reads additional required paths from the workspace config.
- Source handles encoding errors.
- Integrated Travis CI.
- ApiMap#signify filters for method pins.
- Default client configuration updates.
- Fixed RuboCop formatting output.
- Removed bundler dependency.
- Removed legacy server and related dependencies.
- Infer method parameter types.
- Include solargraph.formatting in dynamic capability registration.
- Class and module method visibility (e.g., Module#private and Module#module_function).

## 0.20.0 - April 22, 2018
- YardMap tracks unresolved requires
- More specs
- Standardized diagnostics reporters
- `rubocop` and `require_not_found` reporters
- Unresolved requires are reportable diagnostics instead of errors
- LSP handles gem features with extended methods
- textDocument/onTypeFormatting completes brackets in string interpolation
- Workspace uses gemspecs for require paths
- Enabled domain support with @!domain directive in ApiMap and Source
- Workaround for unavailable :rdoc markup class
- Probe infers global variable pins
- Source#all_symbols includes namespaces
- Use kramdown instead of redcarpet for document pages

## 0.19.1 - April 16, 2018
- YardMap finds yardocs for gems with or without the bundler.

## 0.19.0 - April 16, 2018
- Major refactoring.
- ApiMap does not require AST data.
- Prefer line/character positions to offsets.
- ApiMap::Probe class for inferring dynamic return types.
- Improved local variable handling.
- Max workspace size is 5000 files.

## 0.18.3 - April 10, 2018
- castwide/solargraph#33 Enforce UTF-8 encoding when parsing source

## 0.18.2 - April 6, 2018
- RuboCop avoids highlighting more than 1 line per offense.
- LSP message synchronization issues.
- Prefer non-nil variable assignments in results.
- Check for nil assignment nodes in variable pins.
- Fragments handle literal value detection for signatures.
- Unresolved completion items do not emit errors.
- Completion items do not send 'Invalid offset' errors to clients.

## 0.18.1 - April 5, 2018
- First version of the language server.

## 0.17.3 - March 1, 2018
- YardMap rescues Gem::LoadError instead of Gem::MissingSpecError
- Server caches ApiMap for nil workspaces.

## 0.17.2 - February 15, 2018
- Visibility tweaks
- Refactored YardMap
- Process require paths to bundled gems
- Core method return type overrides
- Server handles nil and empty workspaces

## 0.17.1 - February 4, 2018
- Convert ERB templates to parsable code.
- Improved relative constant detection.
- Resolve file paths from symbols in required gems.
- Use inner method suggestion methods to avoid infinite recursion.

## 0.17.0 - February 1, 2018
- Support Solargraph configurations in workspace folders.
- Use @yieldreceiver tag to change block contexts.
- Handle whitespace in signatures.
- Convert 'self' when inferring signature types.
- Handle bare periods without signatures.
- Source#fix handles bare periods better.
- Deprecate snippets.
- Initial support for macro directives.
- Changes to YardMap require path resolution.
- Server provides /define endpoint for go to definition.
- Removed deprecated methods from ApiMap and LiveMap.

## 0.16.0 - January 17, 2018
- Watch and report workspace changes.
- Arguments in Runtime method results.
- Infer yieldparam types from method owner subtypes.
- Select available port from shell.

## 0.15.4 - January 2, 2018
- Include suggestion documentation in /signify response.
- Derive unknown method return types from superclasses.
- Support for extended modules.
- Narrow visibility of private constants and methods.
- Infer return types of method chains from variables.

## 0.15.3 - December 10, 2017
- Suggestion has_doc attribute.
- Fully qualified namespace in generated MethodObject paths.
- Support for private_class_method and private_constant.
- Stable suggestion sorting (e.g., local class method comes before superclass method).
- Track files in workspace code objects.

## 0.15.2 - December 5, 2017
- Patched critical bug in minimum documentation requirement.

## 0.15.1 - December 4, 2017
- Fixed attribute -> code object mapping error.

## 0.15.0 - December 3, 2017
- CodeMap is workspace-agnostic.
- Use YARD code objects for workspace path documentation.
- Map pins to code objects.
- Infer return types from domain (DSL) methods.
- Fixed visibility and results for superclasses.
- Experimental @yieldreceiver tag.
- Improved syntax error handling in Source.fix.
- Gem ships with Ruby 2.2.2 yardocs.
- Experimental plugin architecture and Runtime plugin.
- Experimental support for updating Ruby core documentation.

## 0.14.3 - November 30, 2017
- * Namespace pins
- * Required setting in config
- * Ignore non-Ruby files in workspace
- * Detect changes in workspace files
- * Add return types to class and module suggestions
- * Unique variable names in suggestions
- * Look for variable nodes with non-nil assignments or type tags
- * Server reverted from Puma back to WEBrick
- * Stubbed bundler/(setup|require) dependency mapping
- * Handle config parsing exceptions
- * Disabled Runtime plugin pending further testing
- * Handle exceptions in all server endpoints

## 0.14.2 - November 26, 2017
- Heisenbug in Gem::Specification concealed by Bundler behavior.

## 0.14.1 - November 26, 2017
- Disabled Runtime plugin.

## 0.14.0 - November 26, 2017
- LiveMap plugin support.
- Rebuild workspace yardoc if it exists (do not create).
- Standardized code/filename argument order.
- Internal Runtime plugin.
- Infer typed from Kernel methods.
- Removed unused dependencies.
- Add locations to pins and suggestions.
- Reduced size of /suggest response by default.
- Use /resolve for suggestion detail.
- Domain configuration option (experimental DSL support).
- Identify constant types.
- Optimized namespace type resolution.
- Include stdlib in search and document requests.
- Undefined variable bug in YardMap.

## 0.13.3 - November 7, 2017
- First support for YARD directives in workspace code.
- Experimental LiveMap plugins.
- Changes for backwards compatibility to Ruby 2.2.2.
- Generate config from default object.

## 0.13.2 - October 31, 2017
- * ApiMap clears namespace map when processing virtual files (duplicate object bug).
- * Exception for disagreement between root namespace and signature (root instance method bug).

## 0.13.1 - October 29, 2017
- Added missing return types.
- Fixed object(path) resolution.
- Corrected docstrings assigned to attribute pins.
- Server uses Puma.
- Filter server suggestions by default.
- Cache pin suggestions.
- Improved caches.
- YardMap crawls up the scope to find constants.
- Use local variable pins to reduce node browsing.
- Preparing the workspace also prepares the YardMap.
- Deprecated experimental bind tag.
- Include restargs (e.g., def foo *bar) in method arguments.
- Avoid inferring from signatures in top-level suggestions.
- Global variable support.
- Remove virtual source's existing pins in ApiMap updates.
- Improved performance of signature type inference.

## 0.13.0 - October 3, 2017
- Constant and symbol detection.
- Major code refactoring.
- Update single files instead of entire workspace.
- Eliminated local yardoc generation.

## 0.12.2 - September 14, 2017
- Fixed instance variable scoping bug.
- Partial support for constant method suggestions.

## 0.12.1 - September 12, 2017
- More literal value exceptions.
- Skip literal strings when building signatures.
- Improved ApiMap processing.

## 0.12.0 - September 12, 2017
- ApiMap config excludes test directory by default.
- Fixed literal value detection.
- Consolidated processes for inferring signatures.
- Object resolution detects class methods.
- ApiMap collects method and variable pins while processing maps.
- Removed bundler requirement.
- Avoid preparing workspaces without explicit requests.

## 0.11.2 - September 5, 2017
- Include square brackets in signatures for type inference.
- Semi-colons terminate signatures.
- Detect literal values at the start of signatures.
- Eliminate threads in workspace preparation due to lag and sync issues.
- Classes only include instance methods from included modules one level deep.
- ApiMap recurses into children for constant nodes.

## 0.11.1 - August 24, 2017
- Find arguments node for singleton methods.
- Recurse into class << self when collecting singleton methods.
- Detect singleton method visibility.
- Find constants in ApiMap.
- Inferring signatures detects methods that return self.

## 0.11.0 - August 16, 2017
- Add space to = in attr_accessor suggestions.
- Refactored detection of assignment node types.
- ApiMap caches assignment node types.
- ApiMap checks method visibility.
- Smart switching between class and instance scope when inferring signature types.
- Private methods are available from included modules.
- Avoid infinite loops from variable assignments that reference themselves.
- Detect the self keyword when inferring signature types.
- Updated gemspec dependencies.

## 0.10.3 - August 13, 2017
- Return to master branch for releases.

## 0.10.2 - August 11, 2017
- Chained method call inference.
- Detect class and instance variables in signatures.
- ApiMap caches inferred signature types.

## 0.10.1 - August 11, 2017
- CodeMap signature typing detects method arguments.
- Miscellaneous nil checks.
- Fixed yieldparam detection.
- Clean namespace strings for return types with subtypes.

## 0.10.0 - August 9, 2017
- YardMap#get_constants filters for classes, modules, and constants.
- Suggestions allow Constant as a kind attribute.
- Class variable support.
- Detect variables that directly references classes instead of instances.
- Detect and infer types for yield params.

## 0.9.2 - August 7, 2017
- Add block parameter variables to suggestions.

## 0.9.1 - August 1, 2017
- YardMap fixes.
- Workaround for paths in HTML helper.
- Extract default values for optional arguments from code.
- Parse param tags in suggestions.
- Show return types for method params.
- CodeMap detects comments.
- Solargraph config subcommand writes to .solargraph.yml.

## 0.9.0 - June 27, 2017
- Run GC after each server request.
- ApiMap appends all .rb files in workspace.
- Emulate YARD when parsing comments in ApiMap.
- Include modules in ApiMap inner instance methods.
- Configure ApiMap file options in .solargraph.yml.

## 0.8.6 - June 14, 2017
- ApiMap#update_yardoc sets workspace from thread. Retain docstring in suggestions.
- ApiMap#update_yardoc uses .yardopts directly for globs.
- CodeMap#filename path separator hack.
- Include all arguments in ApiMap instance method suggestions. Nil filename exception in CodeMap.

## 0.8.5 - June 12, 2017
- Exclude Kernel module when querying namespace instance methods.

## 0.8.4 - June 11, 2017
- Sort and filter for suggestions.
- CodeMap#namespace_from returns empty string instead of first node for nodes without locations.
- Improved error handling.
- Suggestions include return types.
- Convert RDoc to HTML in Suggestion#documentation.
- Instance methods in suggestions include superclass and mixin methods.

## 0.8.3 - June 8, 2017
- Improved detection of cursors inside strings.
- Property and Field kinds for suggestions.

## 0.8.2 - June 3, 2017
- Suggestions and inferences for method arguments.

## 0.8.1 - May 31, 2017
- Server uses Webrick.

## 0.8.0 - May 29, 2017
- Method suggestions include arguments.
- Use CodeMap#signature_at to get suggestions for method arguments.
- Server includes /signify endpoint for method arguments.
- First support for hover documentation.
- Handle multi-part constants in namespaces, e.g., "class Foo::Bar"
- Use #initialize documentation for #new methods.
- More HTML formatting helpers.
- Improved type detection for local variables.
- Long/complex signature handling.

## 0.7.5 - May 12, 2017
- Improved live error correction and instance variable suggestions.
