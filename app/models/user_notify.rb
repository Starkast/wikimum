class UserNotify < ActionMailer::Base

  def signup(user)
    @subject      = "Registrering på #{WikiConf['main']['name']}"
    @body['name'] = user.name
    @body['login'] = user.login
    @body['url']  = WikiConf['main']['address']
    @recipients   = user.email
    @from         = WikiConf['mail']['sender']
  end

end
