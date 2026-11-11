# frozen_string_literal: true

describe Solargraph::Page do
  describe '#render' do
    it 'renders a template to a String' do
      expect(described_class.new.render('document', layout: false, locals: { pins: [] })).to be_a(String)
    end

    it 'raises a TypeError when the template does not render a String' do
      allow(Tilt::ERBTemplate).to receive(:new).and_return(instance_double(Tilt::ERBTemplate, render: nil))
      expect { described_class.new.render('document', layout: false) }.to raise_error(TypeError)
    end
  end
end
