require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

root = File.expand_path("..", __FILE__)

get "/" do
  @files = Dir.glob(root + "/documents/*").map do |path|
    File.basename(path)
  end

  erb :index, layout: :layout
end

get "/documents/:filename" do
  file_path = root + "/documents/" + params[:filename]

  headers["Content-Type"] = "text/plain"
  File.read(file_path)
end
