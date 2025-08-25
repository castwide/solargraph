require 'bundler/inline'

# Ensure the required gems are installed
gemfile do
  source 'https://rubygems.org'
  gem 'benchmark-memory'
  gem 'benchmark-ips'
end


large_string = (0..1_000).map { |i| i.to_s * 100 }.join

def from_offset_each_char text, offset
  cursor = 0
  line = 0
  character = nil
  char_index = 0
  text.each_char do |char|
    if cursor == offset
      character = char_index
      break
    end

    if char == "\n"
      line += 1
      char_index = 0
    else
      char_index += 1
    end

    cursor += 1
  end
  character = 0 if character.nil? and (cursor - offset).between?(0, 1)
end

def from_offset_each_line text, offset
  cursor = 0
  line = 0
  character = nil
  text.each_line do |l|
    line_length = l.length

    if l.end_with?("\n") || l.end_with?("\r\n")
      char_length = line_length - 1
    else
      char_length = line_length
    end

    if cursor + char_length >= offset
      character = offset - cursor
      break
    end
    cursor += line_length
    line += 1
  end
  character = 0 if character.nil? and (cursor - offset).between?(0, 1)
end


def from_offset_old text, offset
  cursor = 0
  line = 0
  character = nil
  text.lines.each do |l|
    line_length = l.length
    char_length = l.chomp.length
    if cursor + char_length >= offset
      character = offset - cursor
      break
    end
    cursor += line_length
    line += 1
  end
  character = 0 if character.nil? and (cursor - offset).between?(0, 1)
end

offset = 10_000_000

Benchmark.memory do |x|
  x.report("string.lines.each") do
    from_offset_old(large_string, offset)
  end

  x.report("string.each_line") do
    from_offset_each_line(large_string, offset)
  end

  x.report("string.each_char") do
    from_offset_each_char(large_string, offset)
  end

  x.compare!
end


Benchmark.ips do |x|
  x.report("string.lines.each") do
    from_offset_old(large_string, offset)
  end

  x.report("string.each_line") do
    from_offset_each_line(large_string, offset)
  end

  x.report("string.each_char") do
    from_offset_each_char(large_string, offset)
  end

  x.compare!
end
