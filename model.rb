
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
