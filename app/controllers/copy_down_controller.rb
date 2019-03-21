Ext = Struct.new(:id)
class CopyDownController < ApplicationController
  skip_before_action :require_login, only: [:callback]
  skip_before_action :verify_authenticity_token, only: [:callback]
  def new
    render :new, locals: { companies: companies_for_select}
  end

  def callback
    audit_event = JSON.parse(params['_json'])
    rule_data = audit_event['data']['attributes']['entity']
    rule_id = JSON.parse(rule_data)['data']['id']
    puts "Rule ID: #{rule_id}"
    # get the rule
    # parse the meta
    render json: {}, status: 200
  end

  def new
    # select company
    # select property
    # select rule to be 
  end

  def create
    # 
  end

  def properties
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      sse.write(company_properties(params[:company_id]))
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def rules
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      sse.write(propert_rules(params[:property_id]))
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      duplicate_property
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def properties
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      sse.write(company_properties(params[:company_id]))
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def duplicate_property
    # TODO: set @company_id
    # TODO: set @source_property_id
    source_property = reactor.property(source_property_id)
    payload = source_property['data']['attributes'].tap do |h|
      h['name'] = target_property_name
    end
    @company_id = source_property['data']['links']['company'][/(?<=companies\/).*/]

    results = reactor.create_property(company_id, payload: payload)
    @property = results[:doc]
    render_text("Created property '#{target_property_name}'", results, "#{property_url}/overview")

    return if results[:response]['errors'].present?
    results = reactor.extensions(source_property_id)
    core_ext_id = reactor.extensions(property.id)['data'].first['id']

    extensions = results['data'].each_with_object({}) do |ext, memo|
      if ext['attributes']['name'] == 'core'
        memo[ext['id']] = core_ext_id
        next
      end

      payload = {
        "delegate_descriptor_id": ext['attributes']['delegate_descriptor_id'] || '',
        "settings": ext['attributes']['settings'] || ''
      }

      result = reactor.create_extension(property.id, payload, ext['relationships'])
      new_ext = result[:doc]
      eurl = "#{property_url}/extensions/#{new_ext&.id}"
      render_text("Added #{new_ext&.display_name} Extension", result, eurl)
      memo[ext['id']] = new_ext&.id
    end

    # get data elements, and post
    data_element_results = reactor.data_elements(source_property_id)
    data_element_results['data'].each do |de_result|
      payload = de_result['attributes']
      extension_id = extensions[de_result['relationships']['extension']['data']['id']]
      ext = Ext.new(extension_id)
      de_response = reactor.create_data_element(@property.id, nil, ext, payload)
      de = de_response[:doc]
      aurl = "#{property_url}/data_elements/#{de&.id}"
      render_text("Created Data Element '#{de&.name}'", de_response, aurl)
    end

    rules_results = reactor.rules(source_property_id)
    rules_results['data'].each do |rule_result|
      name = rule_result['attributes']['name']
      rule_response = reactor.create_rule(property.id, name)

      rule = rule_response[:doc]
      aurl = "#{property_url}/rules/#{rule&.id}"
      render_text("Created Rule '#{rule&.name}'", rule_response, aurl)

      rc_results = reactor.rule_components(rule_result['id'])
      rc_results['data'].each do |rc_result|
        payload = rc_result['attributes']
        extension_id = extensions[rc_result['relationships']['extension']['data']['id']]
        ext = Ext.new(extension_id)
        rc_response = reactor.create_rule_component(rule.id, ext, nil, nil, payload)
        rc = rc_response[:doc]
        aurl = "#{property_url}/rule_components/#{rc&.id}"
        render_text("Created Rule Component '#{rc&.name}'", rc_response, aurl)
      end
    end

    # create a dev adapter
    results = reactor.create_adapter(property.id, "Managed by Adobe")
    adapter = results[:doc]
    aurl = "#{property_url}/adapters/#{adapter&.id}"
    render_text("Created Adapter 'Managed by Adobe'", results, aurl)

    # create a dev environment : save the embed code
    results = reactor.create_environment(property.id, adapter.id, "Development")
    environment = results[:doc]
    aurl = "#{property_url}/environments/#{environment&.id}"
    render_text("Created Development Environment 'Development'", results, aurl)

    results = { url: property_url }
    render_text("Duplication Complete! Go have fun!", results, "#{property_url}/overview")
  end

  def source_property_id
    @source_property_id ||= params[:source_property_id]
  end

  def target_property_name
    @target_property_name ||= params[:target_property_name]
  end

  def company_id
    @company_id
  end

  def company_properties(company_id)
    reactor.properties(company_id).map do |p|
      [p.name, p.id]
    end.to_json
  end
end
