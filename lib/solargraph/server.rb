require 'sinatra/base'

module Solargraph
  class Server < Sinatra::Base
    set :port, 0

    post '/suggest' do
      content_type :json
      begin
        code_map = CodeMap.new(code: params['text'], filename: params['filename'])
        offset = code_map.get_offset(params['line'].to_i, params['col'].to_i)
        sugg = code_map.suggest_at(offset, with_snippets: true, filtered: true)
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message }.to_json
      end
    end
  end
end
