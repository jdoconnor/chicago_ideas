class Topic < ActiveRecord::Base

  # my bone dry solution to search, sort and paginate
  include SearchSortPaginate

  
  # we have a polymorphic relationship with notes
  has_many :notes, :as => :asset
  
  scope :by_name, order('name asc')
  
  validates :name, :presence => true
  validates_uniqueness_of :name
  validates :description, :presence => true
  
  # the hash representing this model that is returned by the api
  def api_attributes
    {
      :id => id.to_s,
      :type => self.class.name.downcase,
      :name => name,
      :description => description,
    }
  end

  # a DRY approach to searching lists of these models
  def self.search_fields parent_model=nil
    case parent_model.class.name.underscore
    when 'foo'
    else
      [
        { :name => :search, :as => :string, :fields => [:name], :wildcard => :both },
        { :name => :created_at, :as => :datetimerange }, 
      ]
    end
  end
  
end
