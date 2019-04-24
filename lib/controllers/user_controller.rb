class UserController < BaseController
  before do
    redirect '/' unless logged_in?
  end

  get '/' do
    @user = User[session.fetch(:user_id)] || User.new
    @user_info = session.fetch(:user_info, [])
    haml :show
  end
end
