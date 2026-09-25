# frozen_string_literal: true

require 'tmpdir'

# Two workspace folders open at once should not each pay to deserialize the
# same gem. Asking for a gem's pins from two workspaces in one process is what
# an editor does with two folders open, and the pins that come back are the
# same objects when the work was done once.
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
