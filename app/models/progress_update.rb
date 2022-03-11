class ProgressUpdate < ApplicationRecord
  has_one :funding_applications_progess_update, inverse_of: :progress_update
  has_one :funding_applications, through: :funding_applications_progess_update

  has_many :progress_update_photo
  has_many :progress_update_event
  has_many :progress_update_new_staff

  accepts_nested_attributes_for :progress_update_photo
  accepts_nested_attributes_for :progress_update_event
  accepts_nested_attributes_for :progress_update_new_staff

  attr_accessor :validate_has_upload_photo
  attr_accessor :validate_progress_update_photo

  attr_accessor :validate_has_upload_event
  attr_accessor :validate_progress_update_event
  
  attr_accessor :validate_has_upload_new_staff
  attr_accessor :validate_progress_update_new_staff

  attr_accessor :has_upload_photos
  attr_accessor :has_upload_events
  attr_accessor :has_upload_new_staff

  validates :has_upload_photos, presence: true, if: :validate_has_upload_photo?
  validates :progress_update_photo, presence: true, if: :validate_progress_update_photo?
  validates_associated :progress_update_photo, if: :validate_progress_update_photo?

  validates :has_upload_events, presence: true, if: :validate_has_upload_event?
  validates :progress_update_event, presence: true, if: :validate_progress_update_event?
  validates_associated :progress_update_event, if: :validate_progress_update_event?

  validates :has_upload_new_staff, presence: true, if: :validate_has_upload_new_staff? 
  validates :progress_update_new_staff, presence: true, if: :validate_progress_update_new_staff?
  validates_associated :progress_update_new_staff, if: :validate_progress_update_new_staff?

  def validate_has_upload_photo?
    validate_has_upload_photo == true
  end

  def validate_progress_update_photo?
    validate_progress_update_photo == true
  end

  def validate_has_upload_event?
    validate_has_upload_event == true
  end

  def validate_progress_update_event?
    validate_progress_update_event == true
  end

  def validate_has_upload_new_staff?
    validate_has_upload_new_staff == true
  end

  def validate_progress_update_new_staff?
    validate_progress_update_new_staff == true
  end

end
