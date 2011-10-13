class Challenge
  include Mongoid::Document 
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :title, :type=>String
  field :description, :type=>String

  field :dateStart, :type=>DateTime
  field :dateEnd, :type=>DateTime
  field :discipline, :type=>String
  field :participants, :type=>String
  field :rules, :type=>Array    
  field :goals, :type=>Array        

  field :user_id, :type=>String

  embeds_many :tasks  

  validates_presence_of :title, :description
  
  def user
    User.find(user_id)
  end  
  
end                