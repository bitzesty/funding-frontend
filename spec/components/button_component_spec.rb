require "rails_helper"
include ActionView::Helpers::FormHelper

RSpec.describe ButtonComponent, type: :component do

  it "should render default button component when called with no params" do

    expect(render_inline(ButtonComponent.new()).to_html)
        .to eq("<button class=\"govuk-button\" data-module=\"govuk-button\">" \
               "\n        Save and continue    \n</button>\n")

  end

  it "should render an anchor element when called with an element param " \
     "of 'a'" do

    expect(render_inline(ButtonComponent.new(element: "a")).to_html)
        .to eq("<a class=\"govuk-button\" data-module=\"govuk-button\" " \
               "href=\"#\" role=\"button\" draggable=\"false\">\n        " \
               "#{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render an anchor element with custom text when called with an " \
     "element param of 'a' and a text param of 'custom'" do

    expect(render_inline(ButtonComponent.new(element: "a", text: "custom"))
               .to_html)
        .to eq("<a class=\"govuk-button\" data-module=\"govuk-button\" " \
               "href=\"#\" role=\"button\" draggable=\"false\">\n        " \
               "custom    \n</a>\n")

  end

  it "should render an anchor element with custom data-method when called with an " \
     "element param of 'a' and a data_method param of 'custom'" do

    expect(render_inline(ButtonComponent.new(element: "a", data_method: "custom"))
               .to_html)
        .to eq("<a class=\"govuk-button\" data-module=\"govuk-button\" " \
               "href=\"#\" role=\"button\" data-method=\"custom\" draggable=\"false\">\n        " \
               "#{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render an anchor element with a custom link when called with " \
     "an element param of 'a' and a href param of 'custom'" do

    expect(render_inline(ButtonComponent.new(element: "a", href: "custom"))
               .to_html)
        .to eq("<a class=\"govuk-button\" data-module=\"govuk-button\" " \
               "href=\"custom\" role=\"button\" draggable=\"false\">\n      " \
               "  #{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render an input element with a default type of submit when " \
     "called with an element param of 'input' and no type param" do

    expect(render_inline(ButtonComponent.new(element: "input")).to_html)
        .to eq("<input class=\"govuk-button\" data-module=\"govuk-button" \
               "\" type=\"submit\" value=\"#{I18n.t("buttons.labels.default")}" \
               "\">\n")

  end

  it "should render an input element with a custom type when called with an " \
     "element param of 'input' and a type param" do

    expect(render_inline(ButtonComponent.new(element: "input", type: "button"))
               .to_html)
        .to eq("<input class=\"govuk-button\" data-module=\"govuk-button" \
               "\" type=\"button\" value=\"#{I18n.t("buttons.labels.default")}" \
               "\">\n")

  end

  it "should default to an element type of anchor if no element param has " \
     "been passed, but a href attribute has" do

    expect(render_inline(ButtonComponent.new(href: "custom")).to_html)
        .to eq("<a class=\"govuk-button\" data-module=\"govuk-button\" " \
               "href=\"custom\" role=\"button\" draggable=\"false\">\n      " \
               "  #{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render an anchor element with custom classes when called with " \
     "an element param of 'anchor' and a classes param" do

    expect(render_inline(ButtonComponent.new(element: "a", classes: "custom"))
               .to_html)
        .to eq("<a class=\"govuk-button custom\" data-module=\"govuk-button\"" \
               " href=\"#\" role=\"button\" draggable=\"false\">\n        " \
               "#{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render an anchor element with a disabled class when called with " \
     "an element param of 'anchor' and a disabled param of 'true'" do

    expect(render_inline(ButtonComponent.new(element: "a", disabled: true))
               .to_html)
        .to eq("<a class=\"govuk-button govuk-button--disabled\" data-module=" \
               "\"govuk-button\" href=\"#\" role=\"button\" draggable=\"false\"" \
               ">\n        #{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render a button element with a disabled class when called with " \
     "no element param and a disabled param of 'true'" do

    expect(render_inline(ButtonComponent.new(disabled: true))
               .to_html)
        .to eq("<button class=\"govuk-button govuk-button--disabled\" data-module=" \
               "\"govuk-button\" disabled aria-disabled=\"disabled\">\n     " \
               "   #{I18n.t("buttons.labels.default")}    \n</button>\n")

  end

  it "should render an anchor element with a start button class when called " \
     "with an element param of 'anchor' and a is_start_button param of true" do

    rendered_component = render_inline(ButtonComponent.new(
        element: "a",
        is_start_button: true)
    ).to_html

    expect(rendered_component).to include("</a>")
    expect(rendered_component).to include("govuk-button--start")
    expect(rendered_component).to include("</svg>")

  end

  it "should render a button element with a start button class when called " \
     "with no element param and a is_start_button param of true" do

    rendered_component = render_inline(ButtonComponent.new(
        is_start_button: true)
    ).to_html

    expect(rendered_component).to include("</button>")
    expect(rendered_component).to include("govuk-button--start")
    expect(rendered_component).to include("svg")

  end

  it "should render an anchor element with custom attributes when called " \
     "with an element param of 'a' and a populated attributes param" do

    expect(
        render_inline(
            ButtonComponent.new(
                element: "a",
                attributes: [
                    {attribute: "custom_param", value: "custom_value"},
                    {attribute: "another_custom_param", value: false}
                ]
            )
        ).to_html
    ).to eq("<a class=\"govuk-button\" data-module=" \
               "\"govuk-button\" custom_param=\"custom_value\" " \
               "another_custom_param=\"false\" href=\"#\" role=\"button\" " \
               "draggable=\"false\">\n        " \
               "#{I18n.t("buttons.labels.default")}    \n</a>\n")

  end

  it "should render default button component with a name attribute when " \
     "called with no element param and a populated name param" do

    expect(render_inline(ButtonComponent.new(name: "custom")).to_html)
        .to eq("<button class=\"govuk-button\" data-module=\"govuk-button\" " \
               "name=\"custom\">\n        Save and continue    \n</button>\n")

  end

  it "should render an input element with a name attribute when called with " \
     "an element param of 'input' and a populated name param" do

    expect(render_inline(ButtonComponent.new(element: "input", name: "custom"))
               .to_html)
        .to eq("<input class=\"govuk-button\" data-module=\"govuk-button\" " \
               "type=\"submit\" value=\"#{I18n.t("buttons.labels.default")}" \
               "\" name=\"custom\">\n")

  end

 it "should render data_disable when called with an data-disable param " \
    "of 'true'" do

    expect(render_inline(ButtonComponent.new(element: "input", name: "custom", data_disable: true))
              .to_html)
       .to eq("<input class=\"govuk-button\" data-module=\"govuk-button\" " \
              "type=\"submit\" value=\"#{I18n.t("buttons.labels.default")}" \
              "\" name=\"custom\" data-disable=\"true\">\n")

end

end
