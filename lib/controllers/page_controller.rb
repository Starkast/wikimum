# frozen_string_literal: true

class PageController < BaseController

  MAX_UPLOAD_SIZE = 25 * 1024 * 1024

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

    # Halts the response with 304 before the view renders when the browser's
    # If-None-Match matches. Components of the etag value:
    #
    #   - page.sha1 — content fingerprint, recomputed in Page#before_save.
    #   - page.concealed — `post '/:slug/conceal'` uses `page.this.update` and
    #     deliberately bypasses before_save, so sha1 doesn't reflect
    #     concealment toggles. Mix it in explicitly so the etag is in sync
    #     with what _actions.haml renders.
    #   - audience suffix (a/p for logged_in?, s/u for starkast?) — keeps
    #     anonymous, authed-not-starkast, and starkast renders in separate
    #     cache buckets so neither audience can receive another's body back
    #     from a 304.
    #
    # The audience suffix is defence in depth, not the access policy. Two
    # different logged-in users share the same etag but have different
    # `current_user.login` rendered in the layout — they must not be allowed
    # to share a cached body. Authed responses set Cache-Control: private to
    # keep them out of shared caches.
    def etag_for_page(page)
      etag [
        page.sha1,
        page.concealed ? "c" : "x",
        logged_in? ? "a" : "p",
        starkast? ? "s" : "u",
      ].join("-")
    end

    # Anonymous views are safe to cache in shared caches (nginx in front of
    # the app, browser): the rendered HTML doesn't include any per-user data
    # in the body. `no-cache` makes the browser revalidate every navigation
    # so the moment a visitor logs in, the next page load sees fresh chrome
    # — revalidation is cheap thanks to the ETag (304 with no body).
    # `s-maxage` controls shared caches (nginx); 10 minutes is the default
    # freshness window before nginx revalidates upstream.
    #
    # Authed views render edit/admin links and the current user, so they
    # must never end up in a shared cache and must not be stored locally
    # either (a browser-bookmarked authed page after logout would otherwise
    # flash admin chrome before re-render).
    def cache_for_audience
      if logged_in?
        cache_control :private, no_store: true
      else
        cache_control :public, :no_cache, s_maxage: 600
      end
    end
  end

  get '/' do
    @page = Page
      .select(:id, :slug, :title, :concealed, :revision, :updated_on, :compiled_content, :author_id, :sha1)
      .eager_graph(:author)
      .order(:id)
      .limit(1)
      .all
      .first || Page.new(title: "Förstasidan")

    if @page.new? && logged_in?
      redirect "new"
    end

    @page_title = @page.title
    cache_for_audience

    # Skipped for the empty-wiki fallback (Page.new has no sha1); that
    # response is cheap to render anyway.
    etag_for_page(@page) unless @page.new?

    haml :show
  end

  get '/list' do
    @page_title = "Innehållsförteckning"
    @page_groups = Page
      .select(:id, :slug, :title, :title_char, :revision, :concealed, :description)
      .order(:title_char, :title)
      .with_concealed_if(starkast?)
      .to_hash_groups(:title_char)
    cache_for_audience
    haml :index
  end

  get '/latest' do
    @page_title = "Senast ändrad"
    @page_groups = Page
      .select(:id, :slug, :title, :revision, :concealed, :comment, :updated_on, :author_id)
      .order(:updated_on).reverse
      .with_concealed_if(starkast?)
      .eager_graph(:author)
      .add_graph_aliases(date: [:pages, :date, Sequel.lit("DATE(updated_on)")])
      .to_hash_groups(:date)
    cache_for_audience
    haml :latest
  end

  get '/search' do
    @page_title = "Sökresultat"
    @noindex = true
    @q = params[:q]
    @pages = Page
      .select(:id, :slug, :title, :concealed, :description)
      .with_concealed_if(starkast?)
      .search(params[:q])
      .all

    case @pages.size
    when 0
      flash.now[:notice] = "Din sökning gav inga träffar"
      haml :search
    when 1
      flash[:confirm] = "Din sökning gav bara denna sida som träff"
      redirect @pages.first.slug
    else
      flash.now[:confirm] = "Din sökning gav #{@pages.size} träffar"
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

  post '/link-title' do
    url = params[:url].to_s
    halt 400, "Missing URL" if url.empty?
    halt 400, "Invalid URL" unless UrlValidator.safe?(url)

    content_type :json

    fetcher = App.link_title_fetcher
    result = fetcher.fetch_title(url)

    { url: url, title: result[:title], error: result[:error] }.compact.to_json
  end

  get '/:slug/edit' do
    @page = Page.with_slug(slug).first
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
    halt 404, "Upload not found" unless upload.page.slug.downcase == slug
    halt 404, "Upload not found" if upload.page.concealed && !starkast?

    # uploads to concealed pages should only be cached in a private cache,
    # such as a user's browser, not in shared caches like CDNs
    cache_directive = upload.page.concealed ? :private : :public

    cache_control cache_directive, max_age: 31536000
    content_type upload.content_type

    upload.data
  end

  get '/:slug/uploads' do
    page = Page.with_slug(slug).first
    halt 404, "Page not found" unless page
    restrict_concealed(page)

    content_type :json
    page.uploads.map { |u| { id: u.id, filename: u.filename, path: u.path, markdown: u.markdown_reference, image: u.image? } }.to_json
  end

  post '/:slug/uploads' do
    halt 401, "Not authorized" unless logged_in?

    page = Page.with_slug(slug).first
    halt 404, "Page not found" unless page
    restrict_concealed(page)

    file = params[:file]
    halt 400, "No file provided" unless file && file[:tempfile]
    halt 413, "File too large" if file[:tempfile].size > MAX_UPLOAD_SIZE

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
    halt 404, "Upload not found" unless upload.page.slug.downcase == slug
    restrict_concealed(upload.page)

    upload.destroy

    content_type :json
    { success: true }.to_json
  end

  get '/:slug/' do
    redirect "/#{slug}"
  end

  get '/:slug' do
    @page = Page
      .select(:id, :slug, :title, :concealed, :revision, :updated_on, :compiled_content, :author_id, :sha1)
      .eager_graph(:author)
      .with_slug(slug)
      .limit(1)
      .all
      .first
    redirect "new/#{slug}" unless @page
    @page_title = @page.title
    restrict_concealed(@page)
    cache_for_audience
    etag_for_page(@page)
    haml :show
  end

  get '/:slug/:revision' do |_, revision|
    @page = Revision.with_slug(slug).where(revision: revision.to_i).first
    redirect "#{slug}" unless @page
    @page_title = "#{@page.title} (#{revision})"
    restrict_concealed(@page)
    cache_for_audience
    haml :show
  end

  post '/:slug' do
    halt 400, "Missing title" if params[:title].to_s.empty?

    page = Page.with_slug(slug).first
    restrict_concealed(page)
    page.revise!
    page.set_fields(params, %i(title content description comment))
    page.author = current_user
    page.save

    redirect "#{page.slug_for_uri}"
  end

  post '/:slug/conceal' do
    page = Page.with_slug(slug).first
    restrict_concealed(page)

    # intentionally avoid Page save hook
    page.this.update(concealed: !page.concealed)

    redirect "#{page.slug_for_uri}"
  end
end
