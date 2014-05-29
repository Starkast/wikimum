class PageController < BaseController
  get '/' do
    @page = Page.order(:id).first
    redirect "new" unless @page
    etag @page.sha1 unless logged_in?
    haml :show
  end

  get '/list' do
    @page_groups = Page.order(:title_char, :title).to_hash_groups(:title_char)
    haml :index
  end

  get '/latest' do
    @page_groups = Page.order(:updated_on).reverse.
      select_append(Sequel.lit("DATE(updated_on)")).
      to_hash_groups(:date)
    haml :latest
  end

  get '/search' do
    @pages = Page.search(params[:q])
    @q = params[:q]

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

  post '/new*' do
    page = Page.create(title: params[:title], content: params[:content],description: params[:description])
    redirect "#{page.slug}"
  end

  get '/new' do
    @page = Page.new
    haml :new
  end

  get '/new/:slug' do |slug|
    @page = Page.new(title: slug)
    flash.now[:notice] = "Det finns ingen sida för #{slug}, du får skapa den!"
    haml :new
  end

  get '/:slug/edit' do |slug|
    @page = Page.where(slug: slug.downcase).first
    haml :edit
  end

  get '/:slug' do |slug|
    @page = Page.where(slug: slug.downcase).first
    redirect "new/#{slug}" unless @page
    etag @page.sha1 unless logged_in?
    haml :show
  end

  get '/:slug/:revision' do |slug, revision|
    @page = Revision.where(slug: slug.downcase, revision: revision).first
    redirect "#{slug}" unless @page
    etag @page.sha1 unless logged_in?
    haml :show
  end

  # Borde vara put
  post '/:slug' do |slug|
    page = Page.where(slug: slug.downcase).first
    page.revise!
    page.update(title: params[:title], content: params[:content], description: params[:description], comment: params[:comment])

    redirect "#{page.slug}"
  end
end
