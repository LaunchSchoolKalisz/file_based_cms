require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/documents/", __FILE__)
  else
    File.expand_path("../documents/", __FILE__)
  end
end

def signed_in?
  return true if session[:username]
  false
end

def check_sign_in_status
  if signed_in? == false
    session[:message] = "Please sign in to access that page."
    redirect "/"
  end
end

def valid_credentials?(username, password)
  credentials = load_users

  if credentials.key?(username) 
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else 
    false
  end
end

helpers do
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def load_file_content(path)
    content = File.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      erb render_markdown(content)
    end
  end

  def load_users
    YAML.load_file('users.yml')
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get "/documents/new" do
  check_sign_in_status

  erb :new
end

post "/documents/new" do
  check_sign_in_status
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A file name is required."
    status 422
    erb :new
  elsif filename[-4..-1] == ".txt" || filename[-3..-1] == ".md"
    file_path = File.join(data_path, filename)
    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."
    redirect "/"
  else
    session[:message] = "A file name ending in .md or .txt is required." 
    status 422
    erb :new
  end
end

get "/documents/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end


get "/documents/:filename/edit" do
  check_sign_in_status
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/documents/:filename" do
  check_sign_in_status
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."

  redirect "/"
end

post "/documents/:filename/destroy" do
  check_sign_in_status
  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  
  redirect "/"
end

get "/users/sign_in" do
  erb :sign_in
end

post "/users/sign_in" do
  approved_users = load_users
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :sign_in
  end
end

post "/users/sign_out" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end
