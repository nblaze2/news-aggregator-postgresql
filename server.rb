require "sinatra"
require "pg"
require 'pry'
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
  @articles = Article.all
  erb :index
end

get '/articles/new' do
  erb :new
end

post '/articles' do
  @title = params['title']
  @url = params['url']
  @description = params['description']

  new_article = Article.new({"title" => @title, "url" => @url, "description" => @description})

  if new_article.valid?
    new_article.save
    redirect '/articles'
  else
    @errors = new_article.errors
    erb :new
  end
end
