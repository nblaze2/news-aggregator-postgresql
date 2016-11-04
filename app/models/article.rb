require 'uri'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

class Article
  attr_reader :title, :url, :description, :errors

  def initialize(article_hash = {})
    @title = article_hash["title"]
    @url = article_hash["url"]
    @description = article_hash["description"]
    @errors = {}
  end

  def self.all
    @articles = []
    article_db = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles")}
    article_db.each do |article|
      @articles << Article.new(article)
    end
      @articles
  end

  def valid?
    if @title.strip.empty?
      @errors[:title] = "Please completely fill out form"
    end

    url_test = @url =~ URI::regexp
    url_dup_check = db_connection { |conn| conn.exec("SELECT url FROM articles WHERE url = '#{url}'")}
    if @url.strip.empty?
      @errors[:url] = "Please completely fill out form"
    elsif url_test.nil? && url.strip.length > 0
      @errors[:url] = "Invalid URL"
    end

    if !url_dup_check.first.nil?
      @errors[:url] = "Article with same url already submitted"
    end

    if @description.strip.empty?
      @errors[:description] = "Please completely fill out form"
    elsif @description.length < 20
      @errors[:description] = "Description must be at least 20 characters long"
    end

    if @errors.keys.empty?
      return true
    else
      return false
    end
  end

  def save
    if valid?
      db_connection do |conn|
        conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, url, description])
      end
      return true
    else
      return false
    end
  end

end
