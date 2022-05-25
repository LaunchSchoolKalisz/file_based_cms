require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'
require 'redcarpet'

root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

get "/" do
  @files = Dir.glob(root + "/documents/*").map do |path|
    File.basename(path)
  end

  erb :index, layout: :layout
end

get "/documents/:filename" do
  file_path = root + "/documents/" + params[:filename]

  if File.file?(file_path)
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

