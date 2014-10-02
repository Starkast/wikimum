class PageController < BaseController

  helpers do
    def slug
      Slug.slugify(params[:slug]) if params[:slug]
    end

    def restrict_concealed(page)
      return if starkast?
      if page.concealed
        flash[:error] = "Not authorized!"

        redirect back
      end
    end
  end

  get '/' do
    @page = Page.order(:id).first
    redirect "new" unless @page
    haml :show
  end

  get '/list' do
    @page_groups = Page.order(:title_char, :title).to_hash_groups(:title_char)
    haml :index
  end

  get '/latest' do
    @page_groups = Page.order(:updated_on).reverse.
      eager_graph(:author).
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
    page = Page.new
    page.set_fields(params, %i(title content description comment))
    page.author = current_user
    page.save
    redirect "#{page.slug}"
  end

  get '/new' do
    redirect back unless logged_in?
    @page = Page.new
    haml :new
  end

  get '/new/:slug' do
    redirect back unless logged_in?
    @page = Page.new(title: slug)
    flash.now[:notice] = "Det finns ingen sida för #{slug}, du får skapa den!"
    haml :new
  end

  get '/:slug/edit' do
    @page = Page.find(slug: slug)
    restrict_concealed(@page)
    haml :edit
  end

  get '/:slug' do
    @page = Page.find(slug: slug)
    redirect "new/#{slug}" unless @page
    restrict_concealed(@page)
    haml :show
  end

  get '/:slug/:revision' do |_, revision|
    @page = Revision.where(slug: slug, revision: revision).first
    redirect "#{slug}" unless @page
    restrict_concealed(@page)
    haml :show
  end

  post '/:slug' do
    page = Page.find(slug: slug)
    restrict_concealed(page)
    page.revise!
    page.set_fields(params, %i(title content description comment))
    page.author = current_user
    page.save

    redirect "#{page.slug}"
  end

  post '/:slug/conceal' do
    page = Page.find(slug: slug)
    restrict_concealed(page)

    # intentionally avoid Page save hook
    page.this.update(concealed: !page.concealed)

    redirect "#{page.slug}"
  end
end
