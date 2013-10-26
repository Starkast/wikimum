class PageController < BaseController
  get '/' do
    @page = Page.first
    haml :show
  end

  get '/list' do
    @pages = Page.order(:title)
    haml :index
  end

  get '/new' do
    haml :new
  end

  get '/search' do
    @pages = Page.search(params[:q])

    case @pages.count
    when 0
      flash[:notice] = "Din sökning gav inga träffar"
      redirect request.referrer
    when 1
      flash[:confirm] = "Din sökning gav bara denna sida som träff"
      redirect @pages.first.slug
    else
      flash.now[:confirm] = "Din sökning gav #{@pages.count} träffar"
      haml :search
    end
  end

  get '/:slug' do |slug|
    @page = Page.where(Sequel.ilike(:slug, slug)).first
    haml :show
  end

  post '/new' do
    page = Page.create(title: params[:title], content: params[:content],description: params[:description])
    redirect "#{page.slug}"
  end

  get '/:slug/edit' do |slug|
    @page = Page.where(Sequel.ilike(:slug, slug)).first
    haml :edit
  end

  # Borde vara put
  post '/:slug' do |slug|
    page = Page.where(Sequel.ilike(:slug, slug)).first
    page.update(title: params[:title], content: params[:content], description: params[:description])

    redirect "#{page.slug}"
  end
end
