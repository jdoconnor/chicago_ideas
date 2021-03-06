class ApplicationController < ActionController::Base

  # which pages are we caching
  before_filter :cache_rendered_page, :only => [:index, :contact, :team, :terms, :about, :special_programs_awards, :privacy, :volunteer]
  before_filter :get_sponsors
  before_filter :get_talks
  before_filter :get_nav_featured
  before_filter :get_header_models
  before_filter :capture_path
    
  # the application homepage
  def index
    @talks = Talk.archived.order('RAND()').limit(8)
    @speakers = User.speaker.not_deleted.archived.order('RAND()').limit(8)
    @featured = Chapter.homepage_featured.where('id != 67').order('RAND()').limit(7)
    @clinton = Chapter.find_by_id(67);
    @meta_data = {:page_title => "Welcome", :og_image => "http://www.chicagoideas.com/assets/application/logo.png", :og_title => "Chicago Ideas Week", :og_type => "website", :og_desc => "Chicago Ideas Week (CIW) is about the sharing of ideas, inspiring action and igniting change to positively impact our world. People who come to CIW are artists, engineers, technologists, inventors, scientists, musicians, economists, explorers-and, well...just innately passionate."}
  end
  
  
  def doc_raptor_send(options = { })
    default_options = { 
      :name             => controller_name,
      :document_type    => request.format.to_sym,
      #:test             => ! Rails.env.production?,
      :test => DOC_RAPTOR_TEST #for now
    }
    options = default_options.merge(options)
    #don't really want to sandbox views for pdfs anywhere so lets keep them in main views folder for consitency
    options[:document_content] ||= render_to_string :template => "#{self.controller_name}/pdf.html.haml", :layout => 'pdf.html.haml'
    ext = options[:document_type].to_sym
    
    response = DocRaptor.create(options)
    
  end
  
  def get_header_models
    @current_year = Year.find(2012)
  end
  def get_sponsors
    @sponsors = Sponsor.featured_sponsors.order('RAND()')
  end
  def get_talks    
    @e_talks = TalkBrand.find(TALK_BRAND_ID).talks.archived.order('RAND()').limit(10)
    @e_megatalks = TalkBrand.find(MEGATALK_BRAND_ID).talks.order('RAND()').limit(3)
    @e_speakers = User.speaker.not_deleted.archived.order('RAND()').limit(10)
  end
  def get_nav_featured
    @nav_featured_chapters = Chapter.homepage_featured.order('RAND()').limit(2)
  end
  
  def about
    get_team_members
    @meta_data = {:page_title => "About the CIW Team", :og_title => "Chicago Ideas Week Team", :og_type => "website"}
    render "application/about"
  end
  
  def sizzle
    @meta_data = {:page_title => "CIW Sizzle Reel", :og_title => "Chicago Ideas Week", :og_type => "website"}
    render "application/sizzle"
  end
  
  def media_inquiry
    @meta_data = {:page_title => "CIW Media Inquiry Form", :og_title => "Chicago Ideas Week", :og_type => "website"}
    render 'application/media_inquiry_form'
  end
  
  def send_contact
    AdminMailer.contact_form(params[:contact]).deliver
    render_json_response :ok, :notice => "Your message has been sent."
  end
  
  def community
  end
  
  def volunteer  
  end
  
  
  def special_programs_awards
    @meta_data = {:page_title => "Special Programs & Awards", :og_title => "Special Programs & Awards | Chicago Ideas Week", :og_type => "website", :og_desc => "Chicago Ideas Week (CIW) is about the sharing of ideas, inspiring action and igniting change to positively impact our world. People who come to CIW are artists, engineers, technologists, inventors, scientists, musicians, economists, explorers-and, well...just innately passionate."}
  end
  

  def terms
    @meta_data = {:page_title => "Terms of Use", :og_image => "http://www.chicagoideas.com/assets/application/logo.png", :og_title => "Terms of Use | Chicago Ideas Week", :og_type => "website", :og_desc => "Chicago Ideas Week (CIW) is about the sharing of ideas, inspiring action and igniting change to positively impact our world. People who come to CIW are artists, engineers, technologists, inventors, scientists, musicians, economists, explorers-and, well...just innately passionate."}
  end

  def privacy
    @meta_data = {:page_title => "Privacy Policy", :og_image => "http://www.chicagoideas.com/assets/application/logo.png", :og_title => "Privacy Policy | Chicago Ideas Week", :og_type => "website", :og_desc => "Chicago Ideas Week (CIW) is about the sharing of ideas, inspiring action and igniting change to positively impact our world. People who come to CIW are artists, engineers, technologists, inventors, scientists, musicians, economists, explorers-and, well...just innately passionate."}
  end
  
  # this contains the login and register links, we load it in via AJAX after the initial page has loaded.  
  # This allows us to cache fully rendered versions of the entire front end of the website.
  # This makes for an extremely fast experience for all our visitors
  def account_links
    json = {}
    json[:signed_in] = current_user ? true : false
    json[:admin] = (current_user and current_user.admin?) ? true : false
    json[:connected_to_twitter] = (current_user and current_user.connected_to_twitter?) ? true : false
    json[:connected_to_facebook] = (current_user and current_user.connected_to_facebook?) ? true : false
    json[:full_name] = (current_user ) ? current_user.name : nil
    json[:newsletter] = (current_user ) ? current_user.newsletter : nil
    render :json => json
  end
  
  
  # Capture the URL
  def capture_path
    cookies[:return_to] = request.path if request.method == "GET" && !devise_controller? && !request.xhr? && action_name != 'redirect'
    #puts cookies.to_json    
  end
  
  def after_sign_in_path_for(resource)
    #puts session.to_json
    cookies[:return_to] || user_root_path
  end

  
  private
  
    # appropriate headers to make our content cached - in heroku this gets cached by a squid like cache on top of our application servers
    # this makes for a very fast user experience
    def cache_rendered_page
      expires_in(24.hours)
    end
  
    # recursive call for deep cloning a hash in a way which doesnt keep non scalar types also doesnt modify the params array
    # we use this in logging before_filters
    def collect_hash_contents hash
      new_hash = {}
      hash.each do |key, val|
        # we only keep certain types
        if val.kind_of? Hash
          new_hash[key] = collect_hash_contents(val)
        elsif val.kind_of? String
          new_hash[key] = val
        else
          new_hash[key] = '-stripped-'
        end
      end
      new_hash
    end

    # get all staff members, sorted by priority
    def get_team_members
      # TODO:  add a sort column so we dont have to hard code these
      @team = []
      @team << User.find(2)
      @team << User.find(62)
      @team << User.find(5)
      @team << User.find(6)
      @team << User.find(1)
      #@team << User.find(9)
      #@team << User.find(3)
      @team << User.find(8)
      @team << User.find(4)
      @team << User.find(155)
      #@team << User.find(159)
      #User.staff.not_deleted.where("id not in (2,62,5,6,1,9,3,8,4,155,159,7,156)").all.each do |u|
      #User.staff.not_deleted.where("id not in (2,62,5,6,1,9,3,8,4,155,7)").all.each do |u|
      User.staff.not_deleted.where("id not in (2,62,5,6,1,3,8,4,155,7)").all.each do |u|
        @team << u
      end
      # these guys are part time
      @team << User.find(7)
      #@team << User.find(156)
      @team
    end

end
