require "sinatra"
require "pg"
require_relative "./app/models/article"

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/articles' do
  @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
  erb :index
end

get '/articles/new' do
  erb :new
end

post '/articles' do
  @error = {}
  @title = params['title']
  if @title.empty?
    @error[:title] = "Please completely fill out form"
  end

  @url = params['url']
  if @url.empty?
    @error[:url] = "Please completely fill out form"
  elsif !(@url.include?('www') && @url.include?('http'))
    @error[:url] = "Invalid URL"
  end

  url_arr = []
  db_connection do |conn|
    url_arr = conn.exec("SELECT url FROM articles").to_a
    if @url == url_arr[0]["url"]
      @error[:url] = "Article with same url already submitted"
    end
  end

  @description = params['description']
  if @description.empty?
    @error[:description] = "Please completely fill out form"
  elsif @description.length < 20
    @error[:description] = "Description must be at least 20 characters long"
  end

  if @error.keys.empty?
    db_connection do |conn|
      conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [@title, @url, @description])
    end
    redirect '/articles'
  else
    erb :new
  end
end
