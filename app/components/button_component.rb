class ButtonComponent < ViewComponent::Base

  # See examples of this component at:
  # /rails/components/button_component/

  # https://github.com/github/actionview-component#content-areas
  with_content_areas :html

  # API for the button component based on GOVUK Design System
  # https://design-system.service.gov.uk/components/button/
  # (Refer to nunjucks macro options)
  #
  # @param [String] text The button text, for example, "Start"
  # @param [String] element The HTML element will default to 'button'
  # @param [String] href the contents of the HREF attribute, this being present 
  #                      will override the element and set it to be an
  #                      anchor 'a'
  # @param [String] classes HTML class attribute contents
  # @param [String] type gives the button the type attribute and sets to value
  # @param [Array] attributes array of objects :attribute, :value
  # @param [String] name used for button element
  # @param [String] value add value attribute for button
  # @param [string] data_method Rails function that allows HTTP methods 
  #                 other than GET to be used.
  # @param [Boolean] disabled is the button disabled - disabled and aria
  #                           attributes will be set
  # @param [Boolean] is_start_button Use to configure as call to action 'start'
  #                                  button
  # @param [Boolean] data-disable Used to disable a button once clicked for
  #                               Javascript enabled applicants.

  def initialize (
      text: nil, element: nil, href: nil, classes: nil, attributes: nil,
      type: nil, name: nil, value: nil, data_method: nil, disabled: false, 
      is_start_button: false, data_disable: false
  )

    # If a text parameter has been passed into the initialiser, then use
    # this to populate the text value, otherwise use the default button label
    @text = text.present? ? text : I18n.t("buttons.labels.default")

    # If the element is an input element, then default it's type attribute
    # value to 'submit' unless a type parameter has also been passed into the
    # component initialiser
    @type = type.present? ? type : "submit" if element == "input"

    # If an element parameter has been passed in, then use this
    # to determine which element to render
    unless element.nil?
      @element = element

    # Otherwise, determine which element to render based on the attributes
    # which have been passed into the component initialiser
    else

      # If an href attribute is present, then render an anchor element,
      # otherwise default to rendering a button element
      @element = href.present? ? "a" : "button"

    end

    # If the element is an anchor element, then default it's href
    # attribute unless it has also been passed into the component
    # initialiser
    @href = href.present? ? href : "#" if @element == "a"

    @data_method = data_method.present? ? data_method : nil

    # Create the class string based on parameters passed into the component
    # initialiser
    additional_classes = classes.present? ? " #{classes}" : ""
    disabled_button_class = disabled ? " govuk-button--disabled" : ""
    start_button_class = is_start_button ? " govuk-button--start" : ""
    class_names = %(govuk-button#{additional_classes}#{disabled_button_class}#{start_button_class})
      
    @name = name
    @value = value
    @attributes = attributes
    @disabled = disabled
    @is_start_button = is_start_button
    @data_disable_string = data_disable ? "data-disable=true" : ""

    # All button types have these common attributes
    @common_attributes = %(class="#{class_names}" data-module="govuk-button")

    # If an attributes array of objects has been passed into the component
    # initialiser, then add this to the common_attributes string
    if attributes.present?
      attributes.each do | attribute |
        @common_attributes += %( #{attribute[:attribute]}="#{attribute[:value]}")
      end
    end

    # Button/input buttons will share the following attributes
    @button_attributes = ""

    @button_attributes += %( name="#{@name}") if name.present?

    @button_attributes += %(disabled="disabled" aria-disabled="disabled") if
        disabled

  end

  # This becomes available in the calling block
  attr_reader :text

end
