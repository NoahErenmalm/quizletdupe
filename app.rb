require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

before do
    check_activity()
end

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
    login_request(username, password, db)
    redirect('/')
end

get('/login') do
    slim(:login)
end

post('/logging') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('./db/database.db')

    login_request(username, password, db)
    redirect('/')
end

get('/quiz/create') do
    slim(:quizcreator)
end

post('/quiz/creating') do
    
    questions = params[:questions_text]
    answers = params[:answers]
    images = params[:question_image]


    validate_quiz(questions, answers)

    redirect('/')
end
