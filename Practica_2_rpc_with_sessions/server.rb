require 'sinatra'

enable :sessions

# before we process a route we'll set the response as plain text
# and set up an array of viable moves that a player (and the
# computer) can perform
before do
	session[:computer] = 0 unless session.include?(:computer);
	session[:player] = 0 unless session.include?(:player);
  @defeat = { :rock => :scissors, :paper => :rock, :scissors => :paper}
  @throws = @defeat.keys
end

get '/' do
    haml :index
end

post '/jugar' do
	@option=params[:option]
	redirect "/throw/#{@option}"
end

post '/reset' do
	session.clear
	session[:computer] = 0
	session[:player] = 0
	redirect '/'
end

get '/throw/:type' do
  # the params hash stores querystring and form data
  @player_throw = params[:type].to_sym

  halt(403, "You must throw one of the following: '#{@throws.join(', ')}'") unless @throws.include? @player_throw

  @computer_throw = @throws.sample

  if @player_throw == @computer_throw
    @answer = "There is a tie"
  elsif @player_throw == @defeat[@computer_throw]
    @answer = "Computer wins; #{@computer_throw} defeats #{@player_throw}"
    session[:computer] = session[:computer] + 1
  else
    @answer = "Well done. #{@player_throw} beats #{@computer_throw}"
    session[:player] = session[:player] + 1
  end
  haml :results
end
