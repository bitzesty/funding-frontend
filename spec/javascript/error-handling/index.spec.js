import {addSummaryErrorsClassAndAttributes} from 'index.js';
import {createSummaryErrorsHeading} from 'index.js';
import {createSummaryErrorsBody} from 'index.js';
import {createSummaryErrorsList} from 'index.js';
import {createAndAppendListItem} from 'index.js';
require('index.js');

/**
 * This function encapsulates common assertions for the createAndAppendListItem function.
 * Lots of tests target this function - so common assertions go here.
 * @param {string} attribute - a particular attribute on a model (in format 'attribute_name', \
 * or in format 'nested_model.attribute_name').
 */
function createAndAppendListItemCommonAssertions(attribute) {

  var message = 'message';
  var modelName = 'modelName string';

  var summaryErrorsList = createSummaryErrorsList();
  document.body.append(summaryErrorsList);

  createAndAppendListItem(message, attribute, modelName);

  var listItemElement = summaryErrorsList.firstElementChild;
  var linkElement = listItemElement.firstElementChild;
  
  expect(summaryErrorsList.getElementsByTagName('li').length).toEqual(1);
  expect(listItemElement.getElementsByTagName('a').length).toEqual(1);
  expect(linkElement.getAttribute('data-turbolinks')).toEqual('false');
  expect(linkElement.innerText).toEqual(message);

  return linkElement;

}

/**
 * This function encapsulates common code necessary to test addSummaryError.
 */
function addSummaryErrorHelper() {

  var summaryErrorsList = createSummaryErrorsList();

  var listItem = document.createElement('li');
  listItem.textContent += 'message';
  summaryErrorsList.appendChild(listItem);
  
  var summaryErrorsElement = document.createElement('div');
  summaryErrorsElement.setAttribute('id', 'summary-errors');

  summaryErrorsElement.appendChild(summaryErrorsList);

  document.body.append(summaryErrorsElement);

  return summaryErrorsList;

}

/**
 * Helper function to create a div element with a specified id attribute
 * @param {string} id - a unique identifier for the id attribute of the element
 */
function createDivWithId(id) {

  var div = document.createElement('div');
  div.setAttribute('id', id);

  return div;

}

/**
 * Helper function to create a input element with a specified id attribute
 * @param {string} id - a unique identifier for the id attribute of the element
 */
function createInputWithId(id) {

  var input = document.createElement('input');
  input.setAttribute('id', id);

  return input;

}

describe('error-handling test suite', () => {
  
 /**
 * We clear the document contents - otherwise it persists between tests. 
 * We clear all mocks, otherwise they persist between tests
 */
  afterEach(() => {
    document.getElementsByTagName('html')[0].innerHTML = '';
    jest.clearAllMocks();
  });

  test('addSummaryErrorsClassAndAttributes should not add govuk-error-summary class if it already existed', () => {

    var test_div = document.createElement('div');
    test_div.classList.add('govuk-error-summary');

    var spy = jest.spyOn(test_div.classList, 'add');
  
    addSummaryErrorsClassAndAttributes(test_div);

    expect(spy).toHaveBeenCalledTimes(0);
  
    expect(test_div.getAttribute('aria-labelledby')).toEqual('error-summary-title');
    expect(test_div.getAttribute('role')).toEqual('alert');
    expect(test_div.getAttribute('tabindex')).toEqual('-1');
    expect(test_div.getAttribute('data-module')).toEqual('govuk-error-summary');
  
  });
  
  test('addSummaryErrorsClassAndAttributes should add govuk-error-summary class if it did not already exist', () => {
  
    var test_div = document.createElement('div');
    
    var spy = jest.spyOn(test_div.classList, 'add');
  
    addSummaryErrorsClassAndAttributes(test_div);
  
    expect(test_div.classList.contains('govuk-error-summary')).toEqual(true);
  
    expect(spy).toHaveBeenCalledTimes(1);
  
    expect(test_div.getAttribute('aria-labelledby')).toEqual('error-summary-title');
    expect(test_div.getAttribute('role')).toEqual('alert');
    expect(test_div.getAttribute('tabindex')).toEqual('-1');
    expect(test_div.getAttribute('data-module')).toEqual('govuk-error-summary');
  
  });
  
  
  test('createSummaryErrorsHeading should create element as expected', () => {
  
    var summaryErrorsHeading = createSummaryErrorsHeading();
  
    expect(summaryErrorsHeading.nodeName.toLowerCase()).toEqual('h2');
    expect(summaryErrorsHeading.classList.contains('govuk-error-summary__title')).toEqual(true);
    expect(summaryErrorsHeading.getAttribute('id')).toEqual('error-summary-title');
    expect(summaryErrorsHeading.innerText).toEqual('There is a problem');
  
  });
  
  
  test('createSummaryErrorsBody should create element as expected', () => {
  
    var summaryErrorsBody = createSummaryErrorsBody();
  
    expect(summaryErrorsBody.nodeName.toLowerCase()).toEqual('div');
    expect(summaryErrorsBody.classList.contains('govuk-error-summary__body')).toEqual(true);
    expect(summaryErrorsBody.getAttribute('id')).toEqual('summary-errors-body');
  
  });
  
  
  test('createSummaryErrorsList should create element as expected', () => {
  
    var summaryErrorsList = createSummaryErrorsList();
  
    expect(summaryErrorsList.nodeName.toLowerCase()).toEqual('ul');
    expect(summaryErrorsList.getAttribute('id')).toEqual('summary-errors-list');
    expect(summaryErrorsList.classList.contains('govuk-list')).toEqual(true);
    expect(summaryErrorsList.classList.contains('govuk-error-summary__list')).toEqual(true);
  
  });
  
  
  test('createSummaryErrorsSkeleton should create elements as expected', () => {
  
    var summaryErrorsElement = createDivWithId('summary-errors');
    document.body.append(summaryErrorsElement);
  
    window.createSummaryErrorsSkeleton();
  
    expect(summaryErrorsElement.classList.contains('govuk-error-summary')).toEqual(true);
    expect(summaryErrorsElement.getAttribute('aria-labelledby')).toEqual('error-summary-title');
    expect(summaryErrorsElement.getAttribute('role')).toEqual('alert');
    expect(summaryErrorsElement.getAttribute('tabindex')).toEqual('-1');
    expect(summaryErrorsElement.getAttribute('data-module')).toEqual('govuk-error-summary');
  
    var summaryErrorsHeading = document.getElementById('error-summary-title');
    expect(summaryErrorsHeading.nodeName.toLowerCase()).toEqual('h2');
    expect(summaryErrorsHeading.innerText).toEqual('There is a problem');
  
    var summaryErrorsBody = document.getElementById('summary-errors-body');
    expect(summaryErrorsBody.nodeName.toLowerCase()).toEqual('div');
    expect(summaryErrorsBody.classList.contains('govuk-error-summary__body')).toEqual(true);
  
    var summaryErrorsList = document.getElementById('summary-errors-list');
    expect(summaryErrorsList.nodeName.toLowerCase()).toEqual('ul');
    expect(summaryErrorsList.classList.contains('govuk-list')).toEqual(true);
    expect(summaryErrorsList.classList.contains('govuk-error-summary__list')).toEqual(true);
  
  });
  
  test('createSummaryErrorsSkeleton when skeleton structure already exists', () => {
  
    var summaryErrorsElement = createDivWithId('summary-errors');
    summaryErrorsElement.innerHTML = '<h2>Test</h2><div id="summary-errors-body"><ul id="summary-errors-list"><li>Test</li></ul></div>';
    document.body.append(summaryErrorsElement);

    var spy = jest.spyOn(document, 'getElementById');
  
    window.createSummaryErrorsSkeleton();

    expect(spy.mock.calls).toEqual(
      [
        ['summary-errors'],
        ['summary-errors-body'],
        ['summary-errors-list']
      ]
    );

    expect(document.getElementById('error-summary-title')).toEqual(null);
    expect(document.getElementById('summary-errors-list').innerHTML).toEqual('');
  
  });


  test('createAndAppendListItem - test governing_document_file href added', () => {

    var linkElement = createAndAppendListItemCommonAssertions('governing_document_file')    
    expect(linkElement.getAttribute('href')).toEqual('#modelName string_governing_document_file');

  });


  test('createAndAppendListItem - test project_accounts_files href added', () => {

    var linkElement = createAndAppendListItemCommonAssertions('accounts_files')    
    expect(linkElement.getAttribute('href')).toEqual('#modelName string_accounts_files');
    
  });


  test('createAndAppendListItem - test project_capital_work_true href added', () => {

    var linkElement = createAndAppendListItemCommonAssertions('something not governing_document_file or accounts_files')
    expect(linkElement.getAttribute('href')).toEqual('#project_capital_work_true');

  });


  test('createAndAppendListItem - test project_capital_work_false href added', () => {

    var linkElement = createAndAppendListItemCommonAssertions('capital_work')
    expect(linkElement.getAttribute('href')).toEqual('#project_capital_work_false');
  
  });


  test('createAndAppendListItem - test href added for a nested attribute with a secured fieldname', () => {
 
    var linkElement = createAndAppendListItemCommonAssertions('nestedModelName.secured')

    expect(linkElement.getAttribute('href')).toEqual(
      '#modelName string_nestedModelName_attributes_0_secured_yes_with_evidence');

  });


  test('createAndAppendListItem - test href added for a nested attribute with a fieldname not secured', () => {

    var linkElement = createAndAppendListItemCommonAssertions('nestedModelName.not_secured')

    expect(linkElement.getAttribute('href')).toEqual(
      '#modelName string_nestedModelName_attributes_0_not_secured');
      
  });


  test('addSummaryError - test nothing appended if the message already exists', () => {

    var summaryErrorsList = addSummaryErrorHelper();

    window.addSummaryError(true, 'an attribute', 'message', 'a modelname', 'a child modelname');

    // We initialised the test with one list item.  
    // So only one list item should exist after calling addSummaryError.
    expect(summaryErrorsList.childElementCount).toEqual(1);

  });

  test('addSummaryError - test nothing appended if the attribute is equal to the childModelName', () => {

    var summaryErrorsList = addSummaryErrorHelper();

    // The attribute and childModelName arguments match in this instance - 'project' and 'project'
    window.addSummaryError(true, 'project', 'message', 'model', 'project');

    // We initialised the test with one list item.
    // So, only one list item should exist after calling addSummaryError
    expect(summaryErrorsList.childElementCount).toEqual(1);

  });

  test('addSummaryError - test that a new list item is created if the message did not already exist', () => {

    var summaryErrorsList = addSummaryErrorHelper();

    window.addSummaryError(true, 'attribute', 'msg', 'model', 'childModelName');

    expect(summaryErrorsList.childElementCount).toEqual(2);

    // First child should be as added above
    expect(summaryErrorsList.firstChild.innerHTML).toEqual('message');

    // Second child should be a li element containing an anchor element (firstChild) which
    // contains the text 'msg'
    // <li><a href="...">msg</a></li>
    expect(summaryErrorsList.children[1].firstChild.innerText).toEqual('msg');

  });

  test('addFormGroupError - test that nothing happens if attribute and modelName match', () => {

    var spy = jest.spyOn(document, 'getElementById');

    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'matchingArg', 'message', 'matchingArg', 'parentModel');

    expect(spy).toHaveBeenCalledTimes(0);

  });


  test('addFormGroupError - test for no file, and that the message is already present', () => {

    var spy = jest.spyOn(document, 'getElementById');

    var formGroupElement = createDivWithId('formGroupElementId');
    var formGroupErrorsElement = createDivWithId('formGroupErrorsElementId');
    formGroupErrorsElement.textContent += 'message';

    formGroupElement.append(formGroupErrorsElement);

    document.body.append(formGroupElement);
    
    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'attribute', 'message', 'modelName', 'parentModel');
    
    expect(spy).toHaveBeenCalledTimes(2);

    expect(spy.mock.calls).toEqual(
      [
        ['formGroupElementId'],
        ['formGroupErrorsElementId']
      ]
    );

   expect(formGroupElement.classList.contains('govuk-form-group--error')).toEqual(true);
   expect(formGroupElement.childElementCount).toEqual(1);
   expect(formGroupErrorsElement.childElementCount).toEqual(0);

  });


  test('addFormGroupError - test that span element created, when message not already there', () => {

    var spy = jest.spyOn(document, 'getElementById');

    var formGroupElement = createDivWithId('formGroupElementId');
    var formGroupErrorsElement = createDivWithId('formGroupErrorsElementId');

    formGroupElement.append(formGroupErrorsElement);

    document.body.append(formGroupElement);
    
    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'attribute', 'message', 'modelName', 'parentModel');

    expect(formGroupErrorsElement.firstChild.nodeName.toLowerCase()).toEqual("span")
    expect(formGroupErrorsElement.firstChild.getAttribute('id')).toEqual("project[attribute]-error")
    expect(formGroupErrorsElement.firstChild.classList.contains('govuk-error-message')).toEqual(true)

    expect(formGroupErrorsElement.firstChild.innerHTML).toEqual("<span class=\"govuk-visually-hidden\">Error: </span>message");
    
  });

  test('addFormGroupError - called with attribute containing "file", but not with a parentModel argument', () => {

    var formGroupElement = createDivWithId('formGroupElementId');
    var formGroupErrorsElement = createDivWithId('formGroupErrorsElementId');

    formGroupElement.append(formGroupErrorsElement);

    document.body.append(formGroupElement);

    var fileElement = createInputWithId('modelName_attribute_file');

    document.body.append(fileElement);

    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'attribute_file', 'message', 'modelName');

    expect(fileElement.classList.contains('govuk-file-upload--error')).toEqual(true);

  });

  test('addFormGroupError - called with attribute containing "file", with a parentModel argument not equal to "funding_application"', () => {

    var formGroupElement = createDivWithId('formGroupElementId');
    var formGroupErrorsElement = createDivWithId('formGroupErrorsElementId');

    formGroupElement.append(formGroupErrorsElement);

    document.body.append(formGroupElement);

    var fileElement = createInputWithId('parentModel_modelName_attributes_0_attribute_file');

    document.body.append(fileElement);

    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'attribute_file', 'message', 'modelName', 'parentModel');

    expect(fileElement.classList.contains('govuk-file-upload--error')).toEqual(true);

  });

  test('addFormGroupError - called with attribute containing "file", with a parentModel argument equal to "funding_application"', () => {

    var formGroupElement = createDivWithId('formGroupElementId');
    var formGroupErrorsElement = createDivWithId('formGroupErrorsElementId');

    formGroupElement.append(formGroupErrorsElement);

    document.body.append(formGroupElement);

    var fileElement = createInputWithId('funding_application_modelName_attributes_supporting_documents_files');

    document.body.append(fileElement);

    window.addFormGroupError('formGroupElementId', 'formGroupErrorsElementId', 'attribute_file', 'message', 'modelName', 'funding_application');

    expect(fileElement.classList.contains('govuk-file-upload--error')).toEqual(true);

  });

  test('removeFormGroupErrors - errors includes "model.attributeNames[i]"', () => {

    var spy = jest.spyOn(document, 'getElementById');

    window.removeFormGroupErrors('modelName', ['attribute1'], ['modelName.attribute1']);

    expect(spy).toHaveBeenCalledTimes(0);

  });

  test('removeFormGroupErrors - errors does not include "model.attributeNames[i]"', () => {

    var formGroupElement = createDivWithId('modelName.attribute1-form-group');
    var formGroupErrorsElement = createDivWithId('modelName.attribute1-errors');

    formGroupElement.classList.add('govuk-form-group--error');
    formGroupElement.classList.add('dont-remove-me');
    formGroupErrorsElement.innerHTML = '<p> some error text </p>';

    formGroupElement.append(formGroupErrorsElement);
    document.body.append(formGroupElement);

    window.removeFormGroupErrors('modelName', ['attribute1'], ['model.attribute2']);

    expect(formGroupElement.classList.contains('govuk-form-group--error')).toEqual(false);
    expect(formGroupElement.classList.contains('dont-remove-me')).toEqual(true);
    expect(formGroupErrorsElement.innerHTML).toEqual('');

  });

  test('removeFormGroupErrors - test loop to check it can still remove from classList and innerHTML"', () => {

    var formGroupElement1 = createDivWithId('modelName.attribute1-form-group');
    var formGroupErrorsElement1 = createDivWithId('modelName.attribute1-errors');
    formGroupElement1.classList.add('govuk-form-group--error');
    formGroupElement1.classList.add('dont-remove-me');
    formGroupErrorsElement1.innerHTML = '<p> some error text </p>';

    formGroupElement1.append(formGroupErrorsElement1);

    document.body.append(formGroupElement1);

    var formGroupElement2 = createDivWithId('modelName.attribute2-form-group');
    var formGroupErrorsElement2 = createDivWithId('modelName.attribute2-errors');
    formGroupElement2.classList.add('govuk-form-group--error');
    formGroupElement2.classList.add('dont-remove-me');
    formGroupErrorsElement2.innerHTML = '<p> some error text </p>';


    formGroupElement2.append(formGroupErrorsElement2);

    document.body.append(formGroupElement2);

    window.removeFormGroupErrors('modelName', ['attribute1', 'attribute2'], ['model.attribute3']);

    expect(formGroupElement1.classList.contains('govuk-form-group--error')).toEqual(false);
    expect(formGroupElement2.classList.contains('govuk-form-group--error')).toEqual(false);
    expect(formGroupElement1.classList.contains('dont-remove-me')).toEqual(true);
    expect(formGroupElement2.classList.contains('dont-remove-me')).toEqual(true);
    expect(formGroupErrorsElement1.innerHTML).toEqual('');
    expect(formGroupErrorsElement2.innerHTML).toEqual('');

  });

});
