 require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'pony'
require 'sqlite3'

#SQL Example ---------- TO BE DELETED
# db = SQLite3::Database.new 'test.db'
# db.execute "SELECT * FROM Messages" do |message|
#   puts message
#   puts "======"
# end
# db.close
#------------------------------------
 def get_db
    db = SQLite3::Database.new 'BarberShop.db'
    db.results_as_hash = true
    return db
 end

# run each restart time (initialization)
configure do
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS 
      "Users" 
      (
          "Id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
           "Name" TEXT NOT NULL, 
           "Phone" TEXT, 
           "DateStamp" TEXT, 
           "Barber" TEXT, 
           "Color" TEXT
      )'

  db.execute 'CREATE TABLE IF NOT EXISTS 
      "Contacts" 
      (
            "Id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE, 
            "Email" TEXT, 
            "Message" TEXT
      )'

  db.execute 'CREATE TABLE IF NOT EXISTS 
      "Barbers" 
      (
        "Id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 
        "Name" TEXT NOT NULL , 
        "Surname" TEXT
        )' 

  @arr_barbers = db.execute 'SELECT * FROM Barbers'
  if @arr_barbers.empty?  
    db.execute 'INSERT INTO "Barbers" VALUES (1,"Angela","Woodman");'
    db.execute 'INSERT INTO "Barbers" VALUES (2,"Lisa","Ashley");'
    db.execute 'INSERT INTO "Barbers" VALUES (3,"Jessie","Pinkman");'
    db.execute 'INSERT INTO "Barbers" VALUES (4,"Gabriel","Orchid");'
    db.execute 'INSERT INTO "Barbers" VALUES (5,"Samantha","Kerton");'
  end
  @arr_barbers = db.execute 'SELECT * FROM Barbers'

  db.close if db
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

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  session[:password] = params['password']

  erb :visit 
#  where_user_came_from = session[:previous_url] || '/'
#  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> with password <%=session[:password]%> has access to!'
end

get '/secure/*' do
  erb 'some error'
end

#-------------------------------------------------------------

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/about' do

  #@error = "test on error"
  erb :about
end

get '/visit' do
  db = get_db
  @arr_barbers = db.execute 'SELECT * FROM Barbers'
  db.close if db

  erb :visit
end

post '/visit' do
  session[:username] = params['username']
  session[:phone] = params['phone']
  session[:datetime] = params['datetime']
  session[:barber] = params['barber']
  session[:color] = params['color']

  hh_v = {:username => 'Enter name',
          :phone => 'Enter phone',
          :datetime => 'Enter datetime'}

  #WHY it's not global????
  db = get_db
  @arr_barbers = db.execute 'SELECT * FROM Barbers'
  db.close if db

  @error = hh_v.select {|key,_| params[key] == ""}.values.join(", ")
  if @error != ''
      return erb :visit
  end

  # to be deleted
  f = File.open './public/users.txt', 'a'
  f.write "username: #{session[:username]}, phone: #{session[:phone]}, datetime: #{session[:datetime]}, barber: #{session[:barber]}, color: #{session[:color]}\n"
  f.close
  #--------------

  db = get_db
  db.execute 'INSERT INTO 
      Users
      (
          Name,
          Phone,
          DateStamp,
          Barber,
          Color
      )
      values (?,?,?,?,?)', 
      [session[:username], session[:phone], session[:datetime], session[:barber], session[:color]]
  db.close if db

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

  Pony.mail(
#    :name => session[:username],
#    :mail => session[:email],
#    :body => session[:message],
    :to => 'tassadars@gmail.com',
    :subject => session[:username].to_s + " has contacted you",
    :body => session[:message],
    :via => :smtp,
    :via_options => { 
      :address              => 'smtp.gmail.com', 
      :port                 => '587', 
      :enable_starttls_auto => true, 
      :user_name            => 'tassadars', 
      :password             => 'tassusaderu02757513', 
      :authentication       => :plain, 
      :domain               => 'localhost.localdomain'
    }
  )

  session[:email] = ''
  session[:message] = ''  
  erb 'Дорогой <%=session[:username]%>, вашe сообщение принято. Мы вам ответим в близжайшее время!'
end

get '/showusers' do

  db = get_db
  @arr_hh = db.execute 'SELECT * FROM Users ORDER BY ID DESC'
  db.close if db

  erb :showusers
end