require 'sinatra'
require 'syntaxi'


# before we process a route we'll set the response as plain text
# and set up an array of viable moves that a player (and the
# computer) can perform

get '/' do
    erb :new
end

post '/' do
  @option2=params[:option]
  @option=params[:body].formatted_body(@option2)
  erb :show
end

class String
  def formatted_body(leng)
    source = "[code lang='#{leng}']
                #{self}
              [/code]"
    html = Syntaxi.new(source).process
    %Q{
      <div class="syntax syntax_#{leng}">
        #{html}
      </div>
    }
  end
end
