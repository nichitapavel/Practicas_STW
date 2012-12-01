require 'sinatra'
require 'sinatra/activerecord'
require 'haml'
require 'xmlsimple'
require 'rest-client'

set :database, 'sqlite3:///shortened_urls.db'
set :address, 'localhost:4567'
#set :address, 'exthost.etsii.ull.es:4567'

class ShortenedUrl < ActiveRecord::Base
  has_many :visits
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

class Visit < ActiveRecord::Base
  belongs_to :shortenedurl
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
  @ip = request.ip
  #@ip = "81.34.82.166"
  xml = RestClient.get "http://api.hostip.info/get_xml.php?ip=#{@ip}"
  @country = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['featureMember']['Hostip']['countryName']
  @country.capitalize!
  short_url = ShortenedUrl.find_by_custom(params[:shortened])
  begin
    short_url.visits << Visit.create(:ip => @ip, :country => @country, :shortened_url_id => short_url.id )
    short_url.save
    redirect short_url.url
  rescue
    short_url = ShortenedUrl.find(params[:shortened].to_i(36)) 
    short_url.visits << Visit.create(:ip => @ip, :country => @country, :shortened_url_id => short_url.id )
    short_url.save
    redirect short_url.url
  end
end

get '/visits/:shortened' do
  short_url = ShortenedUrl.find_by_custom(params[:shortened])
  begin
    $visitas = Visit.where(:shortened_url_id => short_url.id)
    $link = 'http://' + settings.address + '/' + short_url.custom_url
  rescue
    short_url = ShortenedUrl.find_by_id(params[:shortened].to_i(36))
    $visitas = Visit.where(:shortened_url_id => short_url.id)
    $link = 'http://' + settings.address + '/' + (short_url.id).to_s
  end
  $url = short_url.url
  $short_url = short_url.id
  haml :visits
end

post '/visits/:shortened' do
  @test = params[:country]
  country_visits = Visit.where(:country => params[:country], :shortened_url_id => $short_url)
  @result = country_visits.size.to_s
  @country = params[:country]
  haml :visits
end
