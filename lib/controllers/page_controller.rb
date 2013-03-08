class PageController < BaseController
  get '/' do
    @page = Page.first
    haml :show
  end

  get '/list' do
    @pages = Page.all
    haml :index
  end

  get '/new' do
    haml :new
  end

  get '/:id' do |slug|
    @page = Page[slug: slug]
    haml :show
  end

  post '/new' do
    page = Page.create(title: params[:title], content: params[:content], markup: params[:markup])
    redirect "#{page.slug}"
  end

  get '/:id/edit' do |slug|
    @page = Page[slug: slug]
    haml :edit
  end

  # Borde vara put
  post '/:id' do |slug: slug|
    page = Page[slug: slug]
    page.update(title: params[:title], content: params[:content], markup: params[:markup])

    redirect "#{page.slug}"
  end
end