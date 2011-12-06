class ChallengesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :find_challenge, :only => [:show, :edit, :update, :destroy]
  #on_spot_edit  is the gem to edit the data on spot 
  can_edit_on_the_spot

  def index
    @title = "Challenges"
    @no_of_row = Challenge.all.count
    @challenges = current_user.challenges
    #@ch =  @challenges.parent_challenge
    #render :text => @ch
  end

  def show       
    @challenge = Challenge.find(params[:id])	
  end

  def show_soc
    @flg = params[:flg]
    @challenge = Challenge.find(params[:id])
    @is_complete_status = 0 
    @challenge.tasks.each do |checkingTaskStatus|
      unless checkingTaskStatus.is_complete == 1
        @is_complete_status = 1
        next
      end
    end
    if @is_complete_status == 0
      Challenge.where(:_id => params[:id]).update(:is_complete => 1)
    end
    @org = User.find(:all,:conditions => ["id=?",@challenge.user_id]).first
  end

  def show_per
    # debugger
    #raise params[:id].inspect
    @challenge = Challenge.find(params[:id])
    @is_complete_status = 0 
    @challenge.tasks.each do |checkingTaskStatus|
      unless checkingTaskStatus.is_complete == 1
        @is_complete_status = 1
        next
      end
    end
    if @is_complete_status == 0
      Challenge.where(:_id => params[:id]).update(:is_complete => 1)
    end
    if (@challenge.social_type.instance_of? ChallengeSocialType rescue false)
      render "show_soc" and return 
    else 
      render "show_per"
    end
  end

  def new
    @challenge = Challenge.new
    1.times {@challenge.tasks.build} 
  end

  def create
  
	#raise current_user.fbauth.uid.inspect
  
	#if !params[:invitees].nil?
	#	params[:invitees].split(",").each do |aFBId|
	#		current_user.user_connections.find_or_create_by_target_id(:user_id => current_user.fbauth.uid, :target_id => aFBId )
	#	end
	#end	
	#raise "aaaa"
	
	
	#debugger
    #raise params[:invitees].inspect
    @ch = Challenge.new(params[:challenge])
    @ch_st_date = params[:start_point_type]
    @st_p_val = params[:start_point_value]
    #@st_p_val = params[:start_point_label]
    @st_p_leb = params[:start_point_label]

    @ch_ed_date = params[:end_point_type]
    @ed_p_val = params[:end_point_value]
    #@ed_p_val = params[:ed_value]
    @ed_p_leb = params[:end_point_label]

    @so_who_win = params[:soc_who_win]
    @so_how_many_winner = params[:soc_how_many_winner]
    @pr_who_win = params[:per_who_win]

    unless @so_who_win.blank?
      #raise "soc"
      @challenge = Challenge.new(:user_id => (current_user.fbauth.uid rescue current_user.id), :title => @ch.title, :description => @ch.description, :canCompleteBeforeTasks => @ch.canCompleteBeforeTasks, \
      :social_type => ChallengeSocialType.new(:status => 1,:who_win => @so_who_win, :how_many_winners => @so_how_many_winner)) do |new_challenge|
        if @ch_st_date == "startPointDate" and  @ch_ed_date == "endPointDate"
          new_challenge.start_point =  PointDateType.new(:value => Date.strptime(@st_p_val, '%m/%d/%Y'))
          new_challenge.end_point = PointDateType.new(:value => Date.strptime(@ed_p_val, '%m/%d/%Y')) 
        else
          new_challenge.start_point =  PointNumberType.new(:value => @st_p_val, :label=> @st_p_leb)
          new_challenge.end_point = PointNumberType.new(:value => @ed_p_val, :label=>@ed_p_leb) 
        end
      end
    else
      #raise "per"
      @challenge = Challenge.new(:user_id => (current_user.fbauth.uid rescue current_user.id), :title => @ch.title, :description => @ch.description, :canCompleteBeforeTasks => @ch.canCompleteBeforeTasks, \
      :personal_type => ChallengePersonalType.new(:who_win => @pr_who_win)) do |new_challenge|
        if @ch_st_date == "startPointDate" and  @ch_ed_date == "endPointDate" 
          #debugger
          new_challenge.start_point =  PointDateType.new(:value => Date.strptime(@st_p_val, '%m/%d/%Y'))
          new_challenge.end_point = PointDateType.new(:value => Date.strptime(@ed_p_val, '%m/%d/%Y')) 
        else
          new_challenge.start_point =  PointNumberType.new(:value => @st_p_val, :label=> @st_p_leb)
          new_challenge.end_point = PointNumberType.new(:value => @ed_p_val, :label=>@ed_p_leb) 
        end
      end            
    end

    @ch.task_attributes.each do |task_attr|
      #@challenge.tasks << Task.new(:name =>"testing")
      @challenge.tasks.build(task_attr)
    end

    @challenge.save!
	
	unless @so_who_win.blank?
		# referenced documents can only be saved when parent exists
		if !params[:invitees].nil?
			params[:invitees].split(",").each do |aFBId|
				current_user.user_connections.find_or_create_by_target_id(:target_id => aFBId )
			end
		end
	end
		

    unless @so_who_win.blank?
      # referenced documents can only be saved when parent exists
      if !params[:invitees].nil?
        params[:invitees].split(",").each do |invitee|
          if @ch_st_date == "startPointDate" and  @ch_ed_date == "endPointDate"
            @challenge.child_challenges.create!(:user_id => invitee, :title => @ch.title, :description => @ch.description, :canCompleteBeforeTasks => @ch.canCompleteBeforeTasks, \
            :start_point => PointDateType.new(:value => Date.strptime(@st_p_val, '%m/%d/%Y')), \
            :end_point => PointDateType.new(:value => Date.strptime(@ed_p_val, '%m/%d/%Y')), \
            :social_type => ChallengeSocialType.new(:who_win => @so_who_win, :how_many_winners => @so_how_many_winner), \
            :tasks => @ch.task_attributes)
          else 
            @challenge.child_challenges.create!(:user_id => invitee, :title => @ch.title, :description => @ch.description, :canCompleteBeforeTasks => @ch.canCompleteBeforeTasks, \
            :start_point => PointNumberType.new(:value => @st_p_val, :label=> @st_p_leb), \
            :end_point => PointNumberType.new(:value => @ed_p_val, :label=>@ed_p_leb), \
            :social_type => ChallengeSocialType.new(:who_win => @so_who_win, :how_many_winners => @so_how_many_winner), \
            :tasks => @ch.task_attributes)
          end
        end      
      end  
    end    

    redirect_to show_per_challenges_path(:id => @challenge), :notice => "Challenge created!"

  end

  def edit
    @challenge = Challenge.find(params[:id])
  end

  def update_task_soc
    #raise params[:challenge].inspect
    @challenge = Challenge.find(params[:id])
    @challenge.tasks.destroy
    @challenge.child_challenges.each do |eachChildChallenge|
      eachChildChallenge.tasks.destroy
      eachChildChallenge.update_attributes(params[:challenge])
    end
    @challenge.update_attributes(params[:challenge])
    redirect_to show_soc_challenges_path(:id => @challenge)
    #raise "aaa"
  end

  def update
    #raise params.inspect
    @challenge = Challenge.find(params[:id])
    #raise ch = params[:challenge].inspect 
    if @challenge.update_attributes(params[:challenge])
		#raise "aaa"
      redirect_to :action => 'index', :id => @challenge
    else
      render :action => edit
    end
  end

  def destroy
    @challenge.destroy
    redirect_to :action => 'index'
  end  

  def invitee_accepted_req
    raise "aaaaaaaaa"
  end

  def message
    render :partial => 'challenges/message'
  end  

  def task_update
    @id = params[:id]
    @name = params[:name]
    @score = params[:score]
    @score_by = params[:score_by]
    render :layout => false
  end

  def task_update_c
    #raise params.inspect
    @ch_ts_update = Challenge.find(params[:id])
    unless params[:tatal_s]
      @ch_ts_update.tasks.where(:name => params[:name]).update(:is_complete => 1)
    else
      @ch_ts_update.tasks.where(:name => params[:name]).update(:is_complete => 1, :score => params[:tatal_s])
    end 
    redirect_to show_per_challenges_path(:id => params[:id])
  end

  def challenge_comp
    @sdf = Challenge.where(:_id => params[:id]).update(:is_complete => 1)
    redirect_to :action => "index"
  end

  def my_challenge
    @my_total_challenge = Challenge.all.count
    @my_all_ch = Challenge.all
    @my_all_ch.each do |sd|
      @org = User.find(:all,:conditions =>["id = ?",sd.user_id]).first
    end
  end

  def add_task_link
    @ch_id = params[:id]
    render :layout => false
  end

  def add_task_fun
    @chall_ref = Challenge.find(params[:challenge_id]) 
    @chall_ref.tasks.push(Task.new(:name => params[:name], :score => params[:score], :score_by => params[:score_by]))
    @chall_ref.child_challenges.each do |ts|
      #ts.tasks.destroy
      #ts.update_attributes(params[:challenge])
      ts.tasks.push(Task.new(:name => params[:name], :score => params[:score], :score_by => params[:score_by]))
    end
    #@chall_ref.child_challenges.build(:tasks => Task.new(:name => params[:name], :score => params[:score], :score_by => params[:score_by]))
    redirect_to show_per_challenges_path(:id => params[:challenge_id])
  end

  def date_update
    @challenge_date = Challenge.find(params[:id])
    @date = @challenge_date.end_point.value 
    render :layout => false
  end


  def update_status
    aChallenge = Challenge.find(params[:id])
    socialType = aChallenge.social_type
    socialType.update_attributes(:status => params[:status])       

    redirect_to show_soc_challenges_path(:id => params[:id])
  end

  def update_status_af_meg
    Challenge.where(:_id => params[:thinking_abt] ).all.each do |aChallenge|
      aChallenge.child_challenges.each do |aChildChallenge|
        socialType = aChildChallenge.social_type
        socialType.update_attributes(:status => "null")
      end
    end
  end

  protected

  def find_challenge
    @challenge = Challenge.all
  end

end

