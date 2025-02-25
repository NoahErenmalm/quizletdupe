require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:index)
end

get('/register') do
    slim(:register)
end

post('/registering') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    db = SQLite3::Database.new('./db/database.db')

    validate_register_account(username, password, db)

    session[:username] = username
    
    redirect('/')
end

get('/login') do
    slim(:login)
end

post('/logging') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    user_data = db.execute("SELECT UserId, Username, Password FROM Users WHERE Username = ?", username).first

    password_digest = BCrypt::Password.create(password)

    if user_data != nil
        if username == user_data["Username"] && password_digest == user_data["Password"]
            session[:username] = user_data["Username"]
            session[:userId] = user_data["UserId"]
        else
            session[:login_error] = "Wrong password"
            redirect('/login')
        end
    else
        session[:login_error] = "Wrong password"
        redirect('/login')
    end

    redirect('/')
end