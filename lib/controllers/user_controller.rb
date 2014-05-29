class UserController < BaseController
  get '/' do
    @user_info = session.fetch(:user_info) || []
    haml :show
  end
end
