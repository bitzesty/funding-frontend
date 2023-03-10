class User < ApplicationRecord
  include GenericValidator

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable

  enum role: [:user, :admin]
  after_initialize :set_default_role, :if => :new_record?

  has_many :users_organisations, inverse_of: :user
  has_many :organisations, through: :users_organisations

  has_many :projects
  has_many :open_medium

  belongs_to :person, optional: true

  attr_accessor :validate_details
  attr_accessor :validate_address

  # These attributes are used to set individual error messages
  # for each of the project date input fields
  attr_accessor :dob_day
  attr_accessor :dob_month
  attr_accessor :dob_year

  validates :name, length: { minimum: 1, maximum: 80 }, if: :validate_details?
  validates :dob_day, presence: true, if: :validate_details?
  validates :dob_month, presence: true, if: :validate_details?
  validates :dob_year, presence: true, if: :validate_details?
  validates :language_preference, inclusion: { in: %w(english welsh both) }, allow_nil: true, if: :validate_details?
  validates :line1, presence: true, if: :validate_address?
  validates :townCity, presence: true, if: :validate_address?
  validates :county, presence: true, if: :validate_address?
  validates :postcode, presence: true, if: :validate_address?

  validate :date_of_birth_is_date_and_in_past?, if: :validate_details?

  validate do

    validate_length(
      :communication_needs,
      50,
      I18n.t("activerecord.errors.models.user.attributes.communication_needs.too_long")
    ) if validate_details?

  end

  def set_default_role
    self.role ||= :user
  end
  
  def validate_details?
    validate_details == true
  end

  def validate_address?
    validate_address == true
  end

  def date_of_birth_is_date_and_in_past?
    unless Date.valid_date?(self.dob_year.to_i, self.dob_month.to_i, self.dob_day.to_i)
      errors.add(:date_of_birth, 'Date of birth must be a valid date')
    else
      dob_provided = Date.new(self.dob_year.to_i, self.dob_month.to_i, self.dob_day.to_i)
      unless dob_provided.past?  
        errors.add(:date_of_birth, 'Date of birth must be in the past')
      end
      unless dob_provided >= Date.new(1910,1,1)
        errors.add(:date_of_birth,  I18n.t("details.dob_error"))
      end
    end
  end

  def self.current_user(user_id)
      @user = User.find_by(uid: user_id)
  end

  # If it isn't 'welsh' or 'both' then default is english, 
  # whether another language or nil
  def send_english_mails?
    ['WELSH', 'BOTH'].exclude? language_preference&.strip&.upcase
  end

  def send_welsh_mails?
    language_preference&.strip&.upcase == 'WELSH'
  end

  def send_bilingual_mails?
    language_preference&.strip&.upcase == 'BOTH'
  end

end
