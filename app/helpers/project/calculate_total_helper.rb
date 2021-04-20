module Project::CalculateTotalHelper
  def calculate_total(object)
    object.select(:amount).map(&:amount).compact.sum
  end

  def calculate_vat_total(object)
    object.select(:vat_amount).map(&:vat_amount).compact.sum
  end
end