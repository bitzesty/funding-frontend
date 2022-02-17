# Controller responsible for processing support page requests
class SupportController < ApplicationController

  include Mailers::SupportMailerHelper

  # Method responsible for rendering the root Support page
  def show
    flash[:errors] = nil
  end

  # Method responsible for rendering the 'Report a problem' page
  def report_a_problem
    clear_flash('problem')
  end

  # Method responsible for rendering the 'Ask a question or give feedback' page
  def question_or_feedback
    clear_flash('question_or_feedback')
  end

  # Method responsible for handling 'Report a problem' form submission
  def process_problem
    logger.info 'User submitted POST /report-a-problem form'

    flash[:errors] = {}

    if params[:support_problem_message].present?
      flash[:support_problem_message] = params[:support_problem_message]
    else
      flash[:errors][:support_problem_message] = 'Enter a message'
    end

    if params[:support_problem_name].present?
      flash[:support_problem_name] = params[:support_problem_name]
    else
      flash[:errors][:support_problem_name] = 'Enter your name'
    end

    if params[:support_problem_email].present?
      flash[:support_problem_email] = params[:support_problem_email]
    else
      flash[:errors][:support_problem_email] = 'Enter your email address'
    end

    if flash[:errors].empty?

      logger.debug 'Validation succeeded for POST /report-a-problem form'

      logger.debug 'Calling mail_report_a_problem'

      mail_report_a_problem(
        params[:support_problem_message],
        params[:support_problem_name],
        params[:support_problem_email]
      )

      logger.debug 'Finished calling mail_report_a_problem'

      # Flash Hash contains populated fields
      clear_flash('problem')

      flash[:success] = true

    end

    logger.info 'Finished processing of POST /report-a-problem form, re-rendering page'

    render :report_a_problem

    # Flash Hash could contain populated fields, errors, or success key
    clear_flash('problem')

  end

  # method responsible for handling 'Ask a question or give feedback' form submission
  def process_question

    logger.info 'User submitted POST /question-or-feedback form'

    flash[:errors] = {}

    if params[:support_question_or_feedback_message].present?
      flash[:support_question_or_feedback_message] = params[:support_question_or_feedback_message]
    else
      flash[:errors][:support_question_or_feedback_message] = 'Enter a message'
    end

    flash[:support_question_or_feedback_name] = params[:support_question_or_feedback_name] if
        params[:support_question_or_feedback_name].present?
    flash[:support_question_or_feedback_email] = params[:support_question_or_feedback_email] if
        params[:support_question_or_feedback_email].present?

    if flash[:errors].empty?

      logger.debug 'Validation succeeded for POST /question-or-feedback form'

      logger.debug 'Calling SupportMailer.question_or_feedback_email'

      mail_question_or_feedback(
        params[:support_question_or_feedback_message],
        params[:support_question_or_feedback_name],
        params[:support_question_or_feedback_email]
      )

      logger.debug 'Finished calling SupportMailer.question_or_feedback_email'

      clear_flash('question_or_feedback')

      flash[:success] = true

    end

    logger.info 'Finished processing of POST /question-or-feedback form, re-rendering page'

    render :question_or_feedback

    # Flash Hash could contain populated fields, errors, or success key
    clear_flash('question_or_feedback')

  end

  # Method responsible for handling root Support form submission
  def update

    if params.key?('support_type')

      if params[:support_type] == 'report_a_problem'

        logger.info('Validation of POST /support form successful, redirecting user to /report-a-problem')

        redirect_to(:report_a_problem)

      elsif params[:support_type] == 'ask_a_question'

        logger.info 'Validation of POST /support form successful, redirecting user to /question-or-feedback'

        redirect_to :question_or_feedback

      else

        logger.info 'Validation failed when posting support question form, ' \
                      'invalid support_type parameter found'

        logger.debug "POST /support form contained a support_type parameter of '#{params[:support_type]}'"

        flash[:errors] = {
          support_type: 'Not a valid choice'
        }

        render :show

      end

    else

      logger.info 'Validation failed when posting support question form, ' \
                    'no support_type parameter found'

      flash[:errors] = {
        support_type: 'Not a valid choice'
      }

      render :show

    end

  end

  # Reusable method for clearing existing FlashHash key/value pairs
  # related to the Support pages
  #
  # @param [String] page_type Used to orchestrate which key/value pairs are cleared
  def clear_flash(page_type)

    flash[:errors] = nil
    flash[:success] = nil
    flash["support_#{page_type}_message"] = nil
    flash["support_#{page_type}_name"] = nil
    flash["support_#{page_type}_email"] = nil

  end

end
