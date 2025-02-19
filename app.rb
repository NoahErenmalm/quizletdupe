require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:home)
end

get('/login') do
    slim(:login)
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
    
    redirect('/')
end

post('logging') do

end