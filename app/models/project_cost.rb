class ProjectCost < ApplicationRecord
  belongs_to :project

  validates :cost_type, presence: true
  validates :amount, numericality: {only_integer: true}
  validates :description, presence: true

  enum cost_type: {
      new_staff: 0,
      professional_fees: 1,
      recruitment: 2,
      purchase_price_of_heritage_items: 3,
      repair_and_conservation_work: 4,
      event_costs: 5,
      digital_outputs: 6,
      equipment_and_materials_including_learning_materials: 7,
      training_for_staff: 8,
      training_for_volunteers: 9,
      travel_for_staff: 10,
      travel_for_volunteers: 11,
      expenses_for_staff: 12,
      expenses_for_volunteers: 13,
      other: 14,
      publicity_and_promotion: 15,
      evaluation: 16,
      contingency: 17
  }
end

