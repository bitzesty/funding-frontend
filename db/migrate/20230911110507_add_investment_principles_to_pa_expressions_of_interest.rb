class AddInvestmentPrinciplesToPaExpressionsOfInterest < ActiveRecord::Migration[7.0]
  def change
   add_column :pa_expressions_of_interest, :investment_principles, :text
  end
end
