class AuthenticationsController < ApplicationController
  require 'fb_graph'
  
  def index
  end

  def create
    # get provider
    params[:provider] ? provider_route = params[:provider] : provider_route = ''

    # callback hash    
    omniauth = request.env["omniauth.auth"]
      
    if omniauth and params[:provider]
      if provider_route == 'facebook'
        # user unique id per provider [REQUIRED]
        omniauth['uid'] ?  uid =  omniauth['uid'] : uid = ''
        omniauth['provider'] ? provider =  omniauth['provider'] : provider = ''
        
        # user profile specific
        omniauth['user_info']['email'] ? email =  omniauth['user_info']['email'] : email = ''
        omniauth['user_info']['name'] ? name =  omniauth['user_info']['name'] : name = ''
        omniauth['user_info']['first_name'] ? first_name =  omniauth['user_info']['first_name'] : first_name = ''
        omniauth['user_info']['last_name'] ? last_name =  omniauth['user_info']['last_name'] : last_name = ''
        omniauth['user_info']['image'] ? image_path =  omniauth['user_info']['image'] : image_path = ''
        
        # user location specific
        omniauth['extra']['user_hash']['location']['name'] ? location_name =  omniauth['extra']['user_hash']['location']['name'] : location_name = ''
        omniauth['extra']['user_hash']['location']['id'] ? location_id =  omniauth['extra']['user_hash']['location']['id'] : location_id = ''
        
      else                                       
        render :text => '--- provider, #{@provider_route}, not supported ---'  
        return
      end
      
      
      # continue on valid uid and provider
    if uid != '' and provider != ''
        # debugger
        auth = Authentication.find_by_provider_and_uid(provider, uid)        
        if !auth.nil?
          flash[:notice] = "Signed in successfully"
          sign_in_and_redirect(:user, auth.user)
        elsif @current_user
          @current_user.authentications.create(:provider => provider, :uid => uid, :name => name, :email => email, :first_name => first_name, :last_name => last_name, :image_path => image_path, :location_name => location_name, :location_id => location_id)
          flash[:notice] = "Facebook authentication successful"
          return
        else  
          user = User.find_or_initialize_by_email(:email => email)
          auth_hash = {:provider => provider, :uid => uid, :name => name, :email => email, :first_name => first_name, :last_name => last_name, :image_path => image_path, :location_name => location_name, :location_id => location_id}
          user.apply_omniauth(auth_hash)         
          if user.save
            flash[:notice] = "New user signed in successfully."
            sign_in_and_redirect(:user, user)
          else
            # drop extra piece while passing through session for payload purposes
            session[:omniauth] = auth_hash
            redirect_to new_user_registration_url
          end
        end
    end
    end
  end

  def destroy
  end

  def failure
    redirect_to new_user_registration_path
  end

end
