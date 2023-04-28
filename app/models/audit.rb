class Audit < ApplicationRecord

  enum audit_action: {
    admin_contact_change: 0,
    admin_organisation_change: 1,
    admin_application_change: 2,
  }

end
