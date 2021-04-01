/*
  Function used to create the skeleton code for the GOV.UK-styled
  summary errors element
 */
window.createSummaryErrorsSkeleton = function() {

    var summaryErrorsElement = document.getElementById("summary-errors");

    addSummaryErrorsClassAndAttributes(summaryErrorsElement);

    if (!summaryErrorsElement.innerHTML.includes("h2")) {
        summaryErrorsElement.appendChild(createSummaryErrorsHeading());
    }

    if (!summaryErrorsElement.innerHTML.includes("div")) {
        var summaryErrorsBodyElement = createSummaryErrorsBody();
        summaryErrorsElement.appendChild(summaryErrorsBodyElement);
    } else {
        summaryErrorsBodyElement =
            document.getElementById("summary-errors-body");
    }

    if (!summaryErrorsElement.innerHTML.includes("ul")) {
        var summaryErrorsList = createSummaryErrorsList();
        summaryErrorsBodyElement.appendChild(summaryErrorsList);
    } else {
        summaryErrorsList = document.getElementById("summary-errors-list");
        summaryErrorsList.innerHTML = "";
    }

}

/*
  Function to create the GOV.UK-styled summary errors element
 */
export function addSummaryErrorsClassAndAttributes(summaryErrorsElement) {

    // Only add the govuk-error-summary class if it does not already exist
    if (!summaryErrorsElement.classList.contains("govuk-error-summary")) {
        summaryErrorsElement.classList.add("govuk-error-summary");
    }

    summaryErrorsElement.setAttribute("aria-labelledby", "error-summary-title");
    summaryErrorsElement.setAttribute("role", "alert");
    summaryErrorsElement.setAttribute("tabindex", "-1");
    summaryErrorsElement.setAttribute("data-module", "govuk-error-summary");

}

/*
  Function to create the heading for the GOV.UK-styled summary errors element
 */
export function createSummaryErrorsHeading() {

    var summaryErrorsHeading = document.createElement("h2");

    summaryErrorsHeading.classList.add("govuk-error-summary__title");

    summaryErrorsHeading.setAttribute("id", "error-summary-title");

    summaryErrorsHeading.innerText = "There is a problem";

    return summaryErrorsHeading;

}

/*
  Function to create the body for the GOV.UK-styled summary errors element
 */
export function createSummaryErrorsBody() {

    var summaryErrorsBodyElement = document.createElement("div");

    summaryErrorsBodyElement.classList.add("govuk-error-summary__body");

    summaryErrorsBodyElement.setAttribute("id", "summary-errors-body");

    return summaryErrorsBodyElement;

}

/*
  Function to create the list for the GOV.UK-styled summary errors element
 */
export function createSummaryErrorsList() {

    var summaryErrorsList = document.createElement("ul");

    summaryErrorsList.setAttribute("id", "summary-errors-list");

    summaryErrorsList.classList.add("govuk-list")
    summaryErrorsList.classList.add("govuk-error-summary__list");

    return summaryErrorsList;

}

/*
  Function to create a list item and append it to the existing list
  within the GOV.UK-styled summary errors element
 */
export function createAndAppendListItem(message, attribute, modelName) {

    var summaryErrorsList = document.getElementById("summary-errors-list");

    var listItemElement = document.createElement("li");
    var linkElement = document.createElement("a");

    linkElement.setAttribute("data-turbolinks", "false");

    if (attribute.includes(".")) {

        var nestedModelName = attribute.split(".")[0];
        var fieldName = attribute.split(".")[1];

        // Specific to the Cash contributions page
        if (fieldName === "secured")
            fieldName += "_yes_with_evidence";

        linkElement.setAttribute(
            "href",
            "#" + modelName + "_" + nestedModelName + "_attributes_0_" + fieldName);

    } else {

        switch (attribute) {
            case "governing_document_file":
                linkElement.setAttribute("href", "#" + modelName + "_governing_document_file");
                break;
            case "accounts_files":
                linkElement.setAttribute("href", "#" + modelName + "_accounts_files");
                break;
            case "cash_contribution_evidence_files":
                linkElement.setAttribute("href", "#project_cash_contributions_attributes_0_cash_contribution_evidence_files");
                break;
            case "evidence_of_support_files":
                linkElement.setAttribute("href", "#project_evidence_of_support_attributes_0_evidence_of_support_files");
                break;
            case "evidence_file":
                linkElement.setAttribute("href", "#payment_details_evidence_file");
                break;
            case "management_description":
                linkElement.setAttribute("href", "#open_medium_management_description");
                break;
            case "risk_register_file":
                linkElement.setAttribute("href", "#open_medium_risk_register_file");
                break;
            case "job_description_files":
                linkElement.setAttribute("href", "#open_medium_job_description_files");
                break;
            default:
                linkElement.setAttribute("href", attribute === "capital_work" ?
                    "#project_capital_work_false" : "#project_capital_work_true");
        }

    }

    linkElement.innerText = message;

    listItemElement.appendChild(linkElement);
    summaryErrorsList.appendChild(listItemElement);

}


window.addSummaryError = function(isNestedForm, attribute, message,
                                  modelName, childModelName) {

    var summaryErrorsElement = document.getElementById("summary-errors");

    /*
        Checking here to ensure that the summary errors component
        does not already include our message (so that we don't
        unnecessarily add it again), and that the errors hash attribute
        does not match the name of the nested model (to ensure that
        we don't add the superfluous 'nested_model_name is invalid' error)
     */
    if (!summaryErrorsElement.innerHTML.includes(message)
        && attribute !== childModelName) {

        createAndAppendListItem(
            message,
            attribute,
            modelName
        );

    }

};

window.addFormGroupError = function(formGroupElementId, formGroupErrorsElementId,
                                    attribute, message, modelName, parentModel) {

    if (attribute != modelName) {

        var mainFormGroupElement = document.getElementById(formGroupElementId);
        mainFormGroupElement.classList.add("govuk-form-group--error");

        if (attribute.includes("file")) {

            // We have a file input field and need to add the necessary
            // govuk-file-upload--error class accordingly.
                
            if (parentModel) {
                if (parentModel === "funding_application")
                    var fileElement = document.getElementById(parentModel + "_" + modelName + "_attributes_supporting_documents_files");
                else
                    var fileElement = document.getElementById(parentModel + "_" + modelName + "_attributes_0_" + attribute.replace(modelName + ".", ""));
            } else {
                var fileElement = document.getElementById(modelName + "_" + attribute);
            }

            fileElement.classList.add("govuk-file-upload--error");

        }

        var formGroupErrorsElement = document.getElementById(formGroupErrorsElementId);

        // Only add the error message if it is not already present
        if (!formGroupErrorsElement.innerHTML.includes(message)) {

            var spanElement = document.createElement("span");
            spanElement.setAttribute("id", "project[" + attribute + "]-error");
            spanElement.classList.add("govuk-error-message");
            spanElement.innerHTML = "<span class='govuk-visually-hidden'>Error: </span>" + message;

            formGroupErrorsElement.appendChild(spanElement);

        }

    }

};

window.removeFormGroupErrors = function(model, attributeNames, errors) {

    for (var i = 0; i < attributeNames.length; i++) {
        if (errors.includes(model + "." + attributeNames[i]) === false) {
            var formGroupElement = document.getElementById(model + "." + attributeNames[i] + "-form-group");
            var formGroupErrorsElement = document.getElementById(model + "." + attributeNames[i] + "-errors");
            formGroupElement.classList.remove("govuk-form-group--error");
            formGroupErrorsElement.innerHTML = "";
        }
    }

};

window.removeAllFormGroupErrors = function(formGroupId, formGroupErrorsId) {

    var formGroupElement = document.getElementById(formGroupId);
    var formGroupErrorsElement = document.getElementById(formGroupErrorsId);
    formGroupElement.classList.remove("govuk-form-group--error");
    formGroupErrorsElement.innerHTML = "";

};
