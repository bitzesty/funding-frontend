class ProgressUpdate < ApplicationRecord
  has_one :funding_applications_progess_update, inverse_of: :progress_update
  has_one :funding_applications, through: :funding_applications_progess_update

  has_many :progress_update_photo, dependent: :destroy
  has_many :progress_update_event, dependent: :destroy
  has_many :progress_update_new_staff, dependent: :destroy
  has_many :progress_update_procurement_evidence, dependent: :destroy
  has_many :progress_update_procurement, dependent: :destroy
  has_many :progress_update_additional_grant_condition, dependent: :destroy
  has_many :progress_update_statutory_permissions_licence, dependent: :destroy
  has_many :progress_update_new_expiry_date, dependent: :destroy
  has_many :progress_update_risk_register, dependent: :destroy

  accepts_nested_attributes_for :progress_update_photo
  accepts_nested_attributes_for :progress_update_event
  accepts_nested_attributes_for :progress_update_new_staff
  accepts_nested_attributes_for :progress_update_procurement_evidence
  accepts_nested_attributes_for :progress_update_procurement
  accepts_nested_attributes_for :progress_update_additional_grant_condition
  accepts_nested_attributes_for :progress_update_statutory_permissions_licence
  accepts_nested_attributes_for :progress_update_risk_register


  attr_accessor :validate_has_upload_photo
  attr_accessor :validate_progress_update_photo

  attr_accessor :validate_has_upload_event
  attr_accessor :validate_progress_update_event
  
  attr_accessor :validate_has_upload_new_staff
  attr_accessor :validate_progress_update_new_staff

  attr_accessor :validate_has_procured_goods

  attr_accessor :validate_has_procurement_report_evidence
  attr_accessor :validate_progress_updates_procurement_evidence

  attr_accessor :validate_progress_update_procurement

  attr_accessor :validate_add_another_procurement
  attr_accessor :validate_date_correct

  attr_accessor :validate_has_statutory_permissions_licence
  attr_accessor :validate_progress_update_statutory_permissions_licence
  attr_accessor :validate_has_risk_update
  attr_accessor :validate_has_risk_register
  attr_accessor :validate_progress_update_risk_register

  attr_accessor :has_upload_photos
  attr_accessor :has_upload_events
  attr_accessor :has_upload_new_staff
  attr_accessor :has_procured_goods
  attr_accessor :has_procurement_report_evidence
  attr_accessor :add_another_procurement
  attr_accessor :no_progress_update
  attr_accessor :date_correct
  attr_accessor :has_statutory_permissions_licence
  attr_accessor :has_risk_update
  attr_accessor :has_risk_register

  validates :has_upload_photos, presence: true, if: :validate_has_upload_photo?
  validates :progress_update_photo, presence: true, if: :validate_progress_update_photo?
  validates_associated :progress_update_photo, if: :validate_progress_update_photo?

  validates :has_upload_events, presence: true, if: :validate_has_upload_event?
  validates :progress_update_event, presence: true, if: :validate_progress_update_event?
  validates_associated :progress_update_event, if: :validate_progress_update_event?

  validates :has_upload_new_staff, presence: true, if: :validate_has_upload_new_staff? 
  validates :progress_update_new_staff, presence: true, if: :validate_progress_update_new_staff?
  validates_associated :progress_update_new_staff, if: :validate_progress_update_new_staff?

  validates :has_procured_goods, presence: true, if: :validate_has_procured_goods?  
  
  validates :date_correct, presence: true, if: :validate_date_correct? 

  validates :has_procurement_report_evidence, presence: true, if: :validate_has_procurement_report_evidence?
  validates :progress_update_procurement_evidence, presence: true, if: :validate_progress_updates_procurement_evidence?

  validates :progress_update_procurement, presence: true, if: :validate_progress_update_procurement?
  validates_associated :progress_update_procurement, if: :validate_progress_update_procurement?

  validates :add_another_procurement, presence: true, if: :validate_add_another_procurement?

  validates :has_statutory_permissions_licence, presence: true, if: :validate_has_statutory_permissions_licence?
  validates :progress_update_statutory_permissions_licence, presence: true, if: :validate_progress_update_statutory_permissions_licence?
  validates_associated :progress_update_statutory_permissions_licence, if: :validate_progress_update_statutory_permissions_licence?

  validates :has_risk_update, presence: true, if: :validate_has_risk_update?
  validates :has_risk_register, presence: true, if: :validate_has_risk_register?
  validates :progress_update_risk_register, presence: true, if: :validate_progress_update_risk_register?

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

  def validate_has_procured_goods?
    validate_has_procured_goods == true
  end

  def validate_has_procurement_report_evidence?
    validate_has_procurement_report_evidence == true
  end

  def validate_progress_updates_procurement_evidence?
    validate_progress_updates_procurement_evidence == true
  end

  def validate_progress_update_procurement?
    validate_progress_update_procurement == true
  end

  def validate_add_another_procurement?
    validate_add_another_procurement == true
  end

  def validate_date_correct?
    validate_date_correct == true
  end

  def validate_has_statutory_permissions_licence?
    validate_has_statutory_permissions_licence == true
  end

  def validate_progress_update_statutory_permissions_licence?
    validate_progress_update_statutory_permissions_licence == true
  end

  def validate_has_risk_update?
    validate_has_risk_update == true
  end
  
  def validate_has_risk_register?
    validate_has_risk_register == true
  end

  def validate_progress_update_risk_register?
    validate_progress_update_risk_register == true
  end

end
