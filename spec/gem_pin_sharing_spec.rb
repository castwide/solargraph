# frozen_string_literal: true

require 'tmpdir'

# Two workspace folders open at once get the same pin objects for a gem they
# share, which is what https://github.com/castwide/solargraph/pull/983 restored
# after they had become one set per DocMap. Identity is the point rather than
# equality: a pin memoizes its macros and its namespace, so the second folder
# indexes pins whose answers are already worked out. Given fresh copies it does
# that work again, around two and a half times the calls into Pin::Base#macros
# and ApiMap::Index#path_pin_hash.
describe Solargraph::ApiMap do
  # @param directory [String]
  # @return [Array<Solargraph::Pin::Base>]
  def server_pins directory
    described_class.load_with_cache(directory, nil).get_path_pins('Backport::Server')
  end

  it 'serves a second workspace the pins it already built for the first' do
    Dir.mktmpdir do |first|
      Dir.mktmpdir do |second|
        [first, second].each { |dir| File.write(File.join(dir, 'app.rb'), "require 'backport'\n") }

        from_first = server_pins(first)
        from_second = server_pins(second)

        expect(from_second.first).to equal(from_first.first)
      end
    end
  end
end
