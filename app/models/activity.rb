# == Schema Information
#
# Table name: activities
#
#  id               :bigint(8)        not null, primary key
#  name             :string           not null
#  english          :boolean          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint(8)        not null
#  activity_type    :integer          not null
#  status           :integer          default("Por validar"), not null
#  notes            :string
#  score            :integer          default(0)
#  description      :text
#  pitch_audience   :text
#  abstract_outline :text
#  files            :string
#  english_approve  :boolean
#  slug             :string
#  match_id         :bigint(8)
#

class Activity < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  belongs_to :match
  belongs_to :user
  has_many :locations, dependent: :destroy
  accepts_nested_attributes_for :locations, allow_destroy: true, reject_if: :created_whithout_name
  has_many :feedback, dependent: :destroy
  has_many :activity_statuses, dependent: :destroy
  has_many :votes, dependent: :destroy
  enum activity_type: %i[Curso Plática Post]

  enum status: %i[Por\ validar En\ revisión Aprobado]
  has_many_attached :files, dependent: :destroy
  before_update :mark_locations_for_removal, :update_score
  before_save :assign_score

  scope :from_a_poll, (lambda { |start_date, end_date|
    where('created_at >= ? AND created_at <= ? AND status = ?', start_date, end_date, 2)
  })
  scope :checked_activities, ->(actual_user) { joins(:activity_statuses).where('activity_statuses.user_id = ?', actual_user).select('activities.id') }
  scope :unapproved, ->(actual_user) { where('activities.id IN (?)', checked_activities(actual_user)).order('name ASC') }
  scope :pending_activities, ->(actual_user) { where('activities.id NOT IN (?)', checked_activities(actual_user)).order('name ASC') }
  scope :order_by_name, -> { order('name ASC') }
  scope :best_activities, (lambda { |poll_id, type|
    joins(:votes)
    .where('votes.poll_id = ?', poll_id)
    .where('activities.activity_type = ?', type)
    .group('activities.name')
    .select('activities.name, sum(votes.value) as points')
    .order('points desc').limit(1)
  })
  validates :pitch_audience, :abstract_outline, :description, presence: true, unless: :post?
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  def css_class
    status_class = { "Por validar": 'on-hold', "En revisión": 'review', "Aprobado": 'approved' }
    status_class[status.to_sym]
  end

  def approved?
    Aprobado?
  end

  def assign_score
    self.score = score_by_type
  end

  def to_param
    slug
  end

  def should_generate_new_friendly_id?
    name_changed?
  end

  def workshop?
    Curso?
  end

  def talk?
    Plática?
  end

  def post?
    Post?
  end

  def can_edit?(user_id)
    user.id == user_id
  end

  def created_whithout_name(location)
    location[:name].blank? && new_record?
  end

  def mark_locations_for_removal
    locations.each do |location|
      location.mark_for_destruction if location.name.blank?
    end
  end

  def score_by_type
    case activity_type
    when 'Curso'
      40
    when 'Plática'
      25
    when 'Post'
      10
    end
  end

  def update_score
    accumulated_score = score_by_type
    accumulated_score += 5 if english_approve
    events_extra_points = Post? ? 5 : 15
    accumulated_score += events_extra_points * locations.where(approve: true).count
    self.score = accumulated_score
  end
end
