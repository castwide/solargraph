require 'json'

module Solargraph
  SNIPPETS = JSON.parse '
    {
      "Exception block": {
        "prefix": "begin",
        "body": [
          "begin",
          "\t$1",
          "rescue => exception",
          "\t",
          "end"
        ]
      },
      "Exception block with ensure": {
        "prefix": "begin ensure",
        "body": [
          "begin",
          "\t$1",
          "rescue => exception",
          "\t",
          "ensure",
          "\t",
          "end"
        ]
      },
      "Exception block with else": {
        "prefix": "begin else",
        "body": [
          "begin",
          "\t$1",
          "rescue => exception",
          "\t",
          "else",
          "\t",
          "end"
        ]
      },
      "Exception block with else and ensure": {
        "prefix": "begin else ensure",
        "body": [
          "begin",
          "\t$1",
          "rescue => exception",
          "\t",
          "else",
          "\t",
          "ensure",
          "\t",
          "end"
        ]
      },
      "Class definition with initialize": {
        "prefix": "class init",
        "body": [
          "class ${ClassName}",
          "\tdef initialize",
          "\t\t$0",
          "\tend",
          "end"
        ]
      },
      "Class definition": {
        "prefix": "class",
        "body": [
          "class ${ClassName}",
          "\t$0",
          "end"
        ]
      },
      "for loop": {
        "prefix": "for",
        "body": [
          "for ${value} in ${enumerable} do",
          "\t$0",
          "end"
        ]
      },
      "if": {
        "prefix": "if",
        "body": [
          "if ${test}",
          "\t$0",
          "end"
        ]
      },
      "if else": {
        "prefix": "if else",
        "body": [
          "if ${test}",
          "\t$0",
          "else",
          "\t",
          "end"
        ]
      },
      "if elsif": {
        "prefix": "if elsif",
        "body": [
          "if ${test}",
          "\t$0",
          "elsif ",
          "\t",
          "end"
        ]
      },
      "if elsif else": {
        "prefix": "if elsif else",
        "body": [
          "if ${test}",
          "\t$0",
          "elsif ",
          "\t",
          "else",
          "\t",
          "end"
        ]
      },
      "forever loop": {
        "prefix": "loop",
        "body": [
          "loop do",
          "\t$0",
          "end"
        ]
      },
      "Module definition": {
        "prefix": "module",
        "body": [
          "module ${ModuleName}",
          "\t$0",
          "end"
        ]
      },
      "unless": {
        "prefix": "unless",
        "body": [
          "unless ${test}",
          "\t$0",
          "end"
        ]
      },
      "until loop": {
        "prefix": "until",
        "body": [
          "until ${test}",
          "\t$0",
          "end"
        ]
      },
      "while loop": {
        "prefix": "while",
        "body": [
          "while ${test}",
          "\t$0",
          "end"
        ]
      },
      "method definition": {
        "prefix": "def",
        "body": [
          "def ${method_name}",
          "\t$0",
          "end"
        ]
      }
    }
  '
end
