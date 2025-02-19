
def validate_register_account(username, password, db)
    password_confirm = params[:password_confirm]
    if password != password_confirm
        session[:register_error] = "Passwords don't match"
        redirect('/register')
    elsif password.length < 5 || password.length > 25
        session[:register_error] = "Passwords must be inbetween 5 and 25 characters"
        redirect('/register')
    elsif db.execute("SELECT Username FROM users WHERE Username=?", username).any?
        session[:register_error] = "Username is already taken"
        redirect('/register')
    end

    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (Username, Password) VALUES (?, ?)", [username, password_digest])
end