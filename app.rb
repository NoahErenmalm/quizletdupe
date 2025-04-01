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
    slim(:"quiz/creator")
end

post('/quiz/creating') do

    if !session[:userId]
        flash[:login_error] = "You have to be logged in to create a quiz..."
        redirect('/login')
    end

    db = SQLite3::Database.new('./db/database.db')
    questions = params[:questions_text]
    answers = params[:answers]
    images = params[:questions_image]
    visibility = params[:visibility]
    title = params[:title]

    images = format_image_array(images)

    validate_quiz_meta(title)
    validate_quiz_text(questions, answers)
    validate_quiz_images(images)

    upload_quiz(questions, answers, images, title, visibility, db)

    redirect('/')
end

get('/quiz/:id') do
    quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    quiz_owner = db.execute("SELECT UserId FROM quiz WHERE quizId = ?", quiz_id).first
    if quiz_owner["UserId"] != session[:userId]
        redirect('/error')
    end

    @quiz = db.execute("SELECT * FROM quiz WHERE quizId = ?", quiz_id).first
    @questions = db.execute("SELECT * FROM questions WHERE QuizId = ?", quiz_id)

    slim(:"quiz/home")
end

get('/quiz/:id/edit') do
    quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    @quiz_meta = db.execute("SELECT * FROM quiz WHERE quizId = ?", quiz_id).first

    @quiz_questions = db.execute("SELECT * FROM questions WHERE QuizId = ?", quiz_id)

    if session[:userId] != @quiz_meta["UserId"]
        redirect('/error')
    end
    slim(:"quiz/edit")
end

post('/quiz/:id/editing') do
    quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    questions = params[:questions_text]
    answers = params[:answers]
    images = params[:questions_image]
    visibility = params[:visibility]
    title = params[:title]

    images = format_image_array(images)

    validate_quiz_meta(title)
    validate_quiz_text(questions, answers)
    validate_quiz_images(images)

    update_quiz(questions, answers, images, title, visibility, quiz_id, db)
    
    redirect("/quiz/#{quiz_id}")
end

get('/quiz/:id/test/typing') do
    @quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    @data = db.execute("SELECT question, answer, image FROM questions WHERE QuizId = ?", @quiz_id).shuffle
    slim(:"/quiz/tests/typing")
end

get('/profile/:id') do
    user_id = params[:id]

    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    @username = db.execute("SELECT Username FROM users WHERE userId = ?", user_id).first
    @quizs = db.execute("SELECT * FROM quiz WHERE userId = ?", user_id)

    slim(:"profile/profile")
end

get('/error') do
    slim(:error)
end

get('/profile/:id/favorites') do
    user_id = params[:id]
    if session[:userId] != user_id
        redirect('/error')
    end

    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    #inte klar

    slim(:"profile/favorites")
end
