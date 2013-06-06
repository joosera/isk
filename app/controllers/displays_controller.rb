class DisplaysController < ApplicationController
  before_filter :require_create, :only => [:new, :create]
  
  
  skip_before_filter :require_login, :only => [:show, :hello, :slide_shown, :current_slide]
    
  def index
    @displays = Display.order(:name).all
    
    respond_to do |format|
      format.js
      format.html
    end
    
  end
  
  #Näytin esittäytyy uniikilla nimellään
  def hello
    @display = Display.where(:name => params[:name]).first_or_initialize
    if request.headers['HTTP_X_FORWARDED_FOR']
      @display.ip = request.headers['HTTP_X_FORWARDED_FOR']
    else
      @display.ip = request.ip
    end
    @display.last_contact_at = Time.now
    @display.last_hello = Time.now
    @display.save!
    @display.reload

    render :text => @display.id
  end
  
  #Näytin kertoo mitä kalvoa näytetään
  def current_slide
    d = Display.find(params[:id])
    if params[:group].to_i != -1
      d.current_group = MasterGroup.find(params[:group])
    else
      d.current_group_id = -1
    end
    s = Slide.find(params[:slide])
    d.current_slide = s
    d.last_contact_at = Time.now
    
    dc = DisplayCount.where(:slide_id => s.id, :display_id => d.id).first_or_initialize
    dc.count += 1
    dc.save!
    
    d.save!
    render :nothing => true
  end
  
  #Näytin kertoo kun ohisyötön kalvo on näytetty
  def slide_shown
    d = Display.find(params[:id])
    d.current_group_id = -1
    oq = d.override_queues.find(params[:override])
    d.current_slide = oq.slide
    d.last_contact_at = Time.now
    oq.destroy
    d.save!
    render :nothing => true
  end
  
  def show
    @display = Display.includes(:presentation, :override_queues => :slide).find(params[:id])
    
    respond_to do |format|
      format.html 
      format.json {
        @display.last_contact_at = Time.now
	      @display.save!
        render(:json =>JSON.pretty_generate(@display.to_hash))
      }
    end
  end
  
  def slide_stats
    @display = Display.find(params[:id])
    
  end
  
  def new
    
  end
  
  def create
    
  end
  
  def edit
    @display = Display.find(params[:id])
    require_edit @display
  end
  
  def update_override
    oq = OverrideQueue.find(params[:id])
    require_edit oq.display
    
    oq.duration = params[:override_queue][:duration]
    oq.save!
    flash[:notice] = "Duration was changed"
    redirect_to :back
  end
  
  def update
    @display = Display.find(params[:id])
    require_edit @display

    if @display.update_attributes(params[:display])
      flash[:notice] = 'Display was successfully updated.'
      redirect_to :back
    else
      render :action => 'edit'
    end
  end  
    
  def presentation
    @display = Display.find(params[:id])
    redirect_to :controller => :presentations, :action => :show, :id => @display.presentation.id
  end
  
  def add_slide
    @display = Display.find(params[:id])
    require_edit @display


    @slides = Slide.current
  end
  
  def queue_slide
    display = Display.find(params[:id])
    require_override display

    slide = Slide.current.find(params[:slide_id])

    Display.transaction do 
      oq = display.override_queues.new
      oq.slide = slide
      oq.duration = params[:duration]
      oq.save!
    end
    
    flash[:notice] = 'Added slide ' << slide.name << ' to the override queue'
    redirect_to :action => :show, :id => display.id
    
  end
  
  def sort_queue
    Display.transaction do
      d = Display.find(params[:id])
      require_override d
      
      
      if params[:override_queue].count == d.override_queues.count
        d.override_queues.each do |oq|
          oq.position = params['override_queue'].index(oq.id.to_s) + 1
          oq.save
        end
        d.reload
        render :partial => 'slide_items', :locals => {:override => d.override_queues}
      else
        render :text => "Invalid slide count, try refreshing", :status => 400
      end
    end
    
  end
  
  def remove_override
    oq = OverrideQueue.find(params[:id]).destroy
    require_override oq.display
    
    flash[:notice] = 'Removed slide from override queue'
    redirect_to :back
  end
  
  def deny
    display = Display.find(params[:id])
    user = User.find(params[:user_id])
    display.authorized_users.delete(user)
    redirect_to :back
  end
  
  def grant
    display = Display.find(params[:id])
    user = User.find(params[:grant][:user_id])
    display.authorized_users << user
    redirect_to :back    
  end
  
  
  private
  
  def require_admin
    raise ApplicationController::PermissionDenied unless require_role 'display-admin'
  end
  
  def require_create
    raise ApplicationController::PermissionDenied unless require_role ['display-admin', 'display-create']
  end
  
  def require_override(d)
    raise ApplicationController::PermissionDenied unless d.can_override?(current_user)
  end
 


end