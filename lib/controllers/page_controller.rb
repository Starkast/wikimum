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

  get '/:slug/uploads/:id/:filename?' do |_, id, _|
    upload = Upload[id.to_i]
    halt 404, "Upload not found" unless upload
    halt 404, "Upload not found" unless upload.page.slug == slug
    halt 404, "Upload not found" if upload.page.concealed && !starkast?

    # uploads to concealed pages should only be cached in a private cache,
    # such as a user's browser, not in shared caches like CDNs
    cache_directive = upload.page.concealed ? :private : :public

    cache_control cache_directive, max_age: 31536000
    content_type upload.content_type

    upload.data
  end

  get '/:slug/uploads' do
    page = Page.find(slug: slug)
    halt 404, "Page not found" unless page
    restrict_concealed(page)

    content_type :json
    page.uploads.map { |u| { id: u.id, filename: u.filename, path: u.path, markdown: u.markdown_reference, image: u.image? } }.to_json
  end

  post '/:slug/uploads' do
    halt 401, "Not authorized" unless logged_in?

    page = Page.find(slug: slug)
    halt 404, "Page not found" unless page
    restrict_concealed(page)

    file = params[:file]
    halt 400, "No file provided" unless file && file[:tempfile]

    upload = Upload.new(
      page: page,
      author: current_user,
      filename: file[:filename],
      content_type: file[:type] || "application/octet-stream",
      data: Sequel.blob(file[:tempfile].read)
    )
    upload.save

    content_type :json
    { id: upload.id, filename: upload.filename, path: upload.path, markdown: upload.markdown_reference, image: upload.image? }.to_json
  end

  delete '/:slug/uploads/:id' do |_, id|
    halt 401, "Not authorized" unless logged_in?

    upload = Upload[id.to_i]
    halt 404, "Upload not found" unless upload
    halt 404, "Upload not found" unless upload.page.slug == slug
    restrict_concealed(upload.page)

    upload.destroy

    content_type :json
    { success: true }.to_json
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
