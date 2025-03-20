require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require_relative './model.rb'
require 'securerandom'

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
    if !session[:userId]
        flash[:login_error] = "You have to be logged in to create a quiz..."
        redirect('/login')
    end
    slim(:"quiz/quizcreator")
end

post('/quiz/creating') do

    db = SQLite3::Database.new('./db/database.db')
    questions = params[:questions_text]
    answers = params[:answers]
    images = params[:questions_image]
    visibility = params[:visibility]
    title = params[:title]
    

    validate_quiz_meta(title)
    validate_quiz_text(questions, answers)
    validate_quiz_images(images)


    #upload_image(images, 0)
    upload_quiz(questions, answers, images, title, visibility, db)


    redirect('/')
end

get('quiz/:id') do


    slim(:quiz/quizhome)

end