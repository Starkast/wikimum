class UserController < BaseController
  get '/' do
    @user = User[session.fetch(:user_id)] || User.new
    @user_info = session.fetch(:user_info) || []
    haml :show
  end
end
