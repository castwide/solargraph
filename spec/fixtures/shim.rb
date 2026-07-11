# frozen_string_literal: true

# A shim for running Solargraph shell commands in tests without using the
# bundled environment

$LOAD_PATH.unshift File.realpath(File.join(__dir__, '..', '..', 'lib'))
load File.join(__dir__, '..', '..', 'bin', 'solargraph')
