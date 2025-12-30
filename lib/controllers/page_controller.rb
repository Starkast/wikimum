# frozen_string_literal: true

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
    @page = Page.order(:id).first || Page.new(title: "Förstasidan")

    if @page.new? && logged_in?
      redirect "new"
    end

    @page_title = @page.title
    haml :show
  end

  get '/list' do
    @page_title = "Innehållsförteckning"
    @page_groups = Page.order(:title_char, :title)
      .with_concealed_if(starkast?)
      .to_hash_groups(:title_char)
    haml :index
  end

  get '/latest' do
    @page_title = "Senast ändrad"
    @page_groups = Page.order(:updated_on).reverse
      .with_concealed_if(starkast?)
      .eager_graph(:author)
      .add_graph_aliases(date: [:pages, :date, Sequel.lit("DATE(updated_on)")])
      .to_hash_groups(:date)
    haml :latest
  end

  get '/search' do
    @page_title = "Sökresultat"
    @pages = Page.with_concealed_if(starkast?).search(params[:q])
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
    @page = Page.new
    @page.set_fields(params, %i(title content description concealed comment))
    @page.author = current_user
    @page.save
    redirect "#{@page.slug_for_uri}"
  rescue Sequel::UniqueConstraintViolation
    flash.now[:error] = %(Sidan existerar redan: <a href="/#{@page.slug}">#{@page.slug}</a>)
    haml :new
  end

  get '/new' do
    unless logged_in?
      flash[:error] = "You need to be logged in to create a new page!"
      redirect "/"
    end
    @page_title = "Skapa ny sida"
    @page = Page.new
    haml :new
  end

  get '/new/:slug' do
    unless logged_in?
      flash[:error] = "You need to be logged in to create a new page!"
      redirect "/"
    end
    @page_title = "Skapa ny sida"
    @page = Page.new(title: slug)
    flash.now[:notice] = "Det finns ingen sida för #{slug}, du får skapa den!"
    haml :new
  end

  get '/:slug/edit' do
    @page = Page.find(slug: slug)
    unless logged_in?
      flash[:error] = "Not authorized to edit!"
      if @page
        redirect "/#{@page.slug_for_uri}"
      else
        redirect "/"
      end
    end
    redirect "new/#{slug}" unless @page
    @page_title = "Ändrar #{@page.title}"
    restrict_concealed(@page)
    @edit_mode = true
    haml :edit
  end

  post '/:slug/preview' do
    @page = Page.new
    @page.set_fields(params, %i(title content))
    @page_title = "Förhandsvisar #{@page.title}"
    @page.compiled_content = Markup.to_html(@page.content)
    haml :preview, layout: false
  end

  get '/:slug/' do
    redirect "/#{slug}"
  end

  get '/:slug' do
    @page = Page.find(slug: slug)
    redirect "new/#{slug}" unless @page
    @page_title = @page.title
    restrict_concealed(@page)
    haml :show
  end

  get '/:slug/:revision' do |_, revision|
    @page = Revision.where(slug: slug, revision: revision.to_i).first
    redirect "#{slug}" unless @page
    @page_title = "#{@page.title} (#{revision})"
    restrict_concealed(@page)
    haml :show
  end

  post '/:slug' do
    halt 400, "Missing title" if params[:title].to_s.empty?

    page = Page.find(slug: slug)
    restrict_concealed(page)
    page.revise!
    page.set_fields(params, %i(title content description comment))
    page.author = current_user
    page.save

    redirect "#{page.slug_for_uri}"
  end

  post '/:slug/conceal' do
    page = Page.find(slug: slug)
    restrict_concealed(page)

    # intentionally avoid Page save hook
    page.this.update(concealed: !page.concealed)

    redirect "#{page.slug_for_uri}"
  end
end
