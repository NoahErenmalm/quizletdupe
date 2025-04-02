
def validate_register_account(username, password, db)
    password_confirm = params[:password_confirm]
    if password != password_confirm
        flash[:register_error] = "Passwords don't match"
        redirect('/register')
    elsif password.length < 5 || password.length > 25
        flash[:register_error] = "Passwords must be inbetween 5 and 25 characters"
        redirect('/register')
    elsif db.execute("SELECT Username FROM users WHERE Username=?", username).any?
        flash[:register_error] = "Username is already taken"
        redirect('/register')
    end

    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (Username, Password) VALUES (?, ?)", [username, password_digest])
end

def login(user_data)
    session[:username] = user_data["Username"]
    session[:userId] = user_data["UserId"]
end

def logout()
    session[:userId] = nil
    session[:username] = nil
    session[:last_seen] = nil
    redirect('/login')
end

def login_request(username, password, db)
    db.results_as_hash = true
    user_data = db.execute("SELECT UserId, Username, Password FROM Users WHERE Username = ?", username).first

    if user_data != nil
        if username == user_data["Username"] && BCrypt::Password.new(user_data["Password"]) == password
            login(user_data)
        else
            flash[:login_error] = "Wrong password"
            redirect('/login')
        end
    else
        flash[:login_error] = "Wrong password"  
        redirect('/login')
    end
end

def check_activity()
    if session[:userId] != nil
        if session[:last_seen] == nil
            session[:last_seen] = Time.now.to_i
        elsif Time.now.to_i - session[:last_seen] > 30*60
            session[:last_seen] = Time.now.to_i
            flash[:inactivity] = "You have been logged out due to inactivity."
            logout()
        end
        session[:last_seen] = Time.now.to_i
    end
end

def validate_quiz_text(questions, answers)
    if !questions || !answers || questions.empty? || answers.empty?
        errors << "Quiz must contain one or more questions..."

    else
        questions.each_with_index do |question, i|
            if question.strip.empty?
                flash[:quiz_error] = "Question #{i+1} cannot be blank..."
                redirect('/quiz/create')
            end
            if answers[i].strip.empty?
                flash[:quiz_error] = "Answer #{i+1} cannot be blank..."
                redirect('/quiz/create')
            end
        end
    end
end

def format_image_array(images)
    array = []
    n = 0
    if !images.empty?
        while n < images.length
            if images[n+1] == "" || images[n+1] == nil
                array << nil
                n += 1
            else
                array << images[n+1]
                n += 2
            end
        end
    end
    return array
end

def validate_quiz_images(images)
    if images
        images.each_with_index do |image, index|
            allowed_extensions = [".png", ".jpg", ".jpeg"]
            next if image.nil?

            if image.is_a?(String)
                file_extension = File.extname(image).downcase
                
                unless allowed_extensions.include?(file_extension)
                    flash[:quiz_error] = "Invalid image at index #{index}"
                    redirect('/quiz/create')
                end
            elsif image.is_a?(Hash) && image[:tempfile]
                file_extension = File.extname(image[:filename]).downcase

                unless allowed_extensions.include?(file_extension)
                    flash[:quiz_error] = "Invalid image image at index #{index}"
                    redirect('/quiz/create')
                end
            else

                flash[:quiz_error] = "Invalid image at index #{index}"
                redirect('/quiz/create')
            end
        end
    end
end
  

def validate_quiz_meta(title)
    if title == ""
        flash[:quiz_error] = "Quiz needs a title..."
        redirect('/quiz/create')
    end
end

def upload_quiz(questions, answers, images, title, visibility, db)
    #visibility handling
    visibility = visibility ? 1 : 0
    #length of quiz
    size = questions.length
    #metadata

    db.transaction do
        db.execute("INSERT INTO quiz (UserId, Title, Size, Private) VALUES (?, ?, ?, ?)", [session[:userId], title, size, visibility])
        last_id = db.last_insert_row_id

        questions.each_with_index do |question, index|
            answer = answers[index]
            image_path = upload_image(images, index, db)

            quiz_meta = db.execute("INSERT INTO questions (QuizId, question, answer, image) VALUES(?, ?, ?, ?)",[last_id, question, answer, image_path])
        end
    end
end

def upload_image(images, index, db)
    if images[index].is_a?(String)
        return images[index]
    elsif images[index] != nil 
        file_extension = File.extname(images[index][:filename]).downcase
        filename = SecureRandom.alphanumeric(24)
        filename << file_extension
        path = "./public/quizImages/#{filename}"
        file = images[index][:tempfile]
        File.open(path, 'wb') do |f|
            f.write(file.read)
        end
        return "/quizImages/#{filename}" 
    else
        return nil
    end
end

def update_quiz(questions, answers, images, title, visibility, quiz_id, db)
    visibility = visibility ? 1 : 0
    size = questions.length
    
    db.transaction do
        db.execute("UPDATE quiz SET Title = ?, Private = ? WHERE QuizId = ?", [title, visibility, quiz_id])

        db.execute("DELETE FROM questions WHERE QuizId = ?", quiz_id)

        questions.each_with_index do |question, index|
            answer = answers[index]
            image_path = upload_image(images, index, db)

            db.execute("INSERT INTO questions (QuizId, Question, Answer, Image) VALUES (?, ?, ?, ?)", [quiz_id, question, answer, image_path])
        end
    end
    cleanup_images()
end

def cleanup_images()
    db = SQLite3::Database.new('./db/database.db')

    images_db = db.execute("SELECT image FROM questions").flatten

    images_path = Dir.glob("./public/quizImages/*")
    images_path = images_path.map { |path| path.sub('./public', '') }

    unused_images = images_path.reject { |path| images_db.include?(path) }

    unused_images.each do |unused_image|
        full_path = "./public#{unused_image}" # Re-add './public' to get the full path
        File.delete(full_path) if File.exist?(full_path)
    end
end

def delete_quiz(quiz_id, db)
    db.execute("DELETE FROM quiz WHERE quizId = ?", quiz_id)
    db.execute("DELETE FROM questions WHERE quizId = ?", quiz_id)
end

def load_favorite_quiz(user_id, db)
    favorites = db.execute("SELECT QuizId FROM saves WHERE UserId = ?", user_id)
    quiz_ids = favorites.map { |favorite| favorite["QuizId"] }

    if quiz_ids.any?
        placeholders = quiz_ids.map { '?' }.join(', ')
        @quizs = db.execute("SELECT * FROM quiz WHERE quizId IN (#{placeholders})", quiz_ids)
    end
end

def favorite_quiz(user_id, quiz_id, db)
    if db.execute("SELECT UserId, QuizId FROM saves WHERE UserId = ? AND QuizId = ?", [user_id, quiz_id]).empty?
        db.execute("INSERT INTO saves (UserId, QuizId) VALUES (?, ?)", [user_id, quiz_id])
    else
        flash[:favourite_error] = "You already saved this quiz"
        redirect("/quiz/#{quiz_id}")
    end
end

def unfavorite_quiz(user_id, quiz_id, db)
    if user_id.nil?
        db.execute("DELETE FROM saves WHERE QuizId = ?", quiz_id)
    else
        db.execute("DELETE FROM saves WHERE UserId = ? AND QuizId = ?", [user_id, quiz_id])
    end
end

def edit_quiz_update_favorite(user_id, quiz_id, db, visibility)
    if visibility && !db.execute("SELECT UserId, QuizId FROM saves WHERE UserId = ? AND QuizId = ?", [user_id, quiz_id]).empty?
        unfavorite_quiz(nil, quiz_id, db)
        favorite_quiz(user_id, quiz_id, db)
    elsif visibility
        unfavorite_quiz(nil, quiz_id, db)
    end
end
