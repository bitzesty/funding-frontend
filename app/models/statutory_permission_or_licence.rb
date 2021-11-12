# This statutory permissions or licence data needed to process a large 
# application started in Salesforce Experience.
class StatutoryPermissionOrLicence < ApplicationRecord
	include GenericValidator

  belongs_to :sfx_pts_payment, optional: true

  attr_accessor :validate_upload_question
	attr_accessor :validate_upload_files
  attr_accessor :validate_date_year_month_day
  attr_accessor :validate_licence_type
  attr_accessor :validate_licence_date

  attr_accessor :licence_date
  attr_accessor :licence_type
  attr_accessor :upload_question
  # These attributes are used to set individual error messages
  # for each of the project date input fields
  attr_accessor :date_day
  attr_accessor :date_month
  attr_accessor :date_year


  has_many_attached :upload_files

  validates :upload_question, presence: true, if: :validate_upload_question?
  validates :date_day, numericality: {
    greater_than: 0,
    less_than: 32,
  }, if: :validate_date_year_month_day?
  validates :date_month, numericality: {
    greater_than: 0,
    less_than: 13,
  }, if: :validate_date_year_month_day?
  validates :date_year, numericality: {
    greater_than: 1699,
    less_than: 4000,
  }, if: :validate_date_year_month_day?
  validates :licence_type, presence: true, if: :validate_licence_type?

  validate do

    validate_file_attached(
			:upload_files,
			I18n.t('activerecord.errors.models.statutory_permission_or_licence.' \
        'attributes.upload_files.inclusion')
		) if validate_upload_files?

    validate_date(
			:licence_date,
      :date_day,
      :date_month,
      :date_month
		) if validate_licence_date?

  end

  def validate_upload_files?
		validate_upload_files == true
	end

	def validate_upload_question?
		validate_upload_question == true
	end

  def validate_date_year_month_day?
		validate_date_year_month_day == true
	end

  def validate_licence_type?
		validate_licence_type == true
	end

  def validate_licence_date?
		validate_licence_date == true
	end

end
