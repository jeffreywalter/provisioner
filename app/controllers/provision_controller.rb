class ProvisionController < ApplicationController
  def new
    render :new, locals: { companies: companies_for_select }
  end

  def index
    render :index, locals: { provisions: Provision.all.order('created_at DESC') }
  end

  def stream
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

  def provision
    @provision ||= Provision.create(company_name: company_name, company_id: company_id, property_name: property_name)
  end

  def provision_property
    results = reactor.create_property(company_id, property_name: property_name)
    @property = results[:doc]
    render_text("Created property '#{property_name}'", results, "#{property_url}/overview")

    # create a dev Host
    results = reactor.create_host(property.id, "Cloudy Cloud")
    host = results[:doc]
    aurl = "#{property_url}/hosts/#{host&.id}"
    render_text("Created Host 'Cloudy Cloud'", results, aurl)

    # create a dev environment : save the embed code
    results = reactor.create_environment(property.id, host.id, "My Precious")
    environment = results[:doc]
    aurl = "#{property_url}/environments/#{environment&.id}"
    render_text("Created Development Environment 'My Precious'", results, aurl)

    # install the dtm extension
    dtm = reactor.extension_package_for('core')
    dtm_ext = reactor.extension_for(property.id, dtm)
    dtm_ext.extension_package = dtm
    # results = reactor.create_extension(property.id, dtm.id)
    # aurl = "#{property_url}/extensions"
    # render_text("Added the DTM extension", results, aurl)
    # dtm_ext = results[:doc]
    # dtm_ext.extension_package = dtm

    # install the aa extension
    aa = reactor.extension_package_for('adobe-analytics')
    results = reactor.create_aa_extension(property.id, aa.id)
    aa_ext = results[:doc]
    aa_ext.extension_package = aa
    aurl = "#{property_url}/extensions/#{aa_ext&.id}"
    render_text("Added the Adobe Analytics Extension", results, aurl)

    # create a js data element named shopping_cart
    data_elements = []
    de_names.each do |name|
      results = reactor.create_data_element(property.id, name, dtm_ext)
      de = results[:doc]
      data_elements << de
      aurl = "#{property_url}/dataElements/#{de&.id}"
      render_text("Created Data Element '#{name}'", results, aurl)
    end

    # create a rule
    rules = []
    50.times do
      name = FFaker::Company.bs.titleize
      rule_results = reactor.create_rule(property.id, name)
      rule = rule_results[:doc]
      rules << rule
      aurl = "#{property_url}/rules/#{rule_results[:doc]&.id}"
      render_text("Created Rule '#{name}'", rule_results, aurl)

      results = reactor.create_rule_component(rule_results[:response], dtm_ext, 'click', :events)
      render_text("Created Click Event for Rule '#{name}'", results, aurl)

      results = reactor.create_rule_component(rule_results[:response], dtm_ext, 'browser', :conditions)
      render_text("Created Browser Condition for Rule '#{name}'", results, aurl)

      results = reactor.create_rule_component(rule_results[:response], aa_ext, 'set-variables', :actions)
      render_text("Created Analytics Set Variables Action for Rule '#{name}'", results, aurl)
    end

    # create a library
    rule_ids = rules.map {|r| [r.id, 'rules']}
    data_element_ids = data_elements.map {|de| [de.id, 'data_elements']}
    extension_ids = [[aa_ext.id, 'extensions'], [dtm_ext.id, 'extensions']]
    results = reactor.create_library(property.id, "Black Friday",
                                     environment.id,
                                     rule_ids,
                                     data_element_ids,
                                     extension_ids
                                    )
    library = results[:doc]
    aurl = "#{property_url}/publishing/#{library&.id}"
    render_text("Created Library '#{library&.name}'", results, aurl)

    # deploy library
    results = reactor.create_build(library&.id)
    aurl = "#{property_url}/publishing/#{library&.id}"
    render_text("Deploying Library '#{library&.name}'", results, aurl)

    # fetch the embed and display
    artifact_url = results[:response]['data']['meta']['artifact_url'].gsub('.min','')
    results = { url: artifact_url }
    render_text("Provisioning Complete! Go have fun!",results, artifact_url )
  end

  def provision_for_select
    Provision.all.map do |provision|
      [
        "#{provision.created_at}: #{provision.company_name} - #{provision.property_name}",
        provision.attributes.to_json
      ]
    end
  end

  def company_id
    @company_id ||= params[:company_id]
  end

  def company_name
    @company_name ||= params[:company_name]
  end

  def property_name
    @property_name ||= params[:property_name]
  end

  def fake_provision
    url = "https://mc-api-activation-dtm-qe.adobe.io/companies/co3880672ae2e5466fa5bc311d0a46f841/properties"
    aurl = "#{alpha_host}/company/CO123456/property/PR123456"
    render_text("Created property Fake", mock_result, aurl)
    sleep 0.1
    render_text("Added the DTM Extension", mock_result)
    sleep 0.1
    render_text("Added the Adobe Analytics Extension", mock_result, aurl)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
    sleep 0.1
    render_text("Created an Adobe Analytics Configuration", mock_result)
  end

  def mock_result
    payload = {
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

    { response: payload, url: 'https://mc-api-activation-dtm-alpha.adobe.io/rules/RL8b616b852c5a46ec8d6f5c2576bcf1e7/rule_components' }
  end

  def de_names
    %w(click_through_rate cost_per_acquisition cost_per_click cost_per_thousand conversion shopping_cart)
  end
end
