require 'sinatra'
require 'sinatra/activerecord'
require 'haml'

set :database, 'sqlite3:///shortened_urls.db'
set :address, 'localhost:4567'
#set :address, 'exthost.etsii.ull.es:4567'

class ShortenedUrl < ActiveRecord::Base
  # Validates whether the value of the specified attributes are unique across the system.
  validates_uniqueness_of :url
  # Validates that the specified attributes are not blank
  validates_presence_of :url
  #validates_format_of :url, :with => /.*/
  validates_format_of :url,
       :with => %r{^(https?|ftp)://.+}i,
       :allow_blank => true,
       :message => "The URL must start with http://, https://, or ftp:// ."
end

get '/search_short_url' do
  haml :search_shorter_url
end

get '/search_url' do
  haml :search_url
end

get '/' do
  haml :index
end

post '/search_short_url' do
  begin
    @result = ShortenedUrl.find(params[:shorturl].to_i(36))   
  rescue 
    @result = ShortenedUrl.find_by_custom(params[:shorturl])
  end
  haml :search_shorter_url
end

post '/search_url' do
  @result = ShortenedUrl.find_by_url(params[:url])
  haml :search_url
end

post '/' do
  if params[:custom].empty?
    @short_url = ShortenedUrl.new(:url => params[:url], :custom => nil)
  else
    @short_url = ShortenedUrl.new(:url => params[:url], :custom => params[:custom])
    @check_custom = ShortenedUrl.find_by_custom(params[:custom])
  end
  if @short_url.valid? && @check_custom.nil?
    @short_url.save
    haml :success, :locals => { :address => settings.address }
  else
    haml :index
  end
end

get '/show' do
  urls = ShortenedUrl.find(:all)
  @url_list = []
  urls.each do |element|
    @url_list.push([element.url, element,  element.custom])
  end
  haml :show
end

get '/:shortened' do
  short_url = ShortenedUrl.find_by_custom(params[:shortened])
  begin
  redirect short_url.url
  rescue
    short_url = ShortenedUrl.find(params[:shortened].to_i(36))
    redirect short_url.url
  end
end