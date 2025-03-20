
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

def validate_quiz_images(images) 
    if images
        images.each do |image|
            next unless image && image[:tempfile] #Vill även lägga till felhantering för för stora bilder.
            
            file_extension = File.extname(image[:filename]).downcase
            allowed_extensoins = [".png", ".jpg", ".jpeg"]

            unless allowed_extensoins.include?(file_extension)
                flash[:quiz_error] = "Invalid image format"
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
    if visibility
        visibility = 1
    else
        visibility = 0
    end
    #length of quiz
    size = questions.length
    #metadata
    db.transaction do
        db.execute("INSERT INTO quiz (UserId, Title, Size, Private) VALUES (?, ?, ?, ?)", [session[:userId], title, size, visibility])
        last_id = db.last_insert_row_id

        questions.each_with_index do |question, index|
            answer = answers[index]
            image_path = images && images[index] && !images[index].empty? ? upload_image(images, index) : nil

            quiz_meta = db.execute("INSERT INTO questions (QuizId, question, answer, image) VALUES(?, ?, ?, ?)",[last_id, question, answer, image_path])
        end
    end
end

def upload_image(images, index)
    p images[index]
    p images
    if images[index] != nil
        file_extension = File.extname(images[index][:filename]).downcase
        filename = SecureRandom.alphanumeric(24)
        filename << file_extension
        path = "./public/quizImages/#{filename}"
        file = images[index][:tempfile]
        File.open(path, 'wb') do |f|
            f.write(file.read)
        end
        return path
    else
        return nil
    end
end