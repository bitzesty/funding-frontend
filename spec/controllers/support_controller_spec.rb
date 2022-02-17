require 'rails_helper'

RSpec.describe SupportController do

  describe "get #show" do

    it "should render the :show template with an empty flash hash" do

      get :show

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(subject.request.flash[:errors]).to eq(nil)
    end
  end

  describe "post #update" do
    it 'should re-render the show page with an error when neither ' \
       'radio button is selected so the params hash is empty' do
      post :update, params: {}
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(subject.request.flash[:errors][:support_type]).to eq 'Not a valid choice'
    end

    it 'should redirect the report a problem page with no errors' do
      post :update, params: { support_type: 'report_a_problem' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:report_a_problem)
      expect(subject.request.flash[:errors]).to eq nil
    end

    it 'should redirect the ask a question page with no errors' do
      post :update, params: { support_type: 'ask_a_question' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:question_or_feedback)
      expect(subject.request.flash[:errors]).to eq nil
    end

    it 'should re-render the show page if an invalid choice is made in the params' do
      post :update, params: { support_type: 'unknown support type' }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(subject.request.flash[:errors][:support_type]).to eq "Not a valid choice"
    end
  end

  describe "get #report_a_problem" do
    it 'should render the :report_a_problem template with an empty flash hash' do
      get :report_a_problem
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors]).to eq(nil)
    end
  end

  describe 'post #process_problem' do

    it 'should re-render the report_a_problem template with an error ' \
        ' when the params hash is empty' do
      expect(subject).to receive(:clear_flash).with('problem').once
      post :process_problem, params: {}
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors][:support_problem_message]).to eq('Enter a message')
      expect(subject.request.flash[:errors][:support_problem_name]).to eq('Enter your name')
      expect(subject.request.flash[:errors][:support_problem_email]).to eq('Enter your email address')
    end

    it 'should re-render the report_a_problem template with errors ' \
        ' when the params hash is populated with empty values' do
      expect(subject).to receive(:clear_flash).with('problem').once
      post :process_problem,
        params: {
          support_problem_message: '',
          support_problem_email: '',
          support_problem_name: ''
        }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors][:support_problem_message]).to eq('Enter a message')
      expect(subject.request.flash[:errors][:support_problem_name]).to eq('Enter your name')
      expect(subject.request.flash[:errors][:support_problem_email]).to eq('Enter your email address')
    end

    it 'should re-render the report_a_problem template with errors ' \
        'when the support_problem_message is populated but other ' \
        'params are not' do
      expect(subject).to receive(:clear_flash).with('problem').once
      post :process_problem,
        params: {
          support_problem_message: 'test',
          support_problem_email: '',
          support_problem_name: ''
        }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors][:support_problem_message]).to eq(nil)
      expect(subject.request.flash[:errors][:support_problem_name]).to eq('Enter your name')
      expect(subject.request.flash[:errors][:support_problem_email]).to eq('Enter your email address')
    end

    it 'should re-render the report_a_problem template with errors ' \
        'when the support_problem_email is populated but other ' \
        'params are not' do
      expect(subject).to receive(:clear_flash).with('problem').once
      post :process_problem,
        params: {
          support_problem_message: '',
          support_problem_email: 'test',
          support_problem_name: ''
        }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors][:support_problem_message]).to eq('Enter a message')
      expect(subject.request.flash[:errors][:support_problem_name]).to eq('Enter your name')
      expect(subject.request.flash[:errors][:support_problem_email]).to eq(nil)
    end

    it 'should re-render the report_a_problem template with errors ' \
        'when the support_problem_name is populated but other ' \
        'params are not' do
      expect(subject).to receive(:clear_flash).with('problem').once
      post :process_problem,
        params: {
          support_problem_message: '',
          support_problem_email: '',
          support_problem_name: 'test' 
        }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      expect(subject.request.flash[:errors][:support_problem_message]).to eq('Enter a message')
      expect(subject.request.flash[:errors][:support_problem_name]).to eq(nil)
      expect(subject.request.flash[:errors][:support_problem_email]).to eq('Enter your email address')
    end

    it 'should re-render the report_a_problem template with no errors ' \
       'when a valid form is submitted' do
      expect(subject).to receive(:clear_flash).with('problem').twice
      expect(subject).to receive(:mail_report_a_problem).once.with('test', 'test', 'test')
      post :process_problem,
        params: {
          support_problem_message: 'test',
          support_problem_email: 'test',
          support_problem_name: 'test'
        }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:report_a_problem)
      # Assert that the Flash Hash has been cleared
      expect(subject.request.flash[:errors]).to eq({})
      expect(subject.request.flash[:success]).to eq(true)
    end
    
  end

  describe "get #question_or_feedback" do
    it 'should render the :report_a_problem template with an empty flash hash' do
      get :question_or_feedback
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:question_or_feedback)
      expect(subject.request.flash[:errors]).to eq(nil)
    end
  end

  describe 'post #process_question' do
    it 'should re-render the report_a_question template with an error ' \
        ' when the params hash is empty' do
      expect(subject).to receive(:clear_flash).with('question_or_feedback').once
      post :process_question, params: {}
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:question_or_feedback)
      expect(subject.request.flash[:errors][:support_question_or_feedback_message]).to eq('Enter a message')
    end

    it 'should re-render the report_a_question template with an error ' \
        ' when the message is empty, but the name and email are present' do
      expect(subject).to receive(:clear_flash).with('question_or_feedback').once
      post :process_question, params: {
        support_question_or_feedback_email: 'test email',
        support_question_or_feedback_name: 'test name'
      }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:question_or_feedback)
      expect(subject.request.flash[:errors][:support_question_or_feedback_message]).to eq('Enter a message')
      expect(subject.request.flash[:support_question_or_feedback_email]).to eq('test email')
      expect(subject.request.flash[:support_question_or_feedback_name]).to eq('test name')
    end

    it 'should re-render the report_a_question template with errors ' \
        ' when the params hash is populated with empty values' do
      expect(subject).to receive(:clear_flash).with('question_or_feedback').once
      post :process_question,
           params: {
             support_question_or_feedback_message: '',
             support_question_or_feedback_email: '',
             support_question_or_feedback_name: ''
           }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:question_or_feedback)
      expect(subject.request.flash[:errors][:support_question_or_feedback_message]).to eq('Enter a message')
    end

    it 'should re-render the report_a_question template with no errors ' \
       'when a valid form is submitted' do
      expect(subject).to receive(:clear_flash).with('question_or_feedback').twice
      expect(subject).to receive(:mail_question_or_feedback).once.with('test', 'test', 'test')
      post :process_question,
           params: {
             support_question_or_feedback_message: 'test',
             support_question_or_feedback_email: 'test',
             support_question_or_feedback_name: 'test'
           }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:question_or_feedback)
      # Assert that the Flash Hash has been cleared
      expect(subject.request.flash[:errors]).to eq({})
      expect(subject.request.flash[:success]).to eq(true)
    end

  end

  describe 'clear_flash' do
    it 'should take a parameter of page_type and clear ' \
        'the contents of the flash' do

      subject.flash[:errors] = 'errors'
      subject.flash[:success] = 'success'
      subject.flash["support_test_message"] = 'message'
      subject.flash["support_test_name"] = 'name'
      subject.flash["support_test_email"] = 'email'

      subject.clear_flash('test')

      expect(subject.flash[:errors]).to eq(nil)
      expect(subject.flash[:success]).to eq(nil)
      subject.flash["support_test_message"] = ''
      subject.flash["support_test_name"] = ''
      subject.flash["support_test_email"] = ''
    end
  end
end
