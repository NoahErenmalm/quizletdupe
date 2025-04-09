require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require_relative './model.rb'
require 'securerandom'

include Model

enable :sessions

#Check activity
before do
    check_activity()
end

#Display home page
get('/') do
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    quizs = db.execute("SELECT * FROM quiz").shuffle

    @selected_quizs = quizs.take(20)

    slim(:index)
end

#Display registering page
get('/register') do
    slim(:register)
end

#Creates a new user account and redirect to home page
#
# username: The username of the user
# password: The password of the user
# password_confirm: The password confirmation of the user
# db: The database connection
post('/registering') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    db = SQLite3::Database.new('./db/database.db')

    validate_register_account(username, password, password_confirm, db)
    login_request(username, password, db)
    redirect('/')
end

#Display login page
get('/login') do
    slim(:login)
end

#Attempt to log in the user and redirect to home page
#
# username: The username of the user
# password: The password of the user
# db: The database connection
post('/logging') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('./db/database.db')

    login_request(username, password, db)
    redirect('/')
end

#Display a logout page and clear the session and redirect to home page
#
# session: The session of the user
get('/logout') do
    
    session.clear
    redirect('/')
end

#Display the quiz creation page
#Check if the user is logged in, if not redirect to login page
get('/quiz/create') do
    if !session[:userId]
        flash[:login_error] = "You have to be logged in to create a quiz..."
        redirect('/login')
    end
    slim(:"quiz/creator")
end

#Create a new quiz and redurect to the quiz page
#
# session: The session of the user
# db: The database connection
# questions: The questions of the quiz
# answers: The answers of the quiz
# images: The images of the quiz
# visibility: The visibility of the quiz
# title: The title of the quiz
# quiz_id: The id of the quiz
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

    quiz_id = db.execute("SELECT quizId FROM quiz WHERE UserId = ?", session[:userId]).last.first
    redirect("/quiz/#{quiz_id}")

end

#Display the quiz page
#
# quiz_id: The id of the quiz
# db: The database connection
# quiz_owner: The owner of the quiz
# @quiz: The quiz data
# @questions: The questions of the quiz
# @favorite: The favorite status of the quiz
# session: The session of the user
get('/quiz/:id') do
    quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    quiz_owner = db.execute("SELECT UserId, Private FROM quiz WHERE quizId = ?", quiz_id).first
    if quiz_owner["UserId"] != session[:userId] && quiz_owner["Private"] == 1
        redirect('/error')
    end

    @quiz = db.execute("SELECT * FROM quiz WHERE quizId = ?", quiz_id).first
    @questions = db.execute("SELECT * FROM questions WHERE QuizId = ?", quiz_id)
    @favorite = db.execute("SELECT UserId, QuizId FROM saves WHERE UserId = ? AND QuizId = ?", [quiz_owner["UserId"], @quiz["QuizId"]])

    slim(:"quiz/home")
end

#Display the quiz editing page
#Check if the user is logged in, if not redirect to login page
#
# quiz_id: The id of the quiz
# db: The database connection
# @quiz_meta: The quiz metadata
# @quiz_questions: The quiz questions
# session: The session of the user
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

#Update the quiz and redirect to the quiz page
#
# quiz_id: The id of the quiz
# db: The database connection
# questions: The questions of the quiz
# answers: The answers of the quiz
# images: The images of the quiz
# visibility: The visibility of the quiz
# title: The title of the quiz
# session: The session of the user
post('/quiz/:id/editing') do
    quiz_id = params[:id]
    if session[:userId].nil?
        redirect("/error")
    else
        user_id = session[:userId]
    end
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

    edit_quiz_update_favorite(user_id, quiz_id, db, visibility)

    redirect("/quiz/#{quiz_id}")
end

#Delete the quiz and redirect to the profile page
#
# quiz_id: The id of the quiz
# db: The database connection
# quiz_owner: The owner of the quiz
# session: The session of the user
post('/quiz/:id/delete') do
    quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    quiz_owner = db.execute("SELECT UserId FROM quiz WHERE QuizId = ?", quiz_id).first
    if quiz_owner["UserId"].to_i != session[:userId]
        redirect('/error')
    end

    delete_quiz(quiz_id, db)
    unfavorite_quiz(nil, quiz_id, db)

    redirect("./profile/#{quiz_owner["UserId"]}")
end

#Display quiz test page(typing test)
#
# @quiz_id: The id of the quiz
# db: The database connection
# @data: The quiz data
get('/quiz/:id/test/typing') do
    @quiz_id = params[:id]
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    @data = db.execute("SELECT question, answer, image FROM questions WHERE QuizId = ?", @quiz_id).shuffle
    slim(:"/quiz/tests/typing")
end

#Dipsplay profile page
#
# @user_id: The id of the user
# db: The database connection
# @username: The username of the user
# @quizs: The quizs of the user
get('/profile/:id') do
    @user_id = params[:id]

    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    @username = db.execute("SELECT Username FROM users WHERE userId = ?", @user_id).first
    @quizs = db.execute("SELECT * FROM quiz WHERE userId = ?", @user_id)

    slim(:"profile/profile")
end

#Display the error page
get('/error') do
    slim(:error)
end

#Diplsay the the favoruites of a user
#Check if the user is logged in, if not redirect to login page
#
# user_id: The id of the user
# db: The database connection
# session: The session of the user
get('/profile/:id/favorites') do
    user_id = params[:id].to_i
    if session[:userId].to_i != user_id
        redirect('/error')
    end

    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true

    load_favorite_quiz(user_id, db)

    slim(:"profile/favorites")
end

#Favorite a quiz and redirect to the said quiz's page
#
# quiz_id: The id of the quiz
# user_id: The id of the user
# db: The database connection
# session: The session of the user
post('/quiz/:id/favouriting') do
    quiz_id = params[:id]
    if !session[:userId]
        flash[:login_error] = "You have to be logged in to save a quiz..."
        redirect('/login')
    else
        user_id = session[:userId]
    end
    db = SQLite3::Database.new('./db/database.db')
    db.results_as_hash = true
    
    favorite_quiz(user_id, quiz_id, db)

    redirect("/quiz/#{quiz_id}")
end

#Unfavorite a quiz and redirect to the said quiz's page
#
# quiz_id: The id of the quiz
# user_id: The id of the user
# db: The database connection
# session: The session of the user
post('/quiz/:id/unfavouriting') do
    quiz_id = params[:id]
    if !session[:userId]
        flash[:login_error] = "You have to be logged in to save a quiz..."
        redirect('/login')
    else
        user_id = session[:userId]
    end
    db = SQLite3::Database.new('./db/database.db')
    
    unfavorite_quiz(user_id, quiz_id, db)

    redirect("/quiz/#{quiz_id}")
end
