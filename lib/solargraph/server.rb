require 'sinatra/base'

module Solargraph
  class Server < Sinatra::Base
    set :port, 56527
    set :bind, '0.0.0.0'
    set :mapper, Mapper.new

    post '/initialize' do
      content_type :json
      settings.mapper.set params['filename'], params['code']
      { "status" => "ok" }.to_json
    end
    
    post '/suggest' do
      content_type :json
      begin
        settings.mapper.set params['filename'], params['code']
        api_map = settings.mapper.get(params['filename'])
        raise 'No API map' if api_map.nil?
        map = Solargraph::CodeMap.new(params['script'], api_map: api_map, with_required: false)
        sugg = map.suggest_at(params['index'].to_i, with_snippets: true, filtered: true)
        { "status" => "ok", "suggestions" => sugg }.to_json
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        { "status" => "err", "message" => e.message }.to_json
      end
    end
  end
end
