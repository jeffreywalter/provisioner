class ProvisionController < ApplicationController
  include ActionController::Live

  def new
    render :new, locals: { companies: companies }
  end

  def index
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      # fake_provision
      provision_property
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  private

  def sse
    @sse ||= SSE.new(response.stream)
  end

  def provision_property
    results = reactor.create_property(company_id, property_name)
    property = results[:doc]
    render_text("Created property '#{property_name}'", results)

    # create a dev environment : save the embed code
    results = reactor.create_environment(property.id, "My Precious")
    environment = results[:doc]
    render_text("Created Development Environment 'My Precious'", results)
    embed_code = environment.library_url

    # install the dtm extension
    dtm = reactor.extension_package_for('dtm')
    results = reactor.create_extension(property.id, dtm.id)
    render_text("Added the DTM extension", results)
    dtm_ext = results[:doc]

    # install the aa extension
    aa = reactor.extension_package_for('adobe-analytics')
    results = reactor.create_extension(property.id, aa.id)
    render_text("Added the Adobe Analytics Extension", results)
    aa_ext = results[:doc]

    # create an AA config and add evars
    results = reactor.create_aa_config(aa_ext.id, aa)
    render_text("Created Adobe Analytics Configuration 'My Awesome Analytics Account'", results)

    # create a js data element named shopping_cart
    results = reactor.create_data_element(property.id, "shopping_cart", dtm_ext)
    render_text("Created Data Element 'shopping_cart'", results)

    # create a rule
    1.times do
      name = FFaker::Company.bs.titleize
      results = reactor.create_rule(property.id, name)
      rule = results[:doc]
      render_text("Created rule '#{name}'", results)

      results = reactor.create_click_rule_component(rule.id, dtm_ext)
      render_text("Created click event for rule '#{name}'", results)
    end
    ## Create a click event
    ## Create a browser condition
    ## Create a AA action

    # create a rule
    ## Create a dead header event
    ## Create a condition
    ## Create a custom action

    # create a library

    # add resources to library

    # deploy library

    # fetch the embed and display
  end

  def companies
    reactor.companies
  end

  def reactor
    @reactor ||= Reactor.new(access_token)
  end

  def access_token
    @access_token ||= AccessToken.new.generate
  end

  def render_text(title, results)
    payload = JSON.pretty_generate(results[:response])
    code = Pygments.highlight(payload ,:lexer => 'ruby')
    data = { title: title, code: code, url: results[:url] }
    t = render_to_string(partial: 'event', formats: [:html], locals: data)
    sse.write(t)
  end

  def company_id
    @company_id ||= params[:company_id]
  end

  def property_name
    @property_name ||= params[:property_name]
  end

  def fake_provision
    url = "https://mc-api-activation-dtm-qe.adobe.io/companies/co3880672ae2e5466fa5bc311d0a46f841/properties"
    render_text("Created property Fake", url, mock_result)
    sleep 0.5
    render_text("Added the DTM Extension", url, mock_result)
    sleep 0.5
    render_text("Added the Adobe Analytics Extension", url, mock_result)
    sleep 0.5
    render_text("Created an Adobe Analytics Configuration", url, mock_result)
  end

  def mock_result
    {
      "data": {
        "id": "PR84158e44dbfa46049416666a2f1d5351",
        "type": "properties",
        "attributes": {
        "created_at": "2016-12-13T02:39:38.851Z",
        "enabled": true,
        "name": "CLI3",
        "updated_at": "2016-12-13T02:39:38.851Z"
      },
      "links": {
        "self": "https://mc-api-activation-dtm-qe.adobe.io/properties/PR84158e44dbfa46049416666a2f1d5351",
        "company": "https://mc-api-activation-dtm-qe.adobe.io/companies/CO3880672ae2e5466fa5bc311d0a46f841",
        "data_elements": "https://mc-api-activation-dtm-qe.adobe.io/properties/PR84158e44dbfa46049416666a2f1d5351/data_elements",
        "environments": "https://mc-api-activation-dtm-qe.adobe.io/properties/PR84158e44dbfa46049416666a2f1d5351/environments",
        "extensions": "https://mc-api-activation-dtm-qe.adobe.io/properties/PR84158e44dbfa46049416666a2f1d5351/extensions",
        "rules": "https://mc-api-activation-dtm-qe.adobe.io/properties/PR84158e44dbfa46049416666a2f1d5351/rules"
      },
      "meta": {
        "extensions_count": 0,
        "approvals_open_count": 0,
        "approvals_rejected_count": 0,
        "approvals_unassigned_count": 0,
        "last_published_at": "2016-12-12T02:39:38.860Z"
      }
      }
    }
  end

end
