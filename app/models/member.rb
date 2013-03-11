# -*- encoding : utf-8 -*-
class Member < ActiveRecord::Base

  include Tokyorails::GithubMethods

  validates_presence_of :uid, :name, :bio
  validates_uniqueness_of :uid
  validates_uniqueness_of :github_username, :allow_blank => true

  has_one :image, :as => :imageable, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :projects, :through => :memberships

  scope :authenticated, where("access_token IS NOT NULL AND access_token != ''")
  scope :name_like, lambda {|query| where("UPPER(name) LIKE UPPER(?)", "%#{query}%")}

  def self.authenticate(auth)
    member = Member.find_by_uid(auth['uid'].to_s)
    if member
      member.access_token = auth['credentials']['token']
      member.save!
    end
    member
  end

  def photo
    self.image || self.create_image(:file_url => photo_url) unless photo_url.blank?
  end

  def member_of?(project)
    memberships.exists?(project_id: project, deleted_at: nil)
  end

  def first_name
    name.split(' ').first
  end

  def active?
    rsvps.first && rsvps.first.created_at > 3.months.ago
  end

  def rsvps
    Rsvp.where(member_id: uid, response: 'yes').order('created_at desc')
  end

  def upcoming_rsvp_response
    if event = Event.upcoming.first
      rsvp = Rsvp.where(member_id: uid, meetup_id: event.uid).first
    end
    rsvp.present? ? rsvp.response : 'unknown'
  end

  def interests
    [] # coming from somewhere
  end

end
