require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/about' do

  #@error = "test on error"
  erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do
  session[:username] = params['username']
  session[:phone] = params['phone']
  session[:datetime] = params['datetime']
  session[:barber] = params['barber']
  session[:color] = params['color']

  hh_v = {  :username => 'Enter name',
          :phone => 'Enter phone',
          :datetime => 'Enter datetime'}

  @error = hh_v.select {|key,_| params[key] == ""}.values.join(", ")
  if @error != ''
      return erb :visit
  end

  f = File.open './public/users.txt', 'a'
  f.write "username: #{session[:username]}, phone: #{session[:phone]}, datetime: #{session[:datetime]}, barber: #{session[:barber]}, color: #{session[:color]}\n"
  f.close

  session[:username] = ''
  session[:phone] = ''
  session[:datetime] = ''
  session[:barber] = ''
  session[:color] = ''
  erb 'Дорогой <%=session[:username]%>, ваша заявка принята на рассмотрение. Парикмахер <%=session[:barber]%> вам перезвонит!'
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  session[:email] = params['email']
  session[:message] = params['message']

  hh_c = {:email => 'Enter email',
          :message => 'Enter message'}

  @error = hh_c.select {|key,_| params[key] == ""}.values.join(", ")
  if @error != ''
      return erb :contacts
  end


  f = File.open './public/messages.txt', 'a'
  f.write "email: #{session[:email]}, message: #{session[:message]}\n"
  f.close

  session[:email] = ''
  session[:message] = ''  
  erb 'Дорогой <%=session[:username]%>, вашe сообщение принято. Мы вам ответим в близжайшее время!'
end


get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  session[:password] = params['password']

  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> with password <%=session[:password]%> has access to!'
end
